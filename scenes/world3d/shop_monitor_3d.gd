@tool
extends Node3D
## Diegetic 2D UI rendered onto a 3D wall monitor via SubViewport -> StandardMaterial3D.

@onready var sub_viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $ScreenMesh
@onready var status_label: Label = $SubViewport/ScreenRoot/Margin/VBox/Header/StatusPill
@onready var credits_label: Label = $SubViewport/ScreenRoot/Margin/VBox/StatsRow/CreditsValue
@onready var heat_bar: ProgressBar = $SubViewport/ScreenRoot/Margin/VBox/HeatRow/HeatBar
@onready var ticker_label: Label = $SubViewport/ScreenRoot/Margin/VBox/TickerLabel


func _ready() -> void:
	_bind_viewport_texture()
	if Engine.is_editor_hint():
		return
	GameEvents.credits_changed.connect(func(_c: int, _d: int) -> void: _refresh())
	GameEvents.suspicion_changed.connect(func(_s: int) -> void: _refresh())
	GameEvents.shift_phase_changed.connect(func(_p: String) -> void: _refresh())
	GameEvents.day_started.connect(func(_d: int, _r: int, _rem: int) -> void: _refresh())
	GameEvents.customer_arrived.connect(_on_customer_arrived)
	_refresh()


func _bind_viewport_texture() -> void:
	if screen_mesh == null or sub_viewport == null:
		return
	var mat := StandardMaterial3D.new()
	var tex := sub_viewport.get_texture()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	screen_mesh.set_surface_override_material(0, mat)


func _refresh() -> void:
	if Engine.is_editor_hint():
		return
	var phase := TimeManager.get_phase_name()
	status_label.text = phase
	match phase:
		"OPEN":
			status_label.modulate = Color(0.2, 1.0, 0.65)
		"CLOSING":
			status_label.modulate = Color(1.0, 0.45, 0.35)
		_:
			status_label.modulate = Color(1.0, 0.82, 0.25)

	credits_label.text = "%d ¢" % EconomyManager.credits
	heat_bar.value = EconomyManager.suspicion
	ticker_label.text = "DAY %d // RENT %d ¢ (%dd) // STOCK %d/%d" % [
		TimeManager.current_day,
		EconomyManager.rent_due,
		EconomyManager.get_days_until_rent(TimeManager.current_day),
		InventoryManager.stock.size(),
		InventoryManager.MAX_SHELF_SLOTS,
	]


func _on_customer_arrived(offer: Dictionary) -> void:
	if Engine.is_editor_hint():
		return
	ticker_label.text = "CLIENT: %s (%s) -> %s" % [
		offer.get("customer_name", "?"),
		offer.get("role", "?"),
		offer.get("item_name", "?"),
	]
