extends Node
## Manages player credits, periodic station rent, heat/suspicion, and faction standings.

const RENT_INTERVAL_DAYS: int = 3
const BUYOUT_TARGET: int = 2500

var credits: int = 340
var rent_due: int = 480
var suspicion: int = 12 ## 0..100 heat gauge; >= 80 triggers CorpSec fine/inspection.
var factions: Dictionary[String, int] = {
	"Scavengers": 10,
	"Syndicate": 5,
	"CorpSec": 0,
}

var daily_spent: int = 0
var daily_earned: int = 0
var daily_deals: int = 0
var daily_rejected: int = 0
var daily_reported: int = 0


func reset_daily_ledger() -> void:
	daily_spent = 0
	daily_earned = 0
	daily_deals = 0
	daily_rejected = 0
	daily_reported = 0


func adjust_credits(delta: int, reason: String = "") -> void:
	credits += delta
	if delta > 0:
		daily_earned += delta
	elif delta < 0:
		daily_spent += -delta
	GameEvents.credits_changed.emit(credits, delta)
	if not reason.is_empty():
		var sign_txt := "+" if delta >= 0 else ""
		GameEvents.log_message.emit("%s (%s%d ¢)" % [reason, sign_txt, delta], "cash" if delta >= 0 else "warn")


func adjust_suspicion(delta: int) -> void:
	suspicion = clampi(suspicion + delta, 0, 100)
	GameEvents.suspicion_changed.emit(suspicion)


func adjust_reputation(faction: String, delta: int) -> void:
	if not factions.has(faction):
		return
	factions[faction] = clampi(factions[faction] + delta, -50, 100)
	GameEvents.reputation_changed.emit(faction, factions[faction])


func get_days_until_rent(current_day: int) -> int:
	var rem := current_day % RENT_INTERVAL_DAYS
	return 0 if rem == 0 else RENT_INTERVAL_DAYS - rem


func is_rent_day(current_day: int) -> bool:
	return current_day > 0 and (current_day % RENT_INTERVAL_DAYS == 0)


func settle_end_of_day(current_day: int) -> Dictionary:
	var rent_paid := 0
	var fine_paid := 0
	var rent_missed := false
	var raid_triggered := false

	if suspicion >= 80:
		raid_triggered = true
		fine_paid = mini(maxi(credits, 0), 160)
		credits -= fine_paid
		suspicion = clampi(suspicion - 35, 0, 100)
		GameEvents.credits_changed.emit(credits, -fine_paid)
		GameEvents.suspicion_changed.emit(suspicion)
		GameEvents.log_message.emit("CorpSec sweep! Paid %d ¢ in 'compliance fees'." % fine_paid, "danger")
	else:
		adjust_suspicion(-6)

	if is_rent_day(current_day):
		if credits >= rent_due:
			credits -= rent_due
			rent_paid = rent_due
			GameEvents.credits_changed.emit(credits, -rent_paid)
			rent_due = int(round(rent_due * 1.18))
		else:
			rent_missed = true
			adjust_suspicion(15)

	var net_profit := daily_earned - daily_spent - rent_paid - fine_paid
	var buyout_reached := credits >= BUYOUT_TARGET

	return {
		"day": current_day,
		"earned": daily_earned,
		"spent": daily_spent,
		"deals": daily_deals,
		"rejected": daily_rejected,
		"reported": daily_reported,
		"rent_paid": rent_paid,
		"rent_missed": rent_missed,
		"fine_paid": fine_paid,
		"raid_triggered": raid_triggered,
		"net_profit": net_profit,
		"credits_after": credits,
		"next_rent": rent_due,
		"days_until_rent": get_days_until_rent(current_day + 1),
		"buyout_reached": buyout_reached,
	}
