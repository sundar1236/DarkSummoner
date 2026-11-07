class_name HeroPedestalView
extends Control

# Renders the Chibi Hero on a glowing elemental pedestal with breathing bob,
# oversized weapon, and a floating elemental spirit companion (Ref Images 4, 5, 6).

@export var character_id: String = "shadow_hunter"
var _t: float = 0.0

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5 + Vector2(0, 30)
	var t := _t
	var pulse := (1.0 + sin(t * 3.0)) * 0.5
	var bob := sin(t * 2.5) * 4.0
	
	# 1. Glowing Elemental Pedestal (Tiered Hexagonal / Oval Stone with Runic Rim)
	var ped_center := center + Vector2(0, 50)
	draw_arc(ped_center, 90.0, 0.0, TAU, 32, Color(0.2, 0.65, 1.0, 0.25 * pulse), 3.0)
	draw_arc(ped_center, 70.0, 0.0, TAU, 32, Color(0.4, 0.8, 1.0, 0.5), 2.0)
	
	# Pedestal Base Polygon
	var ped_pts := PackedVector2Array([
		ped_center + Vector2(-80, 0),
		ped_center + Vector2(-55, 25),
		ped_center + Vector2(55, 25),
		ped_center + Vector2(80, 0),
		ped_center + Vector2(55, -20),
		ped_center + Vector2(-55, -20)
	])
	draw_colored_polygon(ped_pts, Color(0.1, 0.12, 0.2, 0.95))
	draw_polyline(ped_pts, Color(0.85, 0.72, 0.3, 0.9), 2.5)
	
	# Pedestal runic glow
	draw_circle(ped_center, 40.0, Color(0.15, 0.5, 0.9, 0.25 * pulse))

	# 2. Hero Body — Chibi Proportions (2.2 heads tall)
	var hero_pos := center + Vector2(0, bob)
	
	# Cape / Shadows behind
	var cape_pts := PackedVector2Array([
		hero_pos + Vector2(-15, -10),
		hero_pos + Vector2(15, -10),
		hero_pos + Vector2(25, 35),
		hero_pos + Vector2(-25, 35)
	])
	draw_colored_polygon(cape_pts, Color(0.08, 0.06, 0.14, 0.95))
	
	# Torso & Tunic
	var tunic_pts := PackedVector2Array([
		hero_pos + Vector2(-14, -8),
		hero_pos + Vector2(14, -8),
		hero_pos + Vector2(18, 22),
		hero_pos + Vector2(-18, 22)
	])
	draw_colored_polygon(tunic_pts, Color(0.18, 0.22, 0.34, 1.0))
	draw_polyline(tunic_pts, Color(0.85, 0.7, 0.25, 0.9), 1.5)
	
	# Gold belt with gem
	draw_rect(Rect2(hero_pos + Vector2(-12, 10), Vector2(24, 6)), Color(0.9, 0.75, 0.25, 1.0), true)
	draw_circle(hero_pos + Vector2(0, 13), 3.0, Color(0.95, 0.25, 0.25, 1.0))

	# Chibi Head (Large expressive head)
	var head_center := hero_pos + Vector2(0, -32)
	# Hair / Hood
	draw_circle(head_center, 26.0, Color(0.12, 0.1, 0.18, 1.0))
	# Face
	draw_circle(head_center + Vector2(0, 2), 20.0, Color(0.96, 0.85, 0.78, 1.0))
	
	# Expressive Large Eyes
	var eye_l := head_center + Vector2(-8, 2)
	var eye_r := head_center + Vector2(8, 2)
	draw_circle(eye_l, 5.0, Color(0.15, 0.15, 0.22, 1.0))
	draw_circle(eye_r, 5.0, Color(0.15, 0.15, 0.22, 1.0))
	# Iris glow (purple for shadow hunter, cyan for storm reaper, gold for valkyrie)
	var iris_col := Color(0.65, 0.3, 0.95, 1.0)
	if character_id == "storm_reaper":
		iris_col = Color(0.2, 0.85, 1.0, 1.0)
	elif character_id == "soul_binder":
		iris_col = Color(0.3, 0.95, 0.65, 1.0)
	draw_circle(eye_l, 3.2, iris_col)
	draw_circle(eye_r, 3.2, iris_col)
	# Eye catchlights
	draw_circle(eye_l + Vector2(-1.2, -1.2), 1.5, Color.WHITE)
	draw_circle(eye_r + Vector2(-1.2, -1.2), 1.5, Color.WHITE)
	
	# Cute smile
	draw_arc(head_center + Vector2(0, 11), 4.0, 0.2, PI - 0.2, 8, Color(0.4, 0.2, 0.2, 0.8), 1.5)

	# 3. Oversized Signature Weapon (Right hand)
	var weap_pos := hero_pos + Vector2(28, 4)
	# Blade / Scythe
	draw_line(weap_pos + Vector2(0, 25), weap_pos + Vector2(0, -30), Color(0.45, 0.35, 0.25, 1.0), 3.0) # Haft
	var blade_pts := PackedVector2Array([
		weap_pos + Vector2(0, -30),
		weap_pos + Vector2(-22, -45),
		weap_pos + Vector2(-10, -20)
	])
	draw_colored_polygon(blade_pts, Color(0.85, 0.9, 1.0, 1.0))
	draw_polyline(blade_pts, Color(0.85, 0.7, 0.25, 1.0), 2.0)

	# 4. Floating Elemental Spirit Companion (Flits to the upper left)
	var comp_bob := sin(t * 3.5) * 6.0
	var comp_pos := hero_pos + Vector2(-48, -45 + comp_bob)
	# Outer aura
	draw_circle(comp_pos, 14.0 + pulse * 3.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.3))
	# Inner wisp
	draw_circle(comp_pos, 8.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.9))
	draw_circle(comp_pos + Vector2(-2, -2), 3.0, Color.WHITE)
	# Tiny wisp trail
	for tr in range(3):
		var tra := comp_pos + Vector2(float(tr) * 4.0, 10.0 + float(tr) * 5.0)
		draw_circle(tra, (3.0 - float(tr)) * 0.8, Color(iris_col.r, iris_col.g, iris_col.b, 0.5 - float(tr) * 0.15))
