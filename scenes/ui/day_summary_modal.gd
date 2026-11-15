extends Control
## End-of-day settlement ledger displaying revenue, rent payment, and CorpSec sweep warnings.

@onready var title_label: Label = $Panel/Margin/VBox/TitleLabel
@onready var ledger_label: RichTextLabel = $Panel/Margin/VBox/LedgerText
@onready var next_day_btn: Button = $Panel/Margin/VBox/NextDayBtn


func _ready() -> void:
	visible = false
	next_day_btn.pressed.connect(_on_next_day_pressed)
	GameEvents.day_ended.connect(_on_day_ended)


func _on_day_ended(summary: Dictionary) -> void:
	visible = true
	var day := int(summary.get("day", 1))
	title_label.text = "DAY %d SHIFT LEDGER" % day

	var lines: Array[String] = [
		"Deals Completed: [b]%d[/b]  |  Rejected: %d  |  Reported: %d" % [
			int(summary.get("deals", 0)),
			int(summary.get("rejected", 0)),
			int(summary.get("reported", 0)),
		],
		"Gross Sales: [color=#59ff9e]+%d ¢[/color]" % int(summary.get("earned", 0)),
		"Stock Purchases: [color=#ffd257]-%d ¢[/color]" % int(summary.get("spent", 0)),
	]

	var rent_paid := int(summary.get("rent_paid", 0))
	if rent_paid > 0:
		lines.append("Station Rent Paid: [color=#ff88aa]-%d ¢[/color]" % rent_paid)
	elif bool(summary.get("rent_missed", false)):
		lines.append("[color=#ff4c6a]RENT MISSED! CorpSec Debt Alert (+15 Heat)[/color]")

	if bool(summary.get("raid_triggered", false)):
		lines.append("[color=#ff4c6a]CORPSEC COMPLIANCE SWEEP: -%d ¢ Fine[/color]" % int(summary.get("fine_paid", 0)))

	lines.append("----------------------------------------")
	lines.append("Balance After Shift: [b]%d ¢[/b] (Next Rent: %d ¢ in %dd)" % [
		int(summary.get("credits_after", 0)),
		int(summary.get("next_rent", 480)),
		int(summary.get("days_until_rent", 1)),
	])

	if bool(summary.get("buyout_reached", false)):
		lines.append("\n[color=#59ff9e][b]SHOP BUYOUT TARGET REACHED! You own Deck-09 Pawn.[/b][/color]")

	ledger_label.text = "\n".join(lines)


func _on_next_day_pressed() -> void:
	visible = false
	TimeManager.start_next_day()
