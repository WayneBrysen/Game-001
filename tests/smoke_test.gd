extends Node
## Headless end-to-end smoke test verifying the 3D+2D shopkeeper core loop.

const MAIN_SCENE = preload("res://scenes/main/main.tscn")


func _ready() -> void:
	var main_inst := MAIN_SCENE.instantiate()
	add_child(main_inst)
	await get_tree().process_frame

	assert(TimeManager.current_day == 1, "Expected Day 1")
	assert(TimeManager.current_phase == TimeManager.Phase.PREP, "Expected PREP phase")
	assert(InventoryManager.stock.size() == 3, "Expected 3 starter items")

	# Open shop -> spawns customer 1
	TimeManager.open_shop_shift()
	await get_tree().process_frame
	assert(TimeManager.current_phase == TimeManager.Phase.OPEN, "Expected OPEN phase")
	assert(not TimeManager.active_offer.is_empty(), "Expected active offer")

	# Open 2D workbench overlay on 3D shop
	TimeManager.open_active_workbench()
	await get_tree().process_frame
	var wb: Control = main_inst.get_node("UILayer/AppraisalWorkbench2D")
	assert(wb.visible, "Expected 2D workbench visible")

	# Resolve deal cleanly via workbench
	var offer := TimeManager.active_offer.duplicate(true)
	if offer["intent"] == "SELL_TO_PLAYER":
		GameEvents.deal_resolved.emit("buy", int(offer["initial_price"]), offer)
	else:
		GameEvents.deal_resolved.emit("sell", int(offer["initial_price"]), offer)
	wb.close_workbench()
	await get_tree().process_frame
	assert(TimeManager.active_offer.is_empty(), "Offer should clear after deal")

	# End shift & check summary modal
	TimeManager.end_shift()
	await get_tree().process_frame
	var modal: Control = main_inst.get_node("UILayer/DaySummaryModal")
	assert(modal.visible, "Expected DaySummaryModal visible")
	assert(TimeManager.current_phase == TimeManager.Phase.CLOSING, "Expected CLOSING phase")

	# Advance to Day 2
	TimeManager.start_next_day()
	await get_tree().process_frame
	assert(TimeManager.current_day == 2, "Expected Day 2")
	assert(TimeManager.current_phase == TimeManager.Phase.PREP, "Expected PREP phase on Day 2")

	print("SMOKE_TEST_PASSED: Day1->Workbench2D->Deal->Summary->Day2 OK")
	get_tree().quit(0)
