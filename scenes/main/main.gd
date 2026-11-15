extends Node
## Root coordinator bridging the 3D shop world, 2D appraisal workbench, and HUD layers.

@onready var shop_world_3d: Node3D = $ShopWorld3D
@onready var hud: Control = $UILayer/HUD
@onready var workbench_2d: Control = $UILayer/AppraisalWorkbench2D


func _ready() -> void:
	GameEvents.workbench_requested.connect(_on_workbench_requested)
	GameEvents.workbench_closed.connect(_on_workbench_closed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_workbench"):
		if workbench_2d.visible:
			workbench_2d.close_workbench()
		else:
			TimeManager.open_active_workbench()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_uv") and workbench_2d.visible:
		workbench_2d.toggle_uv_shortcut()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact") and not workbench_2d.visible:
		hud.trigger_primary_context_action()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("cam_preset_1") and not workbench_2d.visible:
		shop_world_3d.set_camera_preset("overview")
	elif event.is_action_pressed("cam_preset_2") and not workbench_2d.visible:
		shop_world_3d.set_camera_preset("counter")
	elif event.is_action_pressed("cam_preset_3") and not workbench_2d.visible:
		shop_world_3d.set_camera_preset("shelves")


func _on_workbench_requested(offer: Dictionary) -> void:
	shop_world_3d.set_workbench_dimmed(true)
	workbench_2d.open_with_offer(offer)


func _on_workbench_closed() -> void:
	shop_world_3d.set_workbench_dimmed(false)
