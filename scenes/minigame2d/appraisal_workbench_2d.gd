extends Control
## 2D interactive appraisal and haggling overlay interleaved with the 3D shop floor.

@onready var scanner_pad: Control = $CenterPanel/Margin/HBox/LeftCol/UVScannerPad2D
@onready var uv_toggle_btn: Button = $CenterPanel/Margin/HBox/LeftCol/ScannerTools/UVToggleBtn
@onready var scan_result_label: Label = $CenterPanel/Margin/HBox/LeftCol/ScanResultLabel

@onready var customer_header: Label = $CenterPanel/Margin/HBox/RightCol/CustomerHeader
@onready var dialogue_label: Label = $CenterPanel/Margin/HBox/RightCol/DialogueLabel
@onready var item_title: Label = $CenterPanel/Margin/HBox/RightCol/ItemTitle
@onready var item_meta: Label = $CenterPanel/Margin/HBox/RightCol/ItemMeta
@onready var price_slider: HSlider = $CenterPanel/Margin/HBox/RightCol/PriceRow/PriceSlider
@onready var price_value_label: Label = $CenterPanel/Margin/HBox/RightCol/PriceRow/PriceValueLabel
@onready var mood_label: Label = $CenterPanel/Margin/HBox/RightCol/MoodLabel

@onready var primary_btn: Button = $CenterPanel/Margin/HBox/RightCol/ActionsRow/PrimaryBtn
@onready var reject_btn: Button = $CenterPanel/Margin/HBox/RightCol/ActionsRow/RejectBtn
@onready var report_btn: Button = $CenterPanel/Margin/HBox/RightCol/ActionsRow/ReportBtn
@onready var back_btn: Button = $CenterPanel/Margin/HBox/RightCol/BackBtn

var _offer: Dictionary = {}


func _ready() -> void:
	visible = false
	scanner_pad.clue_revealed.connect(_on_clue_revealed)
	uv_toggle_btn.toggled.connect(_on_uv_toggled)
	price_slider.value_changed.connect(_on_price_changed)
	primary_btn.pressed.connect(_on_primary_pressed)
	reject_btn.pressed.connect(_on_reject_pressed)
	report_btn.pressed.connect(_on_report_pressed)
	back_btn.pressed.connect(close_workbench)


func open_with_offer(offer: Dictionary) -> void:
	if offer.is_empty():
		return
	_offer = offer.duplicate(true)
	visible = true

	scanner_pad.load_offer(_offer)
	uv_toggle_btn.set_pressed_no_signal(true)
	scan_result_label.text = "Move mouse over blueprint with UV [F] active to scan hidden tags."
	scan_result_label.modulate = Color(0.65, 0.85, 1.0)

	var is_buying: bool = _offer.get("intent", "SELL_TO_PLAYER") == "SELL_TO_PLAYER"
	customer_header.text = "%s // %s (%s)" % [
		_offer.get("customer_name", "Patron"),
		_offer.get("role", "Unknown"),
		_offer.get("faction", "Neutral"),
	]
	dialogue_label.text = "\"%s\"" % _offer.get("dialogue", "...")
	item_title.text = "%s [%s]" % [_offer.get("item_name", "Item"), _offer.get("category", "MISC")]
	item_meta.text = "Est. Street Value: %d ¢   |   %s" % [
		int(_offer.get("base_value", 100)),
		_offer.get("description", ""),
	]

	var init_price := int(_offer.get("initial_price", 100))
	if is_buying:
		price_slider.min_value = maxi(10, int(round(init_price * 0.5)))
		price_slider.max_value = int(round(init_price * 1.3))
		primary_btn.text = "BUY ITEM"
		report_btn.visible = true
	else:
		price_slider.min_value = maxi(15, int(round(init_price * 0.75)))
		price_slider.max_value = int(round(init_price * 1.5))
		primary_btn.text = "SELL FROM SHELF"
		report_btn.visible = false

	price_slider.value = init_price
	_update_mood_feedback(init_price)


func close_workbench() -> void:
	if not visible:
		return
	visible = false
	GameEvents.workbench_closed.emit()


func toggle_uv_shortcut() -> void:
	if not visible:
		return
	uv_toggle_btn.button_pressed = not uv_toggle_btn.button_pressed


func _on_uv_toggled(pressed: bool) -> void:
	scanner_pad.toggle_uv(pressed)
	uv_toggle_btn.text = "UV SCAN: ON [F]" if pressed else "UV SCAN: OFF [F]"


func _on_clue_revealed(clue_text: String, is_stolen: bool, has_beacon: bool) -> void:
	var prefix := "ALERT: " if (is_stolen or has_beacon) else "VERIFIED: "
	scan_result_label.text = prefix + clue_text
	if has_beacon:
		scan_result_label.modulate = Color(1.0, 0.4, 0.3)
	elif is_stolen:
		scan_result_label.modulate = Color(1.0, 0.82, 0.25)
	else:
		scan_result_label.modulate = Color(0.3, 1.0, 0.68)


func _on_price_changed(val: float) -> void:
	_update_mood_feedback(int(val))


func _update_mood_feedback(proposed: int) -> void:
	price_value_label.text = "%d ¢" % proposed
	var is_buying: bool = _offer.get("intent", "SELL_TO_PLAYER") == "SELL_TO_PLAYER"
	var acceptable := false
	if is_buying:
		acceptable = proposed >= int(_offer.get("min_acceptable", 1))
	else:
		acceptable = proposed <= int(_offer.get("max_acceptable", 9999))

	if acceptable:
		mood_label.text = "Customer Mood: WILLING TO DEAL"
		mood_label.modulate = Color(0.32, 1.0, 0.65)
	else:
		mood_label.text = "Customer Mood: PUSHBACK (Offer outside threshold!)"
		mood_label.modulate = Color(1.0, 0.42, 0.35)
	primary_btn.disabled = not acceptable


func _on_primary_pressed() -> void:
	var final_price := int(price_slider.value)
	var decision := "buy" if _offer.get("intent", "SELL_TO_PLAYER") == "SELL_TO_PLAYER" else "sell"
	visible = false
	GameEvents.deal_resolved.emit(decision, final_price, _offer)
	GameEvents.workbench_closed.emit()


func _on_reject_pressed() -> void:
	visible = false
	GameEvents.deal_resolved.emit("reject", 0, _offer)
	GameEvents.workbench_closed.emit()


func _on_report_pressed() -> void:
	visible = false
	GameEvents.deal_resolved.emit("report", 0, _offer)
	GameEvents.workbench_closed.emit()
