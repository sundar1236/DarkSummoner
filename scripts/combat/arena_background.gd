class_name ArenaBackground
extends Node2D

# Atmospheric dark-fantasy 2.5D arena floor rendering with beveled abyssal stone tiles,
# glowing summoning circle runes, corner braziers, and dynamic torchlight flicker.

var flicker_timer: float = 0.0
var reduced_effects: bool = false
var floor_theme_name: String = "Abyssal Ruins"
var floor_background_color: Color = Color(0.05, 0.03, 0.07, 1.0)
var tile_base_color: Color = Color(0.09, 0.06, 0.13, 0.95)
var tile_highlight_color: Color = Color(0.18, 0.13, 0.25, 0.6)
var border_color: Color = Color(0.25, 0.14, 0.38, 0.9)
var rune_color: Color = Color(0.7, 0.25, 0.95, 0.85)
var brazier_glow_color: Color = Color(0.9, 0.3, 0.1, 0.15)
var brazier_flame_color: Color = Color(0.95, 0.25, 0.15, 0.9)

func set_floor_theme(floor_num: int) -> void:
	var theme_index := posmod(maxi(floor_num, 1) - 1, 5)
	match theme_index:
		0:
			floor_theme_name = "Abyssal Ruins"
			floor_background_color = Color(0.05, 0.03, 0.07, 1.0)
			tile_base_color = Color(0.09, 0.06, 0.13, 0.95)
			tile_highlight_color = Color(0.18, 0.13, 0.25, 0.6)
			border_color = Color(0.25, 0.14, 0.38, 0.9)
			rune_color = Color(0.7, 0.25, 0.95, 0.85)
			brazier_glow_color = Color(0.9, 0.3, 0.1, 0.15)
			brazier_flame_color = Color(0.95, 0.25, 0.15, 0.9)
		1:
			floor_theme_name = "Ember Catacombs"
			floor_background_color = Color(0.09, 0.035, 0.025, 1.0)
			tile_base_color = Color(0.16, 0.075, 0.045, 0.95)
			tile_highlight_color = Color(0.3, 0.16, 0.09, 0.65)
			border_color = Color(0.48, 0.19, 0.07, 0.9)
			rune_color = Color(1.0, 0.42, 0.12, 0.9)
			brazier_glow_color = Color(1.0, 0.28, 0.04, 0.2)
			brazier_flame_color = Color(1.0, 0.48, 0.12, 0.95)
		2:
			floor_theme_name = "Frostbound Crypt"
			floor_background_color = Color(0.025, 0.055, 0.09, 1.0)
			tile_base_color = Color(0.055, 0.11, 0.17, 0.95)
			tile_highlight_color = Color(0.13, 0.24, 0.34, 0.65)
			border_color = Color(0.12, 0.32, 0.48, 0.9)
			rune_color = Color(0.25, 0.78, 1.0, 0.9)
			brazier_glow_color = Color(0.12, 0.55, 1.0, 0.18)
			brazier_flame_color = Color(0.3, 0.8, 1.0, 0.95)
		3:
			floor_theme_name = "Blighted Sanctum"
			floor_background_color = Color(0.025, 0.065, 0.045, 1.0)
			tile_base_color = Color(0.055, 0.12, 0.075, 0.95)
			tile_highlight_color = Color(0.14, 0.25, 0.16, 0.65)
			border_color = Color(0.18, 0.38, 0.2, 0.9)
			rune_color = Color(0.42, 0.95, 0.38, 0.9)
			brazier_glow_color = Color(0.25, 0.9, 0.2, 0.18)
			brazier_flame_color = Color(0.55, 1.0, 0.3, 0.95)
		4:
			floor_theme_name = "Crimson Throne"
			floor_background_color = Color(0.075, 0.025, 0.045, 1.0)
			tile_base_color = Color(0.14, 0.055, 0.075, 0.95)
			tile_highlight_color = Color(0.28, 0.12, 0.16, 0.65)
			border_color = Color(0.42, 0.12, 0.18, 0.9)
			rune_color = Color(1.0, 0.3, 0.38, 0.9)
			brazier_glow_color = Color(1.0, 0.12, 0.2, 0.2)
			brazier_flame_color = Color(1.0, 0.42, 0.25, 0.95)
	queue_redraw()

func _ready() -> void:
	add_to_group("arena_backgrounds")
	set_reduced_effects(bool(SaveManager.settings_data.get("reduced_effects", false)))

func set_reduced_effects(enabled: bool) -> void:
	reduced_effects = enabled
	set_process(not enabled)
	if enabled:
		flicker_timer = 0.0
	queue_redraw()

func _shade_color(base: Color, amount: float) -> Color:
	return Color(
		clampf(base.r + amount, 0.0, 1.0),
		clampf(base.g + amount, 0.0, 1.0),
		clampf(base.b + amount, 0.0, 1.0),
		base.a
	)

func _process(delta: float) -> void:
	flicker_timer += delta
	if flicker_timer >= 0.08:
		flicker_timer = 0.0
		queue_redraw()

func _draw() -> void:
	# Deep dark void floor
	draw_rect(Rect2(0, 0, 720, 1280), floor_background_color, true)
	
	# Beveled 2.5D stone tile grid
	var tile_size := 75.0
	for x in range(25, 695, int(tile_size)):
		for y in range(65, 1155, int(tile_size)):
			var tile_rect := Rect2(x + 2, y + 2, tile_size - 4, tile_size - 4)
			# Slate stone base with subtle random shade
			var shade_offset := sin(float(x * 13 + y * 7)) * 0.015
			var stone_col := _shade_color(tile_base_color, shade_offset)
			draw_rect(tile_rect, stone_col, true)
			# 2.5D top/left highlight bevel
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.position.y), tile_highlight_color, 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), tile_highlight_color, 1.0)
			# Bottom/right shadow bevel
			draw_line(Vector2(tile_rect.position.x, tile_rect.end.y), Vector2(tile_rect.end.x, tile_rect.end.y), tile_base_color.darkened(0.7), 1.5)
			draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.end.y), tile_base_color.darkened(0.7), 1.5)

	# Outer border boundary stone walls with depth shadow
	draw_rect(Rect2(20, 60, 680, 1100), border_color, false, 5.0)
	draw_rect(Rect2(25, 65, 670, 1090), border_color.darkened(0.35), false, 2.0)
	
	# Central Abyssal Altar Summoning Ring (Center: 360, 640)
	var center := Vector2(360, 640)
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse := (1.0 + sin(t * 2.0)) * 0.5
	
	# Glowing runes
	draw_circle(center, 220.0, Color(floor_background_color.r, floor_background_color.g, floor_background_color.b, 0.45))
	draw_arc(center, 220.0, 0, TAU, 64, _shade_color(rune_color, pulse * 0.12), 3.0)
	draw_arc(center, 180.0, 0, TAU, 48, Color(rune_color.r, rune_color.g, rune_color.b, 0.45), 2.0)
	draw_arc(center, 120.0, 0, TAU, 32, Color(rune_color.r, rune_color.g, rune_color.b, 0.62), 2.0)
	
	# Double Octagram runic star lines
	for i in range(8):
		var angle := (TAU / 8.0) * float(i)
		var p1 := center + Vector2.RIGHT.rotated(angle) * 180.0
		var p2 := center + Vector2.RIGHT.rotated(angle + PI * 0.75) * 180.0
		draw_line(p1, p2, Color(rune_color.r, rune_color.g, rune_color.b, 0.45), 1.8)
		# Glowing node sigils
		draw_circle(p1, 6.0, rune_color.lightened(0.15))
		draw_circle(p1, 2.5, Color(1.0, 1.0, 1.0, 0.95))

	# Corner Braziers with dynamic torchlight flicker
	var corners := [Vector2(75, 115), Vector2(645, 115), Vector2(75, 1105), Vector2(645, 1105)]
	var flk := sin(t * 8.0) * 3.0 + cos(t * 13.0) * 2.0
	for c in corners:
		# Ambient glowing light pool
		draw_circle(c, 48.0 + flk, brazier_glow_color)
		draw_circle(c, 28.0 + flk * 0.5, Color(brazier_flame_color.r, brazier_flame_color.g, brazier_flame_color.b, 0.25))
		# Brazier stone pillar
		draw_circle(c, 16.0, tile_highlight_color.darkened(0.45))
		draw_circle(c, 11.0, brazier_flame_color)
		draw_circle(c, 5.0, Color(1.0, 0.9, 0.4, 1.0))
