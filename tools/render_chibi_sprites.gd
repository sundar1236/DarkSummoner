extends Node2D

# High-Detail 2D Dark-Fantasy Chibi Character & Combat Sprite Renderer.
# Uses Godot's full 2D vector drawing pipeline (anti-aliased polygons, lines,
# arcs, gradients, and glows) on 256x256 viewports to produce production-grade
# dark-fantasy chibi sprites.

func _ready() -> void:
	print("--- Rendering High-Detail Chibi Sprites via 2D Canvas Pipeline ---")
	
	_render_and_save("player_shadow_hunter", Vector2(160, 160), _draw_shadow_hunter)
	_render_and_save("player_base", Vector2(160, 160), _draw_shadow_hunter)
	_render_and_save("player_storm_reaper", Vector2(160, 160), _draw_storm_reaper)
	_render_and_save("player_soul_binder", Vector2(160, 160), _draw_soul_binder)
	
	_render_and_save("enemy_swarmer", Vector2(128, 128), _draw_enemy_swarmer)
	_render_and_save("enemy_cultist", Vector2(128, 128), _draw_enemy_cultist)
	_render_and_save("enemy_elite", Vector2(160, 160), _draw_enemy_elite)
	_render_and_save("boss_abyssal_dread", Vector2(220, 220), _draw_boss_abyssal_dread)
	
	_render_and_save("pet_wolf", Vector2(96, 96), _draw_pet_wolf)
	_render_and_save("pet_hellhound", Vector2(96, 96), _draw_pet_hellhound)
	
	print("--- All Chibi Sprites Rendered & Saved Successfully! ---")
	get_tree().quit(0)

func draw_ellipse_shape(c: Node2D, pos: Vector2, rx: float, ry: float, col: Color, border_col: Color = Color.TRANSPARENT, border_w: float = 0.0) -> void:
	var pts := PackedVector2Array()
	var segments := 24
	for i in range(segments):
		var a := float(i) * (TAU / float(segments))
		pts.append(pos + Vector2(cos(a) * rx, sin(a) * ry))
	c.draw_colored_polygon(pts, col)
	if border_w > 0.0 and border_col.a > 0.0:
		var line_pts := pts.duplicate()
		line_pts.append(line_pts[0])
		c.draw_polyline(line_pts, border_col, border_w)

func _render_and_save(sprite_name: String, target_size: Vector2, draw_func: Callable) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(int(target_size.x), int(target_size.y))
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	
	var canvas := Node2D.new()
	vp.add_child(canvas)
	canvas.draw.connect(func():
		var center := target_size * 0.5
		draw_func.call(canvas, center)
	)
	canvas.queue_redraw()
	
	# Wait for render pass
	for i in range(3):
		await get_tree().process_frame
		
	var tex := vp.get_texture()
	var img := tex.get_image()
	if img:
		var dir := "res://assets/sprites/characters/"
		if sprite_name.begins_with("enemy_"):
			dir = "res://assets/sprites/enemies/"
		elif sprite_name.begins_with("boss_"):
			dir = "res://assets/sprites/bosses/"
		elif sprite_name.begins_with("pet_"):
			dir = "res://assets/sprites/pets/"
			
		var path := dir + sprite_name + ".png"
		var abs_path := ProjectSettings.globalize_path(path)
		img.save_png(abs_path)
		print("  -> Rendered: ", path)
		
	vp.queue_free()

# ==============================================================================
# 1. SHADOW HUNTER CHIBI
# Dark assassin: 2.2 heads tall, flowing purple cape, leather armor, gold buckle,
# expressive violet eyes with catchlights, dual obsidian curved void daggers.
# ==============================================================================
func _draw_shadow_hunter(c: Node2D, center: Vector2) -> void:
	var aura_col := Color(0.65, 0.2, 0.95, 0.25)
	c.draw_circle(center + Vector2(0, 10), 55.0, aura_col)
	c.draw_circle(center + Vector2(0, 8), 42.0, Color(0.8, 0.25, 1.0, 0.2))
	
	# Flowing Hooded Cape (Layer 1 - Back)
	var cape_pts := PackedVector2Array([
		center + Vector2(-18, -4),
		center + Vector2(18, -4),
		center + Vector2(34, 46),
		center + Vector2(16, 52),
		center + Vector2(0, 48),
		center + Vector2(-16, 52),
		center + Vector2(-34, 46)
	])
	c.draw_colored_polygon(cape_pts, Color(0.08, 0.05, 0.14, 1.0))
	c.draw_polyline(cape_pts + PackedVector2Array([cape_pts[0]]), Color(0.35, 0.18, 0.55, 0.9), 2.2)
	
	# Chunky Chibi Boots (Layer 2)
	var boot_l := PackedVector2Array([
		center + Vector2(-18, 38), center + Vector2(-6, 38),
		center + Vector2(-5, 52), center + Vector2(-20, 52)
	])
	var boot_r := PackedVector2Array([
		center + Vector2(6, 38), center + Vector2(18, 38),
		center + Vector2(20, 52), center + Vector2(5, 52)
	])
	c.draw_colored_polygon(boot_l, Color(0.12, 0.09, 0.18, 1.0))
	c.draw_polyline(boot_l + PackedVector2Array([boot_l[0]]), Color(0.4, 0.25, 0.55, 0.8), 1.5)
	c.draw_colored_polygon(boot_r, Color(0.12, 0.09, 0.18, 1.0))
	c.draw_polyline(boot_r + PackedVector2Array([boot_r[0]]), Color(0.4, 0.25, 0.55, 0.8), 1.5)
	
	# Tunic & Leather Armor Cuirass (Layer 3)
	var body_pts := PackedVector2Array([
		center + Vector2(-16, -2), center + Vector2(16, -2),
		center + Vector2(20, 36), center + Vector2(-20, 36)
	])
	c.draw_colored_polygon(body_pts, Color(0.16, 0.11, 0.24, 1.0))
	c.draw_polyline(body_pts + PackedVector2Array([body_pts[0]]), Color(0.45, 0.25, 0.65, 0.95), 1.8)
	
	# Chest harness & obsidian plate
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-11, 2), center + Vector2(11, 2),
		center + Vector2(13, 22), center + Vector2(-13, 22)
	]), Color(0.24, 0.16, 0.36, 1.0))
	
	# Gold Belt with amethyst gem buckle
	c.draw_rect(Rect2(center + Vector2(-16, 26), Vector2(32, 7)), Color(0.88, 0.72, 0.25, 1.0))
	c.draw_circle(center + Vector2(0, 29.5), 5.0, Color(0.95, 0.25, 0.85, 1.0))
	c.draw_circle(center + Vector2(0, 29.5), 2.5, Color.WHITE)
	
	# Pauldrons (Shoulders)
	c.draw_circle(center + Vector2(-22, 6), 9.0, Color(0.15, 0.1, 0.24, 1.0))
	c.draw_arc(center + Vector2(-22, 6), 9.0, 0.0, TAU, 16, Color(0.85, 0.7, 0.25, 1.0), 2.0)
	c.draw_circle(center + Vector2(22, 6), 9.0, Color(0.15, 0.1, 0.24, 1.0))
	c.draw_arc(center + Vector2(22, 6), 9.0, 0.0, TAU, 16, Color(0.85, 0.7, 0.25, 1.0), 2.0)
	
	# Chibi Head & Assassin Cowl (Layer 4 - Front)
	var head_c := center + Vector2(0, -28)
	c.draw_circle(head_c, 30.0, Color(0.1, 0.06, 0.16, 1.0))
	c.draw_arc(head_c, 30.0, 0.0, TAU, 32, Color(0.42, 0.22, 0.62, 1.0), 2.5)
	c.draw_circle(head_c + Vector2(0, -2), 26.0, Color(0.18, 0.12, 0.28, 1.0))
	
	# Face Oval
	c.draw_circle(head_c + Vector2(0, 3), 20.0, Color(0.98, 0.88, 0.82, 1.0))
	
	# Hair Bangs inside hood
	c.draw_colored_polygon(PackedVector2Array([
		head_c + Vector2(-16, -6), head_c + Vector2(-4, 0),
		head_c + Vector2(0, -6), head_c + Vector2(5, 0),
		head_c + Vector2(16, -6), head_c + Vector2(0, -18)
	]), Color(0.18, 0.12, 0.28, 1.0))
	
	# Cute anime cheeks
	c.draw_circle(head_c + Vector2(-11, 8), 4.5, Color(1.0, 0.55, 0.65, 0.4))
	c.draw_circle(head_c + Vector2(11, 8), 4.5, Color(1.0, 0.55, 0.65, 0.4))
	
	# Large Expressive Eyes (Radiant Violet with catchlights)
	var eye_l := head_c + Vector2(-8, 3)
	var eye_r := head_c + Vector2(8, 3)
	# Lashes / Outline
	draw_ellipse_shape(c, eye_l, 6.5, 8.5, Color(0.12, 0.06, 0.18, 1.0))
	draw_ellipse_shape(c, eye_r, 6.5, 8.5, Color(0.12, 0.06, 0.18, 1.0))
	# Iris
	draw_ellipse_shape(c, eye_l, 5.0, 7.0, Color(0.78, 0.25, 1.0, 1.0))
	draw_ellipse_shape(c, eye_r, 5.0, 7.0, Color(0.78, 0.25, 1.0, 1.0))
	# Pupil
	draw_ellipse_shape(c, eye_l + Vector2(0, 0.5), 3.0, 4.5, Color(0.2, 0.05, 0.35, 1.0))
	draw_ellipse_shape(c, eye_r + Vector2(0, 0.5), 3.0, 4.5, Color(0.2, 0.05, 0.35, 1.0))
	# Catchlights
	c.draw_circle(eye_l + Vector2(-2, -2.5), 2.5, Color.WHITE)
	c.draw_circle(eye_r + Vector2(-2, -2.5), 2.5, Color.WHITE)
	c.draw_circle(eye_l + Vector2(1.8, 2.5), 1.2, Color(1.0, 0.85, 1.0, 0.9))
	c.draw_circle(eye_r + Vector2(1.8, 2.5), 1.2, Color(1.0, 0.85, 1.0, 0.9))
	
	# Confident smile
	c.draw_arc(head_c + Vector2(0, 12), 4.0, 0.2, PI - 0.2, 8, Color(0.5, 0.2, 0.3, 0.9), 1.8)
	
	# Signature Dual Curved Obsidian Void Daggers
	_draw_void_dagger(c, center + Vector2(-34, 18), -0.2)
	_draw_void_dagger(c, center + Vector2(34, 18), 0.2)
	
	# Floating Shadow Flame Spirit Wisp (orbits shoulder)
	var wisp_p := center + Vector2(-36, -38)
	c.draw_circle(wisp_p, 8.0, Color(0.7, 0.25, 1.0, 0.4))
	c.draw_circle(wisp_p, 5.0, Color(0.9, 0.5, 1.0, 0.9))
	c.draw_circle(wisp_p + Vector2(-1, -1), 2.0, Color.WHITE)

func _draw_void_dagger(c: Node2D, pos: Vector2, rot: float) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -26).rotated(rot),
		pos + Vector2(-6, 8).rotated(rot),
		pos + Vector2(0, 22).rotated(rot),
		pos + Vector2(6, 8).rotated(rot)
	])
	c.draw_colored_polygon(pts, Color(0.12, 0.08, 0.2, 1.0))
	c.draw_polyline(pts + PackedVector2Array([pts[0]]), Color(0.95, 0.35, 1.0, 1.0), 2.0)
	# Inner glowing spine
	c.draw_line(pos + Vector2(0, -22).rotated(rot), pos + Vector2(0, 16).rotated(rot), Color(1.0, 0.7, 1.0, 1.0), 1.5)

# ==============================================================================
# 2. STORM REAPER CHIBI
# Heavy storm plate knight: Horned crested helm, glowing electric cyan visor slit,
# storm pauldrons, massive lightning war-scythe with crackling energy.
# ==============================================================================
func _draw_storm_reaper(c: Node2D, center: Vector2) -> void:
	# Electric Cyan Aura
	c.draw_circle(center + Vector2(0, 10), 56.0, Color(0.15, 0.6, 1.0, 0.25))
	c.draw_circle(center + Vector2(0, 8), 44.0, Color(0.3, 0.85, 1.0, 0.22))
	
	# Steel/Obsidian Mantle (Back)
	var cape_pts := PackedVector2Array([
		center + Vector2(-20, -4), center + Vector2(20, -4),
		center + Vector2(36, 48), center + Vector2(-36, 48)
	])
	c.draw_colored_polygon(cape_pts, Color(0.06, 0.09, 0.16, 1.0))
	c.draw_polyline(cape_pts + PackedVector2Array([cape_pts[0]]), Color(0.25, 0.5, 0.8, 0.9), 2.2)
	
	# Heavy Plate Greaves
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-19, 38), center + Vector2(-6, 38),
		center + Vector2(-5, 53), center + Vector2(-21, 53)
	]), Color(0.12, 0.16, 0.26, 1.0))
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(6, 38), center + Vector2(19, 38),
		center + Vector2(21, 53), center + Vector2(5, 53)
	]), Color(0.12, 0.16, 0.26, 1.0))
	
	# Heavy Steel Breastplate
	var body_pts := PackedVector2Array([
		center + Vector2(-18, -2), center + Vector2(18, -2),
		center + Vector2(22, 36), center + Vector2(-22, 36)
	])
	c.draw_colored_polygon(body_pts, Color(0.16, 0.24, 0.38, 1.0))
	c.draw_polyline(body_pts + PackedVector2Array([body_pts[0]]), Color(0.35, 0.65, 0.95, 1.0), 2.0)
	
	# Glowing Lightning Crest on Chest
	c.draw_circle(center + Vector2(0, 16), 6.0, Color(0.2, 0.85, 1.0, 1.0))
	c.draw_circle(center + Vector2(0, 16), 3.0, Color.WHITE)
	
	# Spiked Storm Pauldrons
	c.draw_circle(center + Vector2(-25, 8), 11.0, Color(0.14, 0.2, 0.32, 1.0))
	c.draw_arc(center + Vector2(-25, 8), 11.0, 0.0, TAU, 16, Color(0.35, 0.8, 1.0, 1.0), 2.2)
	c.draw_circle(center + Vector2(25, 8), 11.0, Color(0.14, 0.2, 0.32, 1.0))
	c.draw_arc(center + Vector2(25, 8), 11.0, 0.0, TAU, 16, Color(0.35, 0.8, 1.0, 1.0), 2.2)
	
	# Chibi Battle Helm
	var head_c := center + Vector2(0, -28)
	# Curved Battle Horns
	var horn_l := PackedVector2Array([
		head_c + Vector2(-18, -8), head_c + Vector2(-36, -26),
		head_c + Vector2(-30, -32), head_c + Vector2(-14, -18)
	])
	var horn_r := PackedVector2Array([
		head_c + Vector2(18, -8), head_c + Vector2(36, -26),
		head_c + Vector2(30, -32), head_c + Vector2(14, -18)
	])
	c.draw_colored_polygon(horn_l, Color(0.25, 0.4, 0.6, 1.0))
	c.draw_polyline(horn_l + PackedVector2Array([horn_l[0]]), Color(0.4, 0.85, 1.0, 0.9), 1.8)
	c.draw_colored_polygon(horn_r, Color(0.25, 0.4, 0.6, 1.0))
	c.draw_polyline(horn_r + PackedVector2Array([horn_r[0]]), Color(0.4, 0.85, 1.0, 0.9), 1.8)
	
	# Helm Dome
	c.draw_circle(head_c, 30.0, Color(0.1, 0.15, 0.26, 1.0))
	c.draw_arc(head_c, 30.0, 0.0, TAU, 32, Color(0.35, 0.65, 0.95, 1.0), 2.5)
	c.draw_circle(head_c + Vector2(0, -2), 25.0, Color(0.18, 0.28, 0.44, 1.0))
	
	# Visor Mask Void
	draw_ellipse_shape(c, head_c + Vector2(0, 4), 20.0, 12.0, Color(0.04, 0.06, 0.12, 1.0))
	
	# Glowing Cyan Visor Eye Slit (Expressive Chibi Visor)
	draw_ellipse_shape(c, head_c + Vector2(-8, 4), 6.5, 4.0, Color(0.2, 0.85, 1.0, 1.0))
	draw_ellipse_shape(c, head_c + Vector2(8, 4), 6.5, 4.0, Color(0.2, 0.85, 1.0, 1.0))
	c.draw_circle(head_c + Vector2(-8, 4), 2.5, Color.WHITE)
	c.draw_circle(head_c + Vector2(8, 4), 2.5, Color.WHITE)
	
	# Massive Lightning War-Scythe in Right Hand
	var scy_base := center + Vector2(36, -8)
	c.draw_line(scy_base + Vector2(-4, 45), scy_base + Vector2(4, -40), Color(0.3, 0.25, 0.2, 1.0), 3.5)
	# Scythe Crescent Blade
	var blade_pts := PackedVector2Array([
		scy_base + Vector2(4, -40),
		scy_base + Vector2(-28, -60),
		scy_base + Vector2(-16, -30)
	])
	c.draw_colored_polygon(blade_pts, Color(0.1, 0.3, 0.5, 1.0))
	c.draw_polyline(blade_pts + PackedVector2Array([blade_pts[0]]), Color(0.4, 0.95, 1.0, 1.0), 2.5)
	c.draw_line(scy_base + Vector2(2, -38), scy_base + Vector2(-24, -56), Color.WHITE, 1.5)
	
	# Floating Electric Spark Companion
	var spark_p := center + Vector2(-36, -38)
	c.draw_circle(spark_p, 8.0, Color(0.2, 0.8, 1.0, 0.4))
	c.draw_circle(spark_p, 5.0, Color(0.5, 0.95, 1.0, 0.9))
	c.draw_circle(spark_p + Vector2(-1, -1), 2.0, Color.WHITE)

# ==============================================================================
# 3. SOUL BINDER CHIBI
# Occult necromancer: Horned bone skull mask, radiant emerald wisp eye sockets,
# occult cowl with glyphs, skull lantern focus staff, floating soul companion.
# ==============================================================================
func _draw_soul_binder(c: Node2D, center: Vector2) -> void:
	# Ethereal Emerald Soul Aura
	c.draw_circle(center + Vector2(0, 10), 56.0, Color(0.1, 0.85, 0.5, 0.25))
	c.draw_circle(center + Vector2(0, 8), 44.0, Color(0.25, 1.0, 0.65, 0.22))
	
	# Occult Flowing Robes
	var robe_pts := PackedVector2Array([
		center + Vector2(-20, -4), center + Vector2(20, -4),
		center + Vector2(36, 48), center + Vector2(-36, 48)
	])
	c.draw_colored_polygon(robe_pts, Color(0.04, 0.12, 0.08, 1.0))
	c.draw_polyline(robe_pts + PackedVector2Array([robe_pts[0]]), Color(0.2, 0.6, 0.4, 0.9), 2.2)
	
	# Body Vestments & Talismans
	var body_pts := PackedVector2Array([
		center + Vector2(-18, -2), center + Vector2(18, -2),
		center + Vector2(22, 36), center + Vector2(-22, 36)
	])
	c.draw_colored_polygon(body_pts, Color(0.08, 0.22, 0.16, 1.0))
	c.draw_polyline(body_pts + PackedVector2Array([body_pts[0]]), Color(0.3, 0.85, 0.6, 1.0), 1.8)
	
	# Talisman Belt with glowing soul core
	c.draw_circle(center + Vector2(0, 26), 6.0, Color(0.2, 0.95, 0.65, 1.0))
	c.draw_circle(center + Vector2(0, 26), 3.0, Color.WHITE)
	
	# Orbiting Soul Orbs
	c.draw_circle(center + Vector2(-28, 12), 8.0, Color(0.2, 0.95, 0.65, 0.85))
	c.draw_circle(center + Vector2(-28, 12), 4.0, Color.WHITE)
	c.draw_circle(center + Vector2(28, 12), 8.0, Color(0.2, 0.95, 0.65, 0.85))
	c.draw_circle(center + Vector2(28, 12), 4.0, Color.WHITE)
	
	# Chibi Occult Cowl
	var head_c := center + Vector2(0, -28)
	c.draw_circle(head_c, 30.0, Color(0.06, 0.15, 0.1, 1.0))
	c.draw_arc(head_c, 30.0, 0.0, TAU, 32, Color(0.25, 0.75, 0.5, 1.0), 2.5)
	c.draw_circle(head_c + Vector2(0, -2), 26.0, Color(0.12, 0.28, 0.2, 1.0))
	
	# Horned Ceremonial Bone Mask
	c.draw_circle(head_c + Vector2(0, 4), 21.0, Color(0.92, 0.92, 0.85, 1.0))
	c.draw_arc(head_c + Vector2(0, 4), 21.0, 0.0, TAU, 24, Color(0.3, 0.35, 0.3, 0.8), 1.5)
	# Bone Horns
	draw_ellipse_shape(c, head_c + Vector2(-16, -10), 5.0, 12.0, Color(0.85, 0.85, 0.78, 1.0))
	draw_ellipse_shape(c, head_c + Vector2(16, -10), 5.0, 12.0, Color(0.85, 0.85, 0.78, 1.0))
	
	# Radiant Emerald Eye Sockets (Expressive)
	var eye_l := head_c + Vector2(-7.5, 3)
	var eye_r := head_c + Vector2(7.5, 3)
	c.draw_circle(eye_l, 6.5, Color(0.05, 0.15, 0.1, 1.0))
	c.draw_circle(eye_r, 6.5, Color(0.05, 0.15, 0.1, 1.0))
	c.draw_circle(eye_l, 4.8, Color(0.15, 0.95, 0.6, 1.0))
	c.draw_circle(eye_r, 4.8, Color(0.15, 0.95, 0.6, 1.0))
	c.draw_circle(eye_l + Vector2(-1.5, -1.5), 2.0, Color.WHITE)
	c.draw_circle(eye_r + Vector2(-1.5, -1.5), 2.0, Color.WHITE)
	
	# Skull Nose & Teeth
	draw_ellipse_shape(c, head_c + Vector2(0, 10), 2.5, 3.5, Color(0.1, 0.15, 0.12, 0.8))
	draw_ellipse_shape(c, head_c + Vector2(0, 16), 8.0, 2.5, Color(0.15, 0.2, 0.16, 0.7))
	
	# Spectral Skull Lantern Staff
	var stf_base := center + Vector2(36, -4)
	c.draw_line(stf_base + Vector2(0, 48), stf_base + Vector2(0, -35), Color(0.3, 0.2, 0.15, 1.0), 3.5)
	c.draw_circle(stf_base + Vector2(0, -35), 11.0, Color(0.15, 0.95, 0.65, 0.9))
	c.draw_circle(stf_base + Vector2(0, -35), 5.0, Color.WHITE)
	
	# Floating Soul Companion Wisp
	var comp_p := center + Vector2(-36, -38)
	c.draw_circle(comp_p, 8.0, Color(0.15, 0.95, 0.65, 0.4))
	c.draw_circle(comp_p, 5.0, Color(0.35, 1.0, 0.75, 0.9))
	c.draw_circle(comp_p + Vector2(-1, -1), 2.0, Color.WHITE)

# ==============================================================================
# 4. ENEMY SWARMER (96x96)
# ==============================================================================
func _draw_enemy_swarmer(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 44.0, Color(0.9, 0.15, 0.25, 0.2))
	# Spiky Chitinous Body
	draw_ellipse_shape(c, center + Vector2(0, 4), 32.0, 24.0, Color(0.2, 0.04, 0.08, 1.0), Color(0.85, 0.18, 0.28, 1.0), 2.2)
	draw_ellipse_shape(c, center + Vector2(0, 2), 24.0, 18.0, Color(0.65, 0.1, 0.18, 1.0))
	# Mandibles / Claws
	draw_ellipse_shape(c, center + Vector2(-14, 20), 6.0, 12.0, Color(0.95, 0.9, 0.75, 1.0))
	draw_ellipse_shape(c, center + Vector2(14, 20), 6.0, 12.0, Color(0.95, 0.9, 0.75, 1.0))
	# Fiery Amber Eyes
	c.draw_circle(center + Vector2(-9, 2), 5.0, Color(1.0, 0.85, 0.1, 1.0))
	c.draw_circle(center + Vector2(9, 2), 5.0, Color(1.0, 0.85, 0.1, 1.0))
	c.draw_circle(center + Vector2(-9, 2), 2.0, Color.WHITE)
	c.draw_circle(center + Vector2(9, 2), 2.0, Color.WHITE)

# ==============================================================================
# 5. ENEMY CULTIST (96x96)
# ==============================================================================
func _draw_enemy_cultist(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 44.0, Color(0.6, 0.15, 0.85, 0.2))
	# Robes
	draw_ellipse_shape(c, center + Vector2(0, 12), 30.0, 32.0, Color(0.12, 0.05, 0.2, 1.0), Color(0.5, 0.2, 0.8, 1.0), 2.0)
	# Pointed Hood
	var hood_pts := PackedVector2Array([
		center + Vector2(-18, -4), center + Vector2(18, -4),
		center + Vector2(0, -38)
	])
	c.draw_colored_polygon(hood_pts, Color(0.18, 0.08, 0.3, 1.0))
	c.draw_polyline(hood_pts + PackedVector2Array([hood_pts[0]]), Color(0.65, 0.25, 0.95, 1.0), 2.0)
	# Cyclopean Eye
	c.draw_circle(center + Vector2(0, -10), 9.0, Color(0.95, 0.2, 0.85, 1.0))
	c.draw_circle(center + Vector2(0, -10), 4.0, Color.WHITE)
	# Casting Orb
	c.draw_circle(center + Vector2(0, 16), 11.0, Color(0.85, 0.12, 0.45, 0.9))
	c.draw_circle(center + Vector2(0, 16), 5.0, Color.WHITE)

# ==============================================================================
# 6. ENEMY ELITE (160x160)
# ==============================================================================
func _draw_enemy_elite(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 64.0, Color(1.0, 0.4, 0.05, 0.25))
	# Basalt Torso
	draw_ellipse_shape(c, center + Vector2(0, 12), 48.0, 42.0, Color(0.1, 0.08, 0.12, 1.0), Color(1.0, 0.45, 0.05, 1.0), 2.5)
	# Basalt Spiked Shoulders
	c.draw_circle(center + Vector2(-36, -6), 20.0, Color(0.15, 0.12, 0.18, 1.0))
	c.draw_arc(center + Vector2(-36, -6), 20.0, 0.0, TAU, 16, Color(1.0, 0.5, 0.05, 1.0), 2.2)
	c.draw_circle(center + Vector2(36, -6), 20.0, Color(0.15, 0.12, 0.18, 1.0))
	c.draw_arc(center + Vector2(36, -6), 20.0, 0.0, TAU, 16, Color(1.0, 0.5, 0.05, 1.0), 2.2)
	# Molten Lava Core
	c.draw_circle(center + Vector2(0, 10), 18.0, Color(1.0, 0.35, 0.02, 1.0))
	c.draw_circle(center + Vector2(0, 10), 9.0, Color(1.0, 0.9, 0.4, 1.0))
	# Fiery Eyes
	draw_ellipse_shape(c, center + Vector2(-10, -24), 5.0, 3.0, Color(1.0, 0.9, 0.2, 1.0))
	draw_ellipse_shape(c, center + Vector2(10, -24), 5.0, 3.0, Color(1.0, 0.9, 0.2, 1.0))

# ==============================================================================
# 7. BOSS LORD MALAKAR (220x220)
# ==============================================================================
func _draw_boss_abyssal_dread(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 95.0, Color(0.65, 0.1, 0.9, 0.22))
	# Mantle & Wings
	draw_ellipse_shape(c, center + Vector2(0, 18), 74.0, 68.0, Color(0.06, 0.03, 0.09, 1.0), Color(0.85, 0.2, 0.4, 1.0), 3.0)
	# Dread Horns
	var horn_l := PackedVector2Array([
		center + Vector2(-25, -20), center + Vector2(-55, -65),
		center + Vector2(-40, -75), center + Vector2(-15, -30)
	])
	var horn_r := PackedVector2Array([
		center + Vector2(25, -20), center + Vector2(55, -65),
		center + Vector2(40, -75), center + Vector2(15, -30)
	])
	c.draw_colored_polygon(horn_l, Color(0.12, 0.05, 0.18, 1.0))
	c.draw_polyline(horn_l + PackedVector2Array([horn_l[0]]), Color(0.9, 0.2, 0.45, 1.0), 2.2)
	c.draw_colored_polygon(horn_r, Color(0.12, 0.05, 0.18, 1.0))
	c.draw_polyline(horn_r + PackedVector2Array([horn_r[0]]), Color(0.9, 0.2, 0.45, 1.0), 2.2)
	# Dread Core Eye
	c.draw_circle(center + Vector2(0, 8), 26.0, Color(0.95, 0.08, 0.25, 1.0))
	c.draw_circle(center + Vector2(0, 8), 14.0, Color(1.0, 0.85, 0.2, 1.0))
	c.draw_circle(center + Vector2(0, 8), 6.0, Color.WHITE)
	# Archon Eyes
	c.draw_circle(center + Vector2(-11, -28), 6.0, Color(1.0, 0.2, 0.4, 1.0))
	c.draw_circle(center + Vector2(11, -28), 6.0, Color(1.0, 0.2, 0.4, 1.0))
	c.draw_circle(center + Vector2(-11, -28), 2.5, Color.WHITE)
	c.draw_circle(center + Vector2(11, -28), 2.5, Color.WHITE)

# ==============================================================================
# 8. PETS (Wolf & Hellhound)
# ==============================================================================
func _draw_pet_wolf(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 36.0, Color(0.3, 0.75, 1.0, 0.25))
	draw_ellipse_shape(c, center + Vector2(0, 6), 24.0, 18.0, Color(0.15, 0.25, 0.4, 1.0))
	# Ears
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-14, -6), center + Vector2(-8, -24), center + Vector2(-2, -8)
	]), Color(0.2, 0.35, 0.55, 1.0))
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(2, -8), center + Vector2(8, -24), center + Vector2(14, -6)
	]), Color(0.2, 0.35, 0.55, 1.0))
	# Head
	c.draw_circle(center + Vector2(0, -6), 16.0, Color(0.25, 0.4, 0.6, 1.0))
	# Glowing Cyan Eyes
	c.draw_circle(center + Vector2(-6, -6), 3.5, Color(0.3, 0.9, 1.0, 1.0))
	c.draw_circle(center + Vector2(6, -6), 3.5, Color(0.3, 0.9, 1.0, 1.0))
	c.draw_circle(center + Vector2(-6, -6), 1.5, Color.WHITE)
	c.draw_circle(center + Vector2(6, -6), 1.5, Color.WHITE)

func _draw_pet_hellhound(c: Node2D, center: Vector2) -> void:
	c.draw_circle(center, 38.0, Color(1.0, 0.4, 0.1, 0.3))
	draw_ellipse_shape(c, center + Vector2(0, 6), 25.0, 19.0, Color(0.25, 0.08, 0.05, 1.0))
	# Fiery Ears / Horns
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(-14, -6), center + Vector2(-8, -26), center + Vector2(-2, -8)
	]), Color(0.85, 0.25, 0.05, 1.0))
	c.draw_colored_polygon(PackedVector2Array([
		center + Vector2(2, -8), center + Vector2(8, -26), center + Vector2(14, -6)
	]), Color(0.85, 0.25, 0.05, 1.0))
	# Head
	c.draw_circle(center + Vector2(0, -6), 17.0, Color(0.45, 0.12, 0.06, 1.0))
	# Glowing Molten Amber Eyes
	c.draw_circle(center + Vector2(-6, -6), 4.0, Color(1.0, 0.85, 0.15, 1.0))
	c.draw_circle(center + Vector2(6, -6), 4.0, Color(1.0, 0.85, 0.15, 1.0))
	c.draw_circle(center + Vector2(-6, -6), 1.8, Color.WHITE)
	c.draw_circle(center + Vector2(6, -6), 1.8, Color.WHITE)
