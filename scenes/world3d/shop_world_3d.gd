extends Node3D
## 3D cyberpunk pawnshop interior hosting 2D-in-3D billboard customers, 3D shelf props, and interactive hotspots.

const PRESETS: Dictionary = {
	"overview": {
		"pos": Vector3(0.22, 1.92, -2.05),
		"look": Vector3(0.0, 1.12, 1.1),
	},
	"counter": {
		"pos": Vector3(0.0, 1.54, -1.22),
		"look": Vector3(0.0, 1.02, 0.72),
	},
	"shelves": {
		"pos": Vector3(-0.32, 1.66, -1.52),
		"look": Vector3(-2.3, 1.12, 0.72),
	},
}

@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var customer: Node3D = $HybridCustomer3D
@onready var counter_item_anchor: Node3D = $CounterItemAnchor
@onready var shelf_items_root: Node3D = $ShelfItemsRoot
@onready var counter_area: Area3D = $CounterInteractArea
@onready var door_area: Area3D = $DoorInteractArea
@onready var shelf_area: Area3D = $ShelfInteractArea
@onready var neon_sign_light: OmniLight3D = $Lighting/MagentaDoorLight

var _current_preset: String = "overview"
var _pan_offset: float = 0.0
var _target_cam_pos: Vector3 = PRESETS["overview"]["pos"]
var _target_look: Vector3 = PRESETS["overview"]["look"]
var _spin_time: float = 0.0
var _workbench_dimmed: bool = false


func _ready() -> void:
	counter_area.input_event.connect(_on_counter_input)
	door_area.input_event.connect(_on_door_input)
	shelf_area.input_event.connect(_on_shelf_input)

	GameEvents.customer_arrived.connect(_on_customer_arrived)
	GameEvents.customer_departed.connect(_on_customer_departed)
	GameEvents.inventory_updated.connect(_rebuild_shelf_props)
	GameEvents.camera_focus_requested.connect(set_camera_preset)
	GameEvents.shift_phase_changed.connect(_on_phase_changed)

	_rebuild_shelf_props()
	set_camera_preset("overview")


func _process(delta: float) -> void:
	_spin_time += delta
	if not _workbench_dimmed:
		var pan_dir := Input.get_axis("cam_left", "cam_right")
		_pan_offset = clampf(_pan_offset + pan_dir * delta * 1.4, -0.75, 0.75)

	var desired_pos := _target_cam_pos + Vector3(_pan_offset * 0.45, 0.0, 0.0)
	var desired_look := _target_look + Vector3(_pan_offset * 0.65, 0.0, 0.0)
	camera.global_position = camera.global_position.lerp(desired_pos, clampf(delta * 6.0, 0.0, 1.0))
	camera.look_at(desired_look, Vector3.UP)

	if counter_item_anchor.get_child_count() > 0:
		counter_item_anchor.rotation.y = _spin_time * 0.85
		counter_item_anchor.position.y = 1.06 + sin(_spin_time * 2.2) * 0.025


func set_camera_preset(preset_name: String) -> void:
	if not PRESETS.has(preset_name):
		return
	_current_preset = preset_name
	_pan_offset = 0.0
	_target_cam_pos = PRESETS[preset_name]["pos"]
	_target_look = PRESETS[preset_name]["look"]


func set_workbench_dimmed(dimmed: bool) -> void:
	_workbench_dimmed = dimmed


func _on_phase_changed(phase_name: String) -> void:
	if neon_sign_light == null:
		return
	match phase_name:
		"OPEN":
			neon_sign_light.light_color = Color(0.18, 0.96, 0.82)
			neon_sign_light.light_energy = 2.6
		"CLOSING":
			neon_sign_light.light_color = Color(1.0, 0.25, 0.35)
			neon_sign_light.light_energy = 1.4
		_:
			neon_sign_light.light_color = Color(1.0, 0.24, 0.72)
			neon_sign_light.light_energy = 1.8


func _on_customer_arrived(offer: Dictionary) -> void:
	customer.enter_shop(offer, Vector3(2.8, 0.0, 2.55), Vector3(0.0, 0.0, 1.08))
	_set_counter_prop(offer.get("item_shape", "box"), offer.get("item_color", Color.CYAN))
	set_camera_preset("counter")


func _on_customer_departed(_accepted: bool, _reason: String) -> void:
	_clear_counter_prop()
	customer.leave_shop(Vector3(2.9, 0.0, 2.65))
	set_camera_preset("overview")


func _set_counter_prop(shape_type: String, tint: Color) -> void:
	_clear_counter_prop()
	var prop := _create_item_mesh(shape_type, tint, 0.22)
	counter_item_anchor.add_child(prop)


func _clear_counter_prop() -> void:
	for child in counter_item_anchor.get_children():
		child.queue_free()


func _rebuild_shelf_props() -> void:
	for child in shelf_items_root.get_children():
		child.queue_free()

	var idx := 0
	for item in InventoryManager.stock:
		if idx >= InventoryManager.MAX_SHELF_SLOTS:
			break
		var col := idx % 4
		var row := idx / 4
		var prop := _create_item_mesh(item.get("shape", "box"), item.get("color", Color.CYAN), 0.16)
		prop.position = Vector3(-0.72 + col * 0.48, 0.88 + row * 0.56, 0.0)
		shelf_items_root.add_child(prop)
		idx += 1


func _create_item_mesh(shape_type: String, tint: Color, scale_unit: float) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	match shape_type:
		"cylinder":
			var cyl := CylinderMesh.new()
			cyl.top_radius = scale_unit * 0.45
			cyl.bottom_radius = scale_unit * 0.45
			cyl.height = scale_unit * 1.35
			mesh_inst.mesh = cyl
		"vial":
			var vial := CapsuleMesh.new()
			vial.radius = scale_unit * 0.34
			vial.height = scale_unit * 1.4
			mesh_inst.mesh = vial
		"chip":
			var chip := BoxMesh.new()
			chip.size = Vector3(scale_unit * 1.2, scale_unit * 0.22, scale_unit * 0.9)
			mesh_inst.mesh = chip
		_:
			var box := BoxMesh.new()
			box.size = Vector3(scale_unit, scale_unit * 0.95, scale_unit)
			mesh_inst.mesh = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 0.65
	mat.roughness = 0.28
	mat.metallic = 0.35
	mesh_inst.set_surface_override_material(0, mat)
	return mesh_inst


func _on_counter_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		TimeManager.open_active_workbench()


func _on_door_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if TimeManager.current_phase == TimeManager.Phase.PREP:
			TimeManager.open_shop_shift()
		elif TimeManager.current_phase == TimeManager.Phase.OPEN and TimeManager.active_offer.is_empty():
			TimeManager.spawn_next_customer()


func _on_shelf_input(_cam: Node, event: InputEvent, _pos: Vector3, _norm: Vector3, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		set_camera_preset("overview" if _current_preset == "shelves" else "shelves")
