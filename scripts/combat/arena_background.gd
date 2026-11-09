class_name ArenaBackground
extends Node2D

# Procedural arena floor with four floor palettes and low-cost ambient animation.
# The floor geometry is static; reduced-motion mode disables its periodic redraw.

var flicker_timer: float = 0.0
var theme_name: String = "Abyssal Ruins"
var floor_base_color: Color = Color(0.05, 0.03, 0.07, 1.0)
var stone_base_color: Color = Color(0.09, 0.06, 0.13, 0.95)
var bevel_color: Color = Color(0.18, 0.13, 0.25, 0.6)
var border_color: Color = Color(0.25, 0.14, 0.38, 0.9)
var ring_color: Color = Color(0.7, 0.25, 0.95, 0.8)
var brazier_color: Color = Color(0.95, 0.35, 0.12, 0.9)

func _ready() -> void:
	set_floor_theme(GameManager.floor_number)

func set_floor_theme(floor_num: int) -> String:
	var themes: Array[Dictionary] = [
		{
			"name": "Abyssal Ruins",
			"floor": Color(0.05, 0.03, 0.07, 1.0),
			"stone": Color(0.09, 0.06, 0.13, 0.95),
			"bevel": Color(0.18, 0.13, 0.25, 0.6),
			"border": Color(0.25, 0.14, 0.38, 0.9),
			"ring": Color(0.7, 0.25, 0.95, 0.8),
			"fire": Color(0.95, 0.35, 0.12, 0.9)
		},
		{
			"name": "Blood Crypt",
			"floor": Color(0.07, 0.025, 0.03, 1.0),
			"stone": Color(0.13, 0.055, 0.065, 0.95),
			"bevel": Color(0.24, 0.10, 0.12, 0.65),
			"border": Color(0.42, 0.12, 0.18, 0.95),
			"ring": Color(0.95, 0.22, 0.32, 0.85),
			"fire": Color(1.0, 0.35, 0.12, 0.95)
		},
		{
			"name": "Frost Sanctum",
			"floor": Color(0.025, 0.05, 0.09, 1.0),
			"stone": Color(0.055, 0.10, 0.16, 0.95),
			"bevel": Color(0.12, 0.22, 0.3, 0.65),
			"border": Color(0.15, 0.32, 0.5, 0.95),
			"ring": Color(0.25, 0.7, 1.0, 0.85),
			"fire": Color(0.2, 0.7, 1.0, 0.9)
		},
		{
			"name": "Ashen Forge",
			"floor": Color(0.06, 0.04, 0.025, 1.0),
			"stone": Color(0.14, 0.08, 0.045, 0.95),
			"bevel": Color(0.25, 0.15, 0.08, 0.65),
			"border": Color(0.45, 0.24, 0.08, 0.95),
			"ring": Color(1.0, 0.55, 0.15, 0.85),
			"fire": Color(1.0, 0.3, 0.08, 0.95)
		}
	]
	var theme: Dictionary = themes[posmod(floor_num - 1, themes.size())]
	theme_name = str(theme["name"])
	floor_base_color = theme["floor"]
	stone_base_color = theme["stone"]
	bevel_color = theme["bevel"]
	border_color = theme["border"]
	ring_color = theme["ring"]
	brazier_color = theme["fire"]
	queue_redraw()
	return theme_name

func _process(delta: float) -> void:
	if SaveManager and bool(SaveManager.settings_data.get("reduced_motion", false)):
		return
	flicker_timer += delta
	if flicker_timer >= 0.16:
		flicker_timer = 0.0
		queue_redraw()

func _draw() -> void:
	var reduced_motion: bool = SaveManager and bool(SaveManager.settings_data.get("reduced_motion", false))
	draw_rect(Rect2(0, 0, 720, 1280), floor_base_color, true)

	# Beveled 2.5D stone tile grid.
	var tile_size := 75.0
	for x in range(25, 695, int(tile_size)):
		for y in range(65, 1155, int(tile_size)):
			var tile_rect := Rect2(x + 2, y + 2, tile_size - 4, tile_size - 4)
			var shade_offset := sin(float(x * 13 + y * 7)) * 0.015
			var stone_col := Color(stone_base_color.r + shade_offset, stone_base_color.g + shade_offset, stone_base_color.b + shade_offset, stone_base_color.a)
			draw_rect(tile_rect, stone_col, true)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.position.y), bevel_color, 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), bevel_color, 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.end.y), Vector2(tile_rect.end.x, tile_rect.end.y), Color(0.03, 0.02, 0.05, 0.8), 1.5)
			draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.end.y), Color(0.03, 0.02, 0.05, 0.8), 1.5)

	draw_rect(Rect2(20, 60, 680, 1100), border_color, false, 5.0)
	draw_rect(Rect2(25, 65, 670, 1090), border_color.darkened(0.35), false, 2.0)

	var center := Vector2(360, 640)
	var time_seconds: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 if reduced_motion else (1.0 + sin(time_seconds * 2.0)) * 0.5
	var ring_shadow := Color(ring_color.r * 0.18, ring_color.g * 0.12, ring_color.b * 0.22, 0.45)
	draw_circle(center, 220.0, ring_shadow)
	draw_arc(center, 220.0, 0, TAU, 64, Color(ring_color.r, ring_color.g, ring_color.b, 0.65 + pulse * 0.2), 3.0)
	draw_arc(center, 180.0, 0, TAU, 48, Color(ring_color.r, ring_color.g, ring_color.b, 0.45), 2.0)
	draw_arc(center, 120.0, 0, TAU, 32, Color(ring_color.r, ring_color.g, ring_color.b, 0.55), 2.0)

	for i in range(8):
		var angle := (TAU / 8.0) * float(i)
		var p1 := center + Vector2.RIGHT.rotated(angle) * 180.0
		var p2 := center + Vector2.RIGHT.rotated(angle + PI * 0.75) * 180.0
		draw_line(p1, p2, Color(ring_color.r, ring_color.g, ring_color.b, 0.4), 1.8)
		draw_circle(p1, 6.0, Color(ring_color.r, ring_color.g, ring_color.b, 0.85))
		draw_circle(p1, 2.5, Color(1.0, 1.0, 1.0, 0.95))

	var corners := [Vector2(75, 115), Vector2(645, 115), Vector2(75, 1105), Vector2(645, 1105)]
	var flicker: float = 0.0 if reduced_motion else sin(time_seconds * 8.0) * 3.0 + cos(time_seconds * 13.0) * 2.0
	for corner in corners:
		draw_circle(corner, 48.0 + flicker, Color(brazier_color.r, brazier_color.g, brazier_color.b, 0.15))
		draw_circle(corner, 28.0 + flicker * 0.5, Color(brazier_color.r, brazier_color.g, brazier_color.b, 0.25))
		draw_circle(corner, 16.0, Color(0.18, 0.1, 0.22, 0.95))
		draw_circle(corner, 11.0, brazier_color)
		draw_circle(corner, 5.0, Color(1.0, 0.9, 0.4, 1.0))
