extends Control
## Main HUD showing shop economy, rent countdown, factions, shelf inventory, and 3D/2D triggers.

@onready var day_label: Label = $TopBar/Margin/HBox/DayLabel
@onready var credits_label: Label = $TopBar/Margin/HBox/CreditsLabel
@onready var rent_label: Label = $TopBar/Margin/HBox/RentLabel
@onready var heat_label: Label = $TopBar/Margin/HBox/HeatLabel

@onready var cam_1_btn: Button = $TopBar/Margin/HBox/CamBtns/Cam1Btn
@onready var cam_2_btn: Button = $TopBar/Margin/HBox/CamBtns/Cam2Btn
@onready var cam_3_btn: Button = $TopBar/Margin/HBox/CamBtns/Cam3Btn

@onready var faction_label: Label = $SideStockPanel/Margin/VBox/FactionLabel
@onready var stock_title: Label = $SideStockPanel/Margin/VBox/StockTitle
@onready var stock_list: VBoxContainer = $SideStockPanel/Margin/VBox/StockScroll/StockList

@onready var banner_title: Label = $BottomActionBar/Margin/HBox/InfoCol/BannerTitle
@onready var banner_sub: Label = $BottomActionBar/Margin/HBox/InfoCol/BannerSub
@onready var primary_action_btn: Button = $BottomActionBar/Margin/HBox/ButtonsCol/PrimaryActionBtn
@onready var secondary_action_btn: Button = $BottomActionBar/Margin/HBox/ButtonsCol/SecondaryActionBtn

@onready var log_label: RichTextLabel = $LogPanel/Margin/LogRichText

var _log_lines: Array[String] = []


func _ready() -> void:
	cam_1_btn.pressed.connect(func() -> void: GameEvents.camera_focus_requested.emit("overview"))
	cam_2_btn.pressed.connect(func() -> void: GameEvents.camera_focus_requested.emit("counter"))
	cam_3_btn.pressed.connect(func() -> void: GameEvents.camera_focus_requested.emit("shelves"))

	primary_action_btn.pressed.connect(_on_primary_action)
	secondary_action_btn.pressed.connect(_on_secondary_action)

	GameEvents.credits_changed.connect(func(_c: int, _d: int) -> void: _refresh_top_bar())
	GameEvents.suspicion_changed.connect(func(_s: int) -> void: _refresh_top_bar())
	GameEvents.reputation_changed.connect(func(_f: String, _v: int) -> void: _refresh_factions())
	GameEvents.day_started.connect(func(_d: int, _r: int, _rem: int) -> void: _refresh_all())
	GameEvents.shift_phase_changed.connect(func(_p: String) -> void: _refresh_all())
	GameEvents.inventory_updated.connect(_refresh_stock)
	GameEvents.customer_arrived.connect(_on_customer_arrived)
	GameEvents.customer_departed.connect(_on_customer_departed)
	GameEvents.log_message.connect(_append_log)

	_append_log("Welcome to Project 001: Neon Pawn. Open the shop or inspect shelves.", "info")
	_refresh_all()


func _refresh_all() -> void:
	_refresh_top_bar()
	_refresh_factions()
	_refresh_stock()
	_refresh_action_bar()


func _refresh_top_bar() -> void:
	day_label.text = "DAY %d // %s" % [TimeManager.current_day, TimeManager.get_phase_name()]
	credits_label.text = "CREDITS: %d ¢ / %d ¢" % [EconomyManager.credits, EconomyManager.BUYOUT_TARGET]

	var days_left := EconomyManager.get_days_until_rent(TimeManager.current_day)
	if days_left == 0:
		rent_label.text = "RENT DUE TONIGHT: %d ¢" % EconomyManager.rent_due
		rent_label.modulate = Color(1.0, 0.45, 0.35)
	else:
		rent_label.text = "RENT: %d ¢ (%dd)" % [EconomyManager.rent_due, days_left]
		rent_label.modulate = Color(0.95, 0.85, 0.42)

	heat_label.text = "HEAT: %d%%" % EconomyManager.suspicion
	heat_label.modulate = Color(1.0, 0.35, 0.45) if EconomyManager.suspicion >= 60 else Color(0.35, 0.92, 1.0)


func _refresh_factions() -> void:
	faction_label.text = "SCAV %d | SYN %d | CORP %d" % [
		EconomyManager.factions["Scavengers"],
		EconomyManager.factions["Syndicate"],
		EconomyManager.factions["CorpSec"],
	]


func _refresh_stock() -> void:
	stock_title.text = "SHELF STOCK (%d/%d)" % [InventoryManager.stock.size(), InventoryManager.MAX_SHELF_SLOTS]
	for child in stock_list.get_children():
		child.queue_free()

	for item in InventoryManager.stock:
		var lbl := Label.new()
		var tags := ""
		if item["is_stolen"]:
			tags += " [HOT]"
		if item["has_beacon"]:
			tags += " [BEACON]"
		lbl.text = "• %s (~%d ¢)%s" % [item["name"], InventoryManager.get_sell_value(item), tags]
		lbl.add_theme_font_size_override("font_size", 12)
		lbl.modulate = Color(1.0, 0.62, 0.35) if (item["is_stolen"] or item["has_beacon"]) else Color(0.82, 0.92, 1.0)
		stock_list.add_child(lbl)


func _refresh_action_bar() -> void:
	match TimeManager.current_phase:
		TimeManager.Phase.PREP:
			banner_title.text = "SHOP CLOSED — PREP PHASE"
			banner_sub.text = "Inspect 3D shelves [3], check rent on wall monitor, or open the shutters [E]."
			primary_action_btn.text = "OPEN SHOP [E]"
			primary_action_btn.disabled = false
			secondary_action_btn.visible = false
		TimeManager.Phase.OPEN:
			if TimeManager.active_offer.is_empty():
				var remaining := TimeManager.CUSTOMERS_PER_DAY - TimeManager.customers_served_today
				banner_title.text = "COUNTER CLEAR (%d PATRONS LEFT TODAY)" % remaining
				banner_sub.text = "Call the next patron to the 3D counter or close shop early."
				primary_action_btn.text = "NEXT PATRON [E]" if remaining > 0 else "WRAP UP SHIFT [E]"
				primary_action_btn.disabled = false
				secondary_action_btn.text = "END SHIFT"
				secondary_action_btn.visible = true
			else:
				_show_offer_banner(TimeManager.active_offer)
		TimeManager.Phase.CLOSING:
			banner_title.text = "SHIFT ENDED — NIGHT LEDGER"
			banner_sub.text = "Review daily profits and station rent."
			primary_action_btn.text = "LEDGER OPEN"
			primary_action_btn.disabled = true
			secondary_action_btn.visible = false


func _on_customer_arrived(offer: Dictionary) -> void:
	_show_offer_banner(offer)
	_append_log("%s (%s) approached the counter." % [offer["customer_name"], offer["role"]], "info")


func _show_offer_banner(offer: Dictionary) -> void:
	var intent_txt := "WANTS TO SELL" if offer["intent"] == "SELL_TO_PLAYER" else "WANTS TO BUY"
	banner_title.text = "%s (%s) — %s: %s (%d ¢)" % [
		offer["customer_name"],
		offer["role"],
		intent_txt,
		offer["item_name"],
		int(offer["initial_price"]),
	]
	banner_sub.text = "\"%s\"  [Click 3D Counter or press Tab for 2D UV Appraisal]" % offer["dialogue"]
	primary_action_btn.text = "2D APPRAISAL [Tab]"
	primary_action_btn.disabled = false
	secondary_action_btn.text = "DISMISS"
	secondary_action_btn.visible = true


func _on_customer_departed(_accepted: bool, reason: String) -> void:
	_append_log(reason, "info")
	_refresh_all()


func _on_primary_action() -> void:
	trigger_primary_context_action()


func trigger_primary_context_action() -> void:
	match TimeManager.current_phase:
		TimeManager.Phase.PREP:
			TimeManager.open_shop_shift()
		TimeManager.Phase.OPEN:
			if TimeManager.active_offer.is_empty():
				TimeManager.spawn_next_customer()
			else:
				TimeManager.open_active_workbench()


func _on_secondary_action() -> void:
	if TimeManager.current_phase != TimeManager.Phase.OPEN:
		return
	if TimeManager.active_offer.is_empty():
		TimeManager.end_shift()
	else:
		GameEvents.deal_resolved.emit("reject", 0, TimeManager.active_offer)


func _append_log(text: String, level: String) -> void:
	var col := "#a8d8ff"
	match level:
		"cash":
			col = "#59ff9e"
		"warn":
			col = "#ffd257"
		"danger":
			col = "#ff5c77"
	_log_lines.append("[color=%s]• %s[/color]" % [col, text])
	if _log_lines.size() > 6:
		_log_lines.remove_at(0)
	log_label.text = "\n".join(_log_lines)
