class_name DioramaIsland
extends Control

# Custom 2.5D isometric diorama island renderer (Ref Image 2).
# Renders floating mossy stone island on mystical abyssal water,
# trees, adventurer tent, flickering campfire, and ancient runic altar.

var _anim_time: float = 0.0

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5 + Vector2(0, 20)
	var t := _anim_time
	
	# 1. Shimmering water ripples beneath island
	for i in range(3):
		var phase: float = fmod(t * 0.8 + float(i) * 0.33, 1.0)
		var rx := 220.0 + phase * 60.0
		var ry := 90.0 + phase * 25.0
		var alpha := (1.0 - phase) * 0.35
		draw_arc(center + Vector2(0, 75), rx, 0.0, TAU, 32, Color(0.2, 0.65, 0.9, alpha), 2.5)
		
	# 2. Island Under-Cliff (Dark Stone Extrusion)
	var cliff_pts := PackedVector2Array([
		center + Vector2(-190, 10),
		center + Vector2(-150, 85),
		center + Vector2(0, 115),
		center + Vector2(160, 80),
		center + Vector2(195, 10),
		center + Vector2(140, 25),
		center + Vector2(0, 35),
		center + Vector2(-140, 25)
	])
	draw_colored_polygon(cliff_pts, Color(0.12, 0.14, 0.2, 0.98))
	draw_polyline(cliff_pts, Color(0.25, 0.28, 0.38, 0.8), 2.0)
	
	# Cliff stratification layers
	draw_line(center + Vector2(-120, 60), center + Vector2(0, 80), Color(0.18, 0.22, 0.3, 0.8), 2.0)
	draw_line(center + Vector2(0, 80), center + Vector2(120, 55), Color(0.18, 0.22, 0.3, 0.8), 2.0)

	# 3. Island Top Plateau (Ancient Abyssal Dark Stone Surface)
	var top_pts := PackedVector2Array([
		center + Vector2(0, -75),
		center + Vector2(195, 10),
		center + Vector2(0, 55),
		center + Vector2(-190, 10)
	])
	# Deep dark-slate obsidian plateau with subtle dark rune-stone rim
	draw_colored_polygon(top_pts, Color(0.11, 0.14, 0.21, 1.0))
	draw_polyline(top_pts, Color(0.24, 0.32, 0.44, 0.8), 2.5)
	
	# Inner path / clearing
	var path_pts := PackedVector2Array([
		center + Vector2(-40, -10),
		center + Vector2(50, -20),
		center + Vector2(70, 20),
		center + Vector2(-20, 30)
	])
	draw_colored_polygon(path_pts, Color(0.28, 0.25, 0.22, 0.85))

	# 4. Ancient Altar Stone in Plateau Center
	var altar_pos := center + Vector2(-10, -5)
	draw_rect(Rect2(altar_pos - Vector2(26, 16), Vector2(52, 32)), Color(0.16, 0.13, 0.24, 0.95), true)
	draw_rect(Rect2(altar_pos - Vector2(26, 16), Vector2(52, 32)), Color(0.85, 0.68, 0.25, 0.9), false, 2.0)
	# Glowing arcane rune glyph on altar
	var pulse := (1.0 + sin(t * 3.0)) * 0.5
	draw_circle(altar_pos, 8.0 + pulse * 2.0, Color(0.3, 0.75, 1.0, 0.35 * pulse))
	draw_circle(altar_pos, 4.0, Color(0.65, 0.9, 1.0, 0.9))

	# 5. Adventurer's Campfire
	var fire_pos := center + Vector2(85, 15)
	draw_circle(fire_pos, 10.0, Color(0.2, 0.15, 0.12, 0.9)) # Fire pit rocks
	var flame_flicker := sin(t * 12.0) * 3.0
	var flame_pts := PackedVector2Array([
		fire_pos + Vector2(-6, 2),
		fire_pos + Vector2(0, -14 + flame_flicker),
		fire_pos + Vector2(6, 2)
	])
	draw_colored_polygon(flame_pts, Color(1.0, 0.55, 0.1, 0.95))
	draw_circle(fire_pos + Vector2(0, -4), 4.0, Color(1.0, 0.9, 0.3, 0.95))
	# Floating embers
	for e in range(3):
		var ep := fmod(t * 1.5 + float(e) * 0.4, 1.0)
		var ex := fire_pos.x + sin(t * 3.0 + float(e)) * 8.0
		var ey := fire_pos.y - 12.0 - ep * 24.0
		draw_circle(Vector2(ex, ey), 1.5, Color(1.0, 0.7, 0.2, (1.0 - ep) * 0.8))

	# 6. Adventurer's Tent
	var tent_pos := center + Vector2(110, -25)
	var tent_pts := PackedVector2Array([
		tent_pos + Vector2(0, -28),
		tent_pos + Vector2(-22, 10),
		tent_pos + Vector2(16, 14)
	])
	draw_colored_polygon(tent_pts, Color(0.72, 0.48, 0.28, 0.95))
	draw_polyline(tent_pts, Color(0.45, 0.3, 0.18, 0.9), 1.8)
	# Tent flap
	var flap_pts := PackedVector2Array([
		tent_pos + Vector2(0, -28),
		tent_pos + Vector2(-5, 10),
		tent_pos + Vector2(10, 12)
	])
	draw_colored_polygon(flap_pts, Color(0.2, 0.15, 0.1, 0.8))

	# 7. Chibi Trees & Pine Foliage (Left ridge)
	_draw_chibi_tree(center + Vector2(-110, -15), 1.0)
	_draw_chibi_tree(center + Vector2(-75, -45), 0.85)
	_draw_chibi_tree(center + Vector2(-140, 5), 0.75)

func _draw_chibi_tree(pos: Vector2, scale_fac: float) -> void:
	# Trunk
	draw_rect(Rect2(pos + Vector2(-3 * scale_fac, 0), Vector2(6 * scale_fac, 16 * scale_fac)), Color(0.35, 0.22, 0.12, 1.0), true)
	# Tiered pine triangles
	var c_col := Color(0.12, 0.42, 0.22, 0.95)
	for i in range(3):
		var y_off := -float(i) * 12.0 * scale_fac
		var w := (22.0 - float(i) * 4.0) * scale_fac
		var h := 16.0 * scale_fac
		var pts := PackedVector2Array([
			pos + Vector2(0, y_off - h),
			pos + Vector2(-w, y_off),
			pos + Vector2(w, y_off)
		])
		draw_colored_polygon(pts, c_col)
		draw_polyline(pts, Color(0.2, 0.6, 0.3, 0.8), 1.2)
