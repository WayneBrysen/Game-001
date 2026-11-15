extends Control
## Interactive 2D inspection canvas with a mouse-driven UV scanner lens revealing stolen/beacon clues.

signal clue_revealed(clue_text: String, is_stolen: bool, has_beacon: bool)

var offer: Dictionary = {}
var uv_enabled: bool = true
var cursor_pos: Vector2 = Vector2(180, 140)
var hotspot_pos: Vector2 = Vector2(230, 115)
var beacon_pos: Vector2 = Vector2(125, 195)
var clue_unlocked: bool = false
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(360, 270)


func load_offer(new_offer: Dictionary) -> void:
	offer = new_offer
	clue_unlocked = false
	uv_enabled = true
	hotspot_pos = Vector2(randf_range(190.0, 285.0), randf_range(75.0, 145.0))
	beacon_pos = Vector2(randf_range(80.0, 175.0), randf_range(155.0, 215.0))
	cursor_pos = size * 0.5
	queue_redraw()


func toggle_uv(enabled: bool) -> void:
	uv_enabled = enabled
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		cursor_pos = event.position
		_check_scan_hits()
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		cursor_pos = event.position
		_check_scan_hits()
		queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_pulse += delta * 4.0
		queue_redraw()


func _check_scan_hits() -> void:
	if not uv_enabled or offer.is_empty() or clue_unlocked:
		return
	var dist_hot := cursor_pos.distance_to(hotspot_pos)
	var dist_beacon := cursor_pos.distance_to(beacon_pos)
	if dist_hot <= 52.0 or (offer.get("has_beacon", false) and dist_beacon <= 52.0):
		clue_unlocked = true
		clue_revealed.emit(
			offer.get("uv_clue", "Clean registration."),
			bool(offer.get("is_stolen", false)),
			bool(offer.get("has_beacon", false))
		)


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.05, 0.08, 0.12, 1.0))

	# Blueprint Grid
	var grid_col := Color(0.11, 0.24, 0.34, 0.45)
	for x in range(24, int(size.x), 24):
		draw_line(Vector2(x, 0), Vector2(x, size.y), grid_col, 1.0)
	for y in range(24, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), grid_col, 1.0)

	draw_rect(rect.grow(-2), Color(0.0, 0.85, 1.0, 0.65), false, 2.0)
	if offer.is_empty():
		return

	# Draw stylized 2D item schematic in center
	var center := size * 0.5
	var col: Color = offer.get("item_color", Color.CYAN)
	var shape: String = offer.get("item_shape", "box")

	match shape:
		"vial":
			draw_rect(Rect2(center.x - 30, center.y - 78, 60, 156), col.darkened(0.45))
			draw_rect(Rect2(center.x - 30, center.y - 78, 60, 156), col, false, 3.0)
			draw_rect(Rect2(center.x - 20, center.y - 24, 40, 76), col)
		"cylinder":
			draw_rect(Rect2(center.x - 48, center.y - 68, 96, 136), col.darkened(0.35))
			draw_rect(Rect2(center.x - 48, center.y - 68, 96, 136), col, false, 3.0)
			draw_line(Vector2(center.x - 48, center.y - 28), Vector2(center.x + 48, center.y - 28), Color.WHITE, 2.0)
		"chip":
			draw_rect(Rect2(center.x - 76, center.y - 52, 152, 104), col.darkened(0.4))
			draw_rect(Rect2(center.x - 76, center.y - 52, 152, 104), col, false, 3.0)
			for i in range(-50, 60, 25):
				draw_rect(Rect2(center.x + i - 6, center.y - 62, 12, 10), Color(0.95, 0.8, 0.3))
				draw_rect(Rect2(center.x + i - 6, center.y + 52, 12, 10), Color(0.95, 0.8, 0.3))
		_:
			draw_rect(Rect2(center.x - 68, center.y - 58, 136, 116), col.darkened(0.35))
			draw_rect(Rect2(center.x - 68, center.y - 58, 136, 116), col, false, 3.0)
			draw_rect(Rect2(center.x - 40, center.y - 30, 80, 60), col.lightened(0.18), false, 2.0)

	# Serial label bar
	draw_rect(Rect2(16, 14, 150, 24), Color(0.08, 0.12, 0.18, 0.9))
	draw_string(ThemeDB.fallback_font, Vector2(22, 31), "SN: %s" % offer.get("serial", "???"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.92, 1.0))

	# UV layer hidden markers & lens
	if uv_enabled:
		var lens_radius := 58.0
		draw_circle(cursor_pos, lens_radius, Color(0.55, 0.16, 0.95, 0.18))
		draw_arc(cursor_pos, lens_radius, 0.0, TAU, 36, Color(0.85, 0.35, 1.0, 0.9), 2.5)

		if cursor_pos.distance_to(hotspot_pos) <= lens_radius + 12.0 or clue_unlocked:
			var is_hot := bool(offer.get("is_stolen", false))
			var mark_col := Color(1.0, 0.25, 0.55) if is_hot else Color(0.25, 1.0, 0.7)
			draw_circle(hotspot_pos, 16.0 + sin(_pulse) * 2.0, Color(mark_col.r, mark_col.g, mark_col.b, 0.28))
			draw_arc(hotspot_pos, 18.0, 0.0, TAU, 24, mark_col, 2.5)
			var tag := "SCRAPED ID!" if is_hot else "VALID SEAL"
			draw_string(ThemeDB.fallback_font, hotspot_pos + Vector2(-36, -24), tag, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, mark_col)

		if bool(offer.get("has_beacon", false)) and (cursor_pos.distance_to(beacon_pos) <= lens_radius + 12.0 or clue_unlocked):
			var b_col := Color(1.0, 0.85, 0.2, 0.65 + 0.35 * sin(_pulse * 1.5))
			draw_circle(beacon_pos, 10.0, b_col)
			draw_arc(beacon_pos, 22.0, 0.0, TAU, 24, Color(1.0, 0.45, 0.2), 2.0)
			draw_string(ThemeDB.fallback_font, beacon_pos + Vector2(-42, 34), "CORP BEACON", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.72, 0.25))
