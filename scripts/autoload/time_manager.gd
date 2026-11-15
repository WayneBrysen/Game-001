extends Node
## Controls shop shift lifecycle (PREP -> OPEN -> CLOSING) and customer queue pacing.

const CustomerGenScript = preload("res://scripts/systems/customer_generator.gd")

enum Phase {
	PREP,
	OPEN,
	CLOSING,
}

const CUSTOMERS_PER_DAY: int = 4

var current_day: int = 1
var current_phase: Phase = Phase.PREP
var customers_served_today: int = 0
var active_offer: Dictionary = {}
var _generator := CustomerGenScript.new()


func _ready() -> void:
	GameEvents.deal_resolved.connect(_on_deal_resolved)
	call_deferred("_emit_initial_day_state")


func _emit_initial_day_state() -> void:
	GameEvents.day_started.emit(
		current_day,
		EconomyManager.rent_due,
		EconomyManager.get_days_until_rent(current_day)
	)
	GameEvents.shift_phase_changed.emit(get_phase_name())


func get_phase_name() -> String:
	match current_phase:
		Phase.PREP:
			return "PREP"
		Phase.OPEN:
			return "OPEN"
		Phase.CLOSING:
			return "CLOSING"
	return "PREP"


func open_shop_shift() -> void:
	if current_phase != Phase.PREP:
		return
	current_phase = Phase.OPEN
	customers_served_today = 0
	GameEvents.shift_phase_changed.emit(get_phase_name())
	GameEvents.log_message.emit("Day %d shutter raised. Neon sign active." % current_day, "info")
	spawn_next_customer()


func spawn_next_customer() -> void:
	if current_phase != Phase.OPEN:
		return
	if not active_offer.is_empty():
		return
	if customers_served_today >= CUSTOMERS_PER_DAY:
		end_shift()
		return

	active_offer = _generator.generate_offer(current_day, EconomyManager.suspicion)
	customers_served_today += 1
	GameEvents.customer_arrived.emit(active_offer)


func open_active_workbench() -> void:
	if active_offer.is_empty():
		GameEvents.log_message.emit("No active transaction on the counter.", "warn")
		return
	GameEvents.workbench_requested.emit(active_offer)


func end_shift() -> void:
	if current_phase == Phase.CLOSING:
		return
	active_offer.clear()
	current_phase = Phase.CLOSING
	GameEvents.shift_phase_changed.emit(get_phase_name())
	var summary := EconomyManager.settle_end_of_day(current_day)
	GameEvents.day_ended.emit(summary)


func start_next_day() -> void:
	current_day += 1
	current_phase = Phase.PREP
	customers_served_today = 0
	active_offer.clear()
	EconomyManager.reset_daily_ledger()
	GameEvents.day_started.emit(
		current_day,
		EconomyManager.rent_due,
		EconomyManager.get_days_until_rent(current_day)
	)
	GameEvents.shift_phase_changed.emit(get_phase_name())
	GameEvents.log_message.emit("Day %d begins. Prep shelves or open the shutters." % current_day, "info")


func _on_deal_resolved(decision: String, final_price: int, offer: Dictionary) -> void:
	if offer.is_empty():
		return
	var accepted := false
	var reason := ""

	match decision:
		"buy":
			if not InventoryManager.has_capacity():
				GameEvents.log_message.emit("Shelf full! Sell stock before buying more.", "danger")
				return
			if EconomyManager.credits < final_price:
				GameEvents.log_message.emit("Not enough credits (%d ¢ needed)." % final_price, "danger")
				return
			EconomyManager.adjust_credits(-final_price, "Bought %s" % offer["item_name"])
			InventoryManager.add_item_by_id(
				offer["item_id"],
				final_price,
				offer["is_stolen"],
				offer["has_beacon"]
			)
			EconomyManager.daily_deals += 1
			if offer["is_sting"]:
				EconomyManager.adjust_suspicion(24)
				EconomyManager.adjust_reputation("CorpSec", -12)
				GameEvents.log_message.emit("STING TRAP! Undercover buyer flagged stolen purchase!", "danger")
			elif offer["has_beacon"]:
				EconomyManager.adjust_suspicion(offer["illegal_risk"])
				GameEvents.log_message.emit("Active CorpSec beacon detected on inventory! +%d Heat." % offer["illegal_risk"], "warn")
			elif offer["is_stolen"]:
				EconomyManager.adjust_suspicion(int(offer["illegal_risk"] * 0.5))
				EconomyManager.adjust_reputation("Syndicate", 4)
			else:
				EconomyManager.adjust_reputation(offer["faction"], 3)
			accepted = true
			reason = "Deal struck at %d ¢." % final_price

		"sell":
			var uid := int(offer.get("target_uid", -1))
			if InventoryManager.remove_item_by_uid(uid):
				EconomyManager.adjust_credits(final_price, "Sold %s" % offer["item_name"])
				EconomyManager.daily_deals += 1
				EconomyManager.adjust_reputation(offer["faction"], 4)
				if offer["is_stolen"]:
					EconomyManager.adjust_suspicion(-4)
				accepted = true
				reason = "Sold for %d ¢." % final_price
			else:
				reason = "Item no longer on shelf."

		"reject":
			EconomyManager.daily_rejected += 1
			if offer["is_sting"]:
				GameEvents.log_message.emit("Good eye! Turned away an undercover sting.", "cash")
			reason = "Customer dismissed."

		"report":
			EconomyManager.daily_reported += 1
			if offer["is_stolen"] or offer["has_beacon"]:
				EconomyManager.adjust_credits(45, "CorpSec tip-off bounty")
				EconomyManager.adjust_suspicion(-14)
				EconomyManager.adjust_reputation("CorpSec", 10)
				EconomyManager.adjust_reputation("Syndicate", -10)
				EconomyManager.adjust_reputation("Scavengers", -6)
				reason = "Reported hot goods to CorpSec (+45 ¢ bounty)."
			else:
				EconomyManager.adjust_reputation("CorpSec", -5)
				EconomyManager.adjust_reputation(offer["faction"], -8)
				reason = "False alarm! Item was clean."

	active_offer.clear()
	GameEvents.customer_departed.emit(accepted, reason)
