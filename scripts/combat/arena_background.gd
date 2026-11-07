class_name ArenaBackground
extends Node2D

# Atmospheric dark-fantasy 2.5D arena floor rendering with beveled abyssal stone tiles,
# glowing summoning circle runes, corner braziers, and dynamic torchlight flicker.

var flicker_timer: float = 0.0

func _process(delta: float) -> void:
	flicker_timer += delta
	if flicker_timer >= 0.08:
		flicker_timer = 0.0
		queue_redraw()

func _draw() -> void:
	# Deep dark void floor
	draw_rect(Rect2(0, 0, 720, 1280), Color(0.05, 0.03, 0.07, 1.0), true)
	
	# Beveled 2.5D stone tile grid
	var tile_size := 75.0
	for x in range(25, 695, int(tile_size)):
		for y in range(65, 1155, int(tile_size)):
			var tile_rect := Rect2(x + 2, y + 2, tile_size - 4, tile_size - 4)
			# Slate stone base with subtle random shade
			var shade_offset := sin(float(x * 13 + y * 7)) * 0.015
			var stone_col := Color(0.09 + shade_offset, 0.06 + shade_offset, 0.13 + shade_offset, 0.95)
			draw_rect(tile_rect, stone_col, true)
			# 2.5D top/left highlight bevel
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.position.y), Color(0.18, 0.13, 0.25, 0.6), 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), Color(0.18, 0.13, 0.25, 0.6), 1.0)
			# Bottom/right shadow bevel
			draw_line(Vector2(tile_rect.position.x, tile_rect.end.y), Vector2(tile_rect.end.x, tile_rect.end.y), Color(0.03, 0.02, 0.05, 0.8), 1.5)
			draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.end.y), Color(0.03, 0.02, 0.05, 0.8), 1.5)

	# Outer border boundary stone walls with depth shadow
	draw_rect(Rect2(20, 60, 680, 1100), Color(0.25, 0.14, 0.38, 0.9), false, 5.0)
	draw_rect(Rect2(25, 65, 670, 1090), Color(0.14, 0.08, 0.2, 0.6), false, 2.0)
	
	# Central Abyssal Altar Summoning Ring (Center: 360, 640)
	var center := Vector2(360, 640)
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse := (1.0 + sin(t * 2.0)) * 0.5
	
	# Glowing runes
	draw_circle(center, 220.0, Color(0.1, 0.04, 0.16, 0.45))
	draw_arc(center, 220.0, 0, TAU, 64, Color(0.55 + pulse * 0.15, 0.2, 0.8, 0.7), 3.0)
	draw_arc(center, 180.0, 0, TAU, 48, Color(0.7, 0.25, 0.95, 0.45), 2.0)
	draw_arc(center, 120.0, 0, TAU, 32, Color(0.85, 0.35, 1.0, 0.55), 2.0)
	
	# Double Octagram runic star lines
	for i in range(8):
		var angle := (TAU / 8.0) * float(i)
		var p1 := center + Vector2.RIGHT.rotated(angle) * 180.0
		var p2 := center + Vector2.RIGHT.rotated(angle + PI * 0.75) * 180.0
		draw_line(p1, p2, Color(0.75, 0.25, 1.0, 0.4), 1.8)
		# Glowing node sigils
		draw_circle(p1, 6.0, Color(0.9, 0.35, 1.0, 0.85))
		draw_circle(p1, 2.5, Color(1.0, 1.0, 1.0, 0.95))

	# Corner Braziers with dynamic torchlight flicker
	var corners := [Vector2(75, 115), Vector2(645, 115), Vector2(75, 1105), Vector2(645, 1105)]
	var flk := sin(t * 8.0) * 3.0 + cos(t * 13.0) * 2.0
	for c in corners:
		# Ambient glowing light pool
		draw_circle(c, 48.0 + flk, Color(0.9, 0.3, 0.1, 0.15))
		draw_circle(c, 28.0 + flk * 0.5, Color(0.95, 0.4, 0.15, 0.25))
		# Brazier stone pillar
		draw_circle(c, 16.0, Color(0.18, 0.1, 0.22, 0.95))
		draw_circle(c, 11.0, Color(0.95, 0.25, 0.15, 0.9))
		draw_circle(c, 5.0, Color(1.0, 0.9, 0.4, 1.0))
