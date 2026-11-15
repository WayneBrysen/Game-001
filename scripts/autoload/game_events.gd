extends Node
## Global typed signal bus decoupling 3D shop world, 2D workbench, economy, and UI.

@warning_ignore("unused_signal")
signal credits_changed(new_amount: int, delta: int)
@warning_ignore("unused_signal")
signal suspicion_changed(new_value: int)
@warning_ignore("unused_signal")
signal reputation_changed(faction: String, new_value: int)

@warning_ignore("unused_signal")
signal day_started(day: int, rent_due: int, days_until_rent: int)
@warning_ignore("unused_signal")
signal shift_phase_changed(phase_name: String)
@warning_ignore("unused_signal")
signal day_ended(summary: Dictionary)

@warning_ignore("unused_signal")
signal customer_arrived(offer: Dictionary)
@warning_ignore("unused_signal")
signal customer_departed(accepted: bool, reason: String)

@warning_ignore("unused_signal")
signal workbench_requested(offer: Dictionary)
@warning_ignore("unused_signal")
signal workbench_closed()
@warning_ignore("unused_signal")
signal deal_resolved(decision: String, final_price: int, offer: Dictionary)

@warning_ignore("unused_signal")
signal inventory_updated()
@warning_ignore("unused_signal")
signal log_message(text: String, level: String)
@warning_ignore("unused_signal")
signal camera_focus_requested(target_name: String)


func _ready() -> void:
	_register_default_inputs()


func _register_default_inputs() -> void:
	_ensure_key_action("toggle_workbench", KEY_TAB)
	_ensure_key_action("interact", KEY_E)
	_ensure_key_action("toggle_uv", KEY_F)
	_ensure_key_action("cam_left", KEY_A)
	_ensure_key_action("cam_right", KEY_D)
	_ensure_key_action("cam_preset_1", KEY_1)
	_ensure_key_action("cam_preset_2", KEY_2)
	_ensure_key_action("cam_preset_3", KEY_3)


func _ensure_key_action(action_name: String, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for existing in InputMap.action_get_events(action_name):
		if existing is InputEventKey and existing.physical_keycode == keycode:
			return
	var ev := InputEventKey.new()
	ev.physical_keycode = keycode
	InputMap.action_add_event(action_name, ev)
