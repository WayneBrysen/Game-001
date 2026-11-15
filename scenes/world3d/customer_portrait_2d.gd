@tool
extends Node2D
## Procedural 2D cyberpunk customer sprite rendered inside a SubViewport for 3D Y-billboarding.

@export var coat_color: Color = Color(0.24, 0.58, 0.48)
@export var visor_color: Color = Color(0.2, 0.95, 0.72)
@export var skin_color: Color = Color(0.76, 0.62, 0.54)
@export var accent_color: Color = Color(1.0, 0.25, 0.68)

var is_walking: bool = false
var is_suspicious: bool = false
var bob_time: float = 0.0
var item_tint: Color = Color.TRANSPARENT


func _process(delta: float) -> void:
	var speed := 9.0 if is_walking else 2.6
	bob_time += delta * speed
	queue_redraw()


func apply_profile(offer: Dictionary) -> void:
	coat_color = offer.get("coat_color", coat_color)
	visor_color = offer.get("visor_color", visor_color)
	skin_color = offer.get("skin_color", skin_color)
	is_suspicious = bool(offer.get("is_sting", false)) or bool(offer.get("is_stolen", false))
	item_tint = offer.get("item_color", Color.CYAN)
	queue_redraw()


func _draw() -> void:
	var cx := 128.0
	var breath := sin(bob_time) * (4.5 if is_walking else 2.0)
	var sway := cos(bob_time * 0.5) * (3.0 if is_walking else 0.6)
	var base_y := 300.0

	# Ground outline / neon rim base
	draw_rect(Rect2(cx - 46 + sway, base_y - 12, 92, 8), Color(visor_color.r, visor_color.g, visor_color.b, 0.22))

	# Legs
	var leg_offset := sin(bob_time) * 6.0 if is_walking else 0.0
	draw_rect(Rect2(cx - 28 + sway, 224 + leg_offset, 20, 72), Color(0.11, 0.13, 0.19))
	draw_rect(Rect2(cx + 8 + sway, 224 - leg_offset, 20, 72), Color(0.11, 0.13, 0.19))
	# Boots
	draw_rect(Rect2(cx - 32 + sway, 282 + leg_offset, 26, 14), Color(0.18, 0.21, 0.28))
	draw_rect(Rect2(cx + 6 + sway, 282 - leg_offset, 26, 14), Color(0.18, 0.21, 0.28))

	# Trenchcoat torso
	var torso_top := 124.0 + breath
	var coat_pts := PackedVector2Array([
		Vector2(cx - 42 + sway, torso_top + 10),
		Vector2(cx + 42 + sway, torso_top + 10),
		Vector2(cx + 50 + sway, 240.0 + breath * 0.4),
		Vector2(cx - 50 + sway, 240.0 + breath * 0.4),
	])
	draw_colored_polygon(coat_pts, coat_color)
	draw_polyline(coat_pts + PackedVector2Array([coat_pts[0]]), Color(0.06, 0.08, 0.12), 3.0)

	# High cyber collar & neon lapel trim
	draw_rect(Rect2(cx - 30 + sway, torso_top - 4, 60, 22), coat_color.darkened(0.28))
	draw_line(Vector2(cx - 18 + sway, torso_top + 14), Vector2(cx - 18 + sway, 226), visor_color, 3.0)
	draw_line(Vector2(cx + 18 + sway, torso_top + 14), Vector2(cx + 18 + sway, 226), visor_color, 3.0)

	# Chest inner shirt / harness
	draw_rect(Rect2(cx - 14 + sway, torso_top + 14, 28, 76), Color(0.1, 0.12, 0.17))

	# Head & cyber hood/hair
	var head_y := 86.0 + breath
	draw_circle(Vector2(cx + sway, head_y), 29.0, skin_color)
	draw_arc(Vector2(cx + sway, head_y), 30.0, PI * 0.92, PI * 2.08, 24, Color(0.08, 0.1, 0.16), 10.0)

	# Cyber Visor
	draw_rect(Rect2(cx - 24 + sway, head_y - 10, 48, 14), Color(0.05, 0.07, 0.11))
	draw_rect(Rect2(cx - 21 + sway, head_y - 7, 42, 8), visor_color)

	# Suspicion cue (sweat / scanner ping)
	if is_suspicious and not Engine.is_editor_hint():
		var pulse := 0.55 + 0.45 * sin(bob_time * 2.0)
		draw_circle(Vector2(cx + 34 + sway, head_y - 24), 6.0, Color(1.0, 0.85, 0.2, pulse))

	# Held item silhouette near front hand
	if item_tint.a > 0.05:
		var hand_pos := Vector2(cx + 36 + sway, torso_top + 56)
		draw_rect(Rect2(hand_pos.x - 12, hand_pos.y - 12, 24, 24), item_tint)
		draw_rect(Rect2(hand_pos.x - 12, hand_pos.y - 12, 24, 24), Color(1, 1, 1, 0.7), false, 2.0)
