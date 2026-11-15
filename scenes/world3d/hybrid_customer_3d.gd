@tool
extends Node3D
## 2D-in-3D hybrid customer node: SubViewport 2D sprite projected onto a Y-Billboard Sprite3D.

signal arrived_at_counter
signal exited_shop

@onready var sub_viewport: SubViewport = $SubViewport
@onready var portrait_2d: Node2D = $SubViewport/CustomerPortrait2D
@onready var sprite_3d: Sprite3D = $Sprite3D

var _move_tween: Tween


func _ready() -> void:
	if sprite_3d and sub_viewport:
		sprite_3d.texture = sub_viewport.get_texture()
	if not Engine.is_editor_hint():
		visible = false


func enter_shop(offer: Dictionary, start_pos: Vector3, counter_pos: Vector3) -> void:
	if _move_tween:
		_move_tween.kill()
	position = start_pos
	visible = true
	portrait_2d.apply_profile(offer)
	portrait_2d.is_walking = true

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", counter_pos, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_move_tween.finished.connect(func() -> void:
		portrait_2d.is_walking = false
		arrived_at_counter.emit()
	)


func leave_shop(exit_pos: Vector3) -> void:
	if _move_tween:
		_move_tween.kill()
	portrait_2d.is_walking = true
	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", exit_pos, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_move_tween.finished.connect(func() -> void:
		portrait_2d.is_walking = false
		visible = false
		exited_shop.emit()
	)
