@tool
extends SceneTree

# Generates high-fidelity stylized 2D dark-fantasy chibi character sprites,
# enemies, bosses, VFX, and projectiles for Abyssal Altar Phase 3.

func _init() -> void:
	print("--- Generating Phase 3 Stylized 2D Chibi & Combat Art ---")
	_gen_ground_shadow()
	_gen_shadow_hunter_chibi()
	_gen_storm_reaper_chibi()
	_gen_soul_binder_chibi()
	_gen_enemy_sprites()
	_gen_boss_sprite()
	_gen_combat_vfx()
	print("--- Phase 3 Art Generated Successfully! ---")
	quit(0)

# Helper: Anti-aliased filled ellipse with border and gradient
func _draw_smooth_ellipse(img: Image, center: Vector2, rx: float, ry: float, col: Color, border_col: Color = Color(0,0,0,0), border_w: float = 0.0) -> void:
	var min_x := int(max(0, floor(center.x - rx - border_w - 2.0)))
	var max_x := int(min(img.get_width() - 1, ceil(center.x + rx + border_w + 2.0)))
	var min_y := int(max(0, floor(center.y - ry - border_w - 2.0)))
	var max_y := int(min(img.get_height() - 1, ceil(center.y + ry + border_w + 2.0)))
	
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var dx: float = (float(x) - center.x) / rx
			var dy: float = (float(y) - center.y) / ry
			var dist: float = sqrt(dx * dx + dy * dy)
			
			if border_w > 0.0 and border_col.a > 0.0:
				var outer_r: float = 1.0 + (border_w / min(rx, ry))
				if dist <= outer_r:
					var alpha: float = 1.0
					if dist > 1.0:
						alpha = 1.0 - smoothstep(1.0, outer_r, dist)
						var curr := img.get_pixel(x, y)
						img.set_pixel(x, y, curr.blend(Color(border_col.r, border_col.g, border_col.b, border_col.a * alpha)))
					else:
						var edge_a := 1.0 - smoothstep(0.85, 1.0, dist)
						var curr := img.get_pixel(x, y)
						var blended := col.blend(Color(border_col.r, border_col.g, border_col.b, border_col.a * (1.0 - edge_a)))
						img.set_pixel(x, y, curr.blend(blended))
			else:
				if dist <= 1.0:
					var alpha: float = 1.0 - smoothstep(0.85, 1.0, dist)
					var curr := img.get_pixel(x, y)
					img.set_pixel(x, y, curr.blend(Color(col.r, col.g, col.b, col.a * alpha)))

func _draw_smooth_circle(img: Image, center: Vector2, radius: float, col: Color, border_col: Color = Color(0,0,0,0), border_w: float = 0.0) -> void:
	_draw_smooth_ellipse(img, center, radius, radius, col, border_col, border_w)

# 1. Ground Contact Shadow (Soft realistic Archero 2 oval shadow)
func _gen_ground_shadow() -> void:
	var img := Image.create(96, 48, false, Image.FORMAT_RGBA8)
	var c := Vector2(48, 24)
	# Multi-layered gradient for soft diffuse edge
	_draw_smooth_ellipse(img, c, 44, 18, Color(0.01, 0.01, 0.03, 0.4))
	_draw_smooth_ellipse(img, c, 34, 13, Color(0.01, 0.01, 0.02, 0.65))
	_draw_smooth_ellipse(img, c, 22, 8, Color(0.0, 0.0, 0.0, 0.88))
	img.save_png("res://assets/sprites/vfx/ground_shadow.png")

# 2. Shadow Hunter Chibi (128x128)
# Distinctive assassin silhouette: 2.2 heads tall, large expressive purple eyes with sharp catchlights,
# dark cowl/hood with silver trims, leather tunic with gold buckle, flowing hooded cape, dual glowing daggers.
func _gen_shadow_hunter_chibi() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var c := Vector2(64, 64)
	
	# Atmospheric shadow aura
	_draw_smooth_ellipse(img, c + Vector2(0, 10), 48, 52, Color(0.6, 0.15, 0.95, 0.18))
	_draw_smooth_ellipse(img, c + Vector2(0, 8), 38, 42, Color(0.75, 0.2, 0.95, 0.28))
	
	# Flowing Dark Cloak / Cape (Back layer)
	_draw_smooth_ellipse(img, c + Vector2(0, 24), 30, 32, Color(0.06, 0.04, 0.1, 1.0), Color(0.2, 0.12, 0.32, 0.8), 2.0)
	_draw_smooth_ellipse(img, c + Vector2(0, 20), 25, 28, Color(0.12, 0.08, 0.2, 1.0))
	
	# Boots / Legs (Chunky chibi feet)
	_draw_smooth_ellipse(img, c + Vector2(-12, 42), 9, 7, Color(0.08, 0.06, 0.12, 1.0), Color(0.35, 0.25, 0.45, 0.9), 1.5)
	_draw_smooth_ellipse(img, c + Vector2(12, 42), 9, 7, Color(0.08, 0.06, 0.12, 1.0), Color(0.35, 0.25, 0.45, 0.9), 1.5)
	
	# Assassin Tunic & Leather Armor
	_draw_smooth_ellipse(img, c + Vector2(0, 18), 20, 20, Color(0.18, 0.12, 0.28, 1.0), Color(0.4, 0.22, 0.55, 1.0), 1.8)
	_draw_smooth_ellipse(img, c + Vector2(0, 14), 16, 15, Color(0.28, 0.18, 0.42, 1.0))
	
	# Gold Belt with amethyst void gem
	_draw_smooth_ellipse(img, c + Vector2(0, 24), 15, 4, Color(0.9, 0.75, 0.25, 1.0))
	_draw_smooth_circle(img, c + Vector2(0, 24), 4.0, Color(0.95, 0.25, 0.85, 1.0), Color(1.0, 0.9, 0.4, 1.0), 1.0)
	
	# Pauldrons (Shoulders)
	_draw_smooth_circle(img, c + Vector2(-18, 10), 8.0, Color(0.15, 0.1, 0.24, 1.0), Color(0.85, 0.7, 0.25, 0.9), 1.5)
	_draw_smooth_circle(img, c + Vector2(18, 10), 8.0, Color(0.15, 0.1, 0.24, 1.0), Color(0.85, 0.7, 0.25, 0.9), 1.5)
	
	# Chibi Head & Cowl (Large head for chibi 2.2-heads proportion)
	var head_c := c + Vector2(0, -18)
	# Cowl Outer
	_draw_smooth_circle(img, head_c, 28.0, Color(0.09, 0.06, 0.15, 1.0), Color(0.38, 0.22, 0.55, 1.0), 2.2)
	_draw_smooth_circle(img, head_c + Vector2(0, -2), 24.0, Color(0.16, 0.1, 0.26, 1.0))
	
	# Face Oval
	_draw_smooth_ellipse(img, head_c + Vector2(0, 4), 18, 16, Color(0.98, 0.88, 0.82, 1.0))
	# Subtle anime blush
	_draw_smooth_ellipse(img, head_c + Vector2(-10, 8), 5, 2.5, Color(1.0, 0.6, 0.65, 0.35))
	_draw_smooth_ellipse(img, head_c + Vector2(10, 8), 5, 2.5, Color(1.0, 0.6, 0.65, 0.35))
	
	# Cute bangs peeking from cowl
	_draw_smooth_ellipse(img, head_c + Vector2(-6, -6), 9, 6, Color(0.18, 0.12, 0.28, 1.0))
	_draw_smooth_ellipse(img, head_c + Vector2(6, -6), 9, 6, Color(0.18, 0.12, 0.28, 1.0))
	
	# Large Expressive Eyes (Radiant violet with white catchlights)
	var eye_l := head_c + Vector2(-7, 3)
	var eye_r := head_c + Vector2(7, 3)
	# Eye sockets / lashes
	_draw_smooth_ellipse(img, eye_l, 6.0, 7.5, Color(0.12, 0.08, 0.18, 1.0))
	_draw_smooth_ellipse(img, eye_r, 6.0, 7.5, Color(0.12, 0.08, 0.18, 1.0))
	# Glowing violet iris
	_draw_smooth_ellipse(img, eye_l, 4.5, 6.0, Color(0.75, 0.25, 1.0, 1.0))
	_draw_smooth_ellipse(img, eye_r, 4.5, 6.0, Color(0.75, 0.25, 1.0, 1.0))
	# Deep pupil
	_draw_smooth_ellipse(img, eye_l + Vector2(0, 0.5), 2.5, 3.8, Color(0.2, 0.05, 0.35, 1.0))
	_draw_smooth_ellipse(img, eye_r + Vector2(0, 0.5), 2.5, 3.8, Color(0.2, 0.05, 0.35, 1.0))
	# Catchlights (Top-left specular)
	_draw_smooth_circle(img, eye_l + Vector2(-1.8, -1.8), 2.0, Color.WHITE)
	_draw_smooth_circle(img, eye_r + Vector2(-1.8, -1.8), 2.0, Color.WHITE)
	_draw_smooth_circle(img, eye_l + Vector2(1.5, 2.0), 1.0, Color(1.0, 0.85, 1.0, 0.85))
	_draw_smooth_circle(img, eye_r + Vector2(1.5, 2.0), 1.0, Color(1.0, 0.85, 1.0, 0.85))
	
	# Cute confident smile
	_draw_smooth_ellipse(img, head_c + Vector2(0, 13), 3.5, 1.2, Color(0.45, 0.15, 0.25, 0.85))
	
	# Dual Curved Obsidian Daggers (held at ready angles)
	# Left Dagger
	var d1 := c + Vector2(-28, 22)
	_draw_smooth_ellipse(img, d1, 4.5, 16.0, Color(0.1, 0.06, 0.18, 1.0), Color(0.95, 0.35, 1.0, 0.95), 1.8)
	_draw_smooth_ellipse(img, d1, 2.0, 12.0, Color(0.9, 0.65, 1.0, 1.0))
	# Right Dagger
	var d2 := c + Vector2(28, 22)
	_draw_smooth_ellipse(img, d2, 4.5, 16.0, Color(0.1, 0.06, 0.18, 1.0), Color(0.95, 0.35, 1.0, 0.95), 1.8)
	_draw_smooth_ellipse(img, d2, 2.0, 12.0, Color(0.9, 0.65, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_shadow_hunter.png")
	img.save_png("res://assets/sprites/characters/player_base.png")

# 3. Storm Reaper Chibi (128x128)
# Heavy storm-themed plate knight: crested storm helm with curved horns, glowing electric-blue visor slit,
# spiked steel pauldrons, lightning war-scythe with crackling blue edge, electric aura.
func _gen_storm_reaper_chibi() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var c := Vector2(64, 64)
	
	# Electric Cyan Aura
	_draw_smooth_ellipse(img, c + Vector2(0, 10), 50, 54, Color(0.15, 0.6, 1.0, 0.2))
	_draw_smooth_ellipse(img, c + Vector2(0, 8), 40, 44, Color(0.3, 0.85, 1.0, 0.28))
	
	# Heavy Plate Mantle (Back layer)
	_draw_smooth_ellipse(img, c + Vector2(0, 24), 32, 34, Color(0.06, 0.09, 0.15, 1.0), Color(0.25, 0.45, 0.7, 0.85), 2.0)
	
	# Armored Greaves / Boots
	_draw_smooth_ellipse(img, c + Vector2(-13, 42), 10, 8, Color(0.12, 0.16, 0.24, 1.0), Color(0.4, 0.7, 0.95, 0.9), 1.8)
	_draw_smooth_ellipse(img, c + Vector2(13, 42), 10, 8, Color(0.12, 0.16, 0.24, 1.0), Color(0.4, 0.7, 0.95, 0.9), 1.8)
	
	# Steel Breastplate & Lightning Runes
	_draw_smooth_ellipse(img, c + Vector2(0, 18), 22, 20, Color(0.16, 0.24, 0.36, 1.0), Color(0.35, 0.6, 0.88, 1.0), 2.0)
	_draw_smooth_ellipse(img, c + Vector2(0, 14), 16, 14, Color(0.28, 0.4, 0.58, 1.0))
	_draw_smooth_circle(img, c + Vector2(0, 18), 5.0, Color(0.2, 0.85, 1.0, 1.0), Color(0.8, 0.95, 1.0, 1.0), 1.0)
	
	# Spiked Storm Pauldrons
	_draw_smooth_circle(img, c + Vector2(-22, 10), 10.0, Color(0.15, 0.22, 0.35, 1.0), Color(0.35, 0.75, 1.0, 0.95), 2.0)
	_draw_smooth_circle(img, c + Vector2(22, 10), 10.0, Color(0.15, 0.22, 0.35, 1.0), Color(0.35, 0.75, 1.0, 0.95), 2.0)
	_draw_smooth_circle(img, c + Vector2(-22, 10), 5.0, Color(0.3, 0.85, 1.0, 1.0))
	_draw_smooth_circle(img, c + Vector2(22, 10), 5.0, Color(0.3, 0.85, 1.0, 1.0))
	
	# Chibi Horned Battle Helm
	var head_c := c + Vector2(0, -18)
	# Curved Horns
	_draw_smooth_ellipse(img, head_c + Vector2(-22, -14), 7, 16, Color(0.2, 0.35, 0.5, 1.0), Color(0.45, 0.8, 1.0, 0.9), 1.8)
	_draw_smooth_ellipse(img, head_c + Vector2(22, -14), 7, 16, Color(0.2, 0.35, 0.5, 1.0), Color(0.45, 0.8, 1.0, 0.9), 1.8)
	
	# Helm Dome
	_draw_smooth_circle(img, head_c, 27.0, Color(0.1, 0.15, 0.25, 1.0), Color(0.35, 0.6, 0.88, 1.0), 2.2)
	_draw_smooth_circle(img, head_c + Vector2(0, -2), 23.0, Color(0.18, 0.28, 0.42, 1.0))
	
	# Visor Mask Void
	_draw_smooth_ellipse(img, head_c + Vector2(0, 3), 17, 10, Color(0.04, 0.06, 0.12, 1.0))
	# Crackling Visor Slit (Expressive cyan eyes glow)
	_draw_smooth_ellipse(img, head_c + Vector2(-7, 3), 5.5, 3.5, Color(0.2, 0.85, 1.0, 1.0))
	_draw_smooth_ellipse(img, head_c + Vector2(7, 3), 5.5, 3.5, Color(0.2, 0.85, 1.0, 1.0))
	_draw_smooth_circle(img, head_c + Vector2(-7, 3), 2.0, Color.WHITE)
	_draw_smooth_circle(img, head_c + Vector2(7, 3), 2.0, Color.WHITE)
	
	# Massive Lightning War-Scythe (carried at side)
	var scy := c + Vector2(34, -4)
	# Curved blade arc
	_draw_smooth_ellipse(img, scy, 7, 28, Color(0.1, 0.25, 0.45, 1.0), Color(0.35, 0.9, 1.0, 1.0), 2.0)
	_draw_smooth_ellipse(img, scy, 3, 20, Color(0.85, 0.98, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_storm_reaper.png")

# 4. Soul Binder Chibi (128x128)
# Occult summoner: horned bone skull mask, radiant emerald eye sockets, occult cowl with glyphs,
# skull lantern focus staff, floating ethereal soul companion.
func _gen_soul_binder_chibi() -> void:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var c := Vector2(64, 64)
	
	# Ethereal Emerald Soul Aura
	_draw_smooth_ellipse(img, c + Vector2(0, 10), 50, 54, Color(0.1, 0.85, 0.5, 0.2))
	_draw_smooth_ellipse(img, c + Vector2(0, 8), 40, 44, Color(0.25, 1.0, 0.65, 0.28))
	
	# Flowing Ritual Robes (Back layer)
	_draw_smooth_ellipse(img, c + Vector2(0, 24), 32, 34, Color(0.04, 0.1, 0.08, 1.0), Color(0.18, 0.5, 0.35, 0.85), 2.0)
	_draw_smooth_ellipse(img, c + Vector2(0, 20), 26, 30, Color(0.08, 0.22, 0.16, 1.0))
	
	# Occult Vestments & Talisman Embroideries
	_draw_smooth_ellipse(img, c + Vector2(0, 18), 20, 20, Color(0.12, 0.28, 0.22, 1.0), Color(0.35, 0.85, 0.6, 1.0), 1.8)
	_draw_smooth_circle(img, c + Vector2(0, 24), 5.0, Color(0.2, 0.95, 0.65, 1.0), Color(0.85, 1.0, 0.9, 1.0), 1.0)
	
	# Orbiting Soul Orbs
	_draw_smooth_circle(img, c + Vector2(-26, 12), 7.0, Color(0.15, 0.95, 0.65, 0.85), Color(1.0, 1.0, 1.0, 0.9), 1.5)
	_draw_smooth_circle(img, c + Vector2(26, 12), 7.0, Color(0.15, 0.95, 0.65, 0.85), Color(1.0, 1.0, 1.0, 0.9), 1.5)
	
	# Chibi Head & Occult Cowl
	var head_c := c + Vector2(0, -18)
	_draw_smooth_circle(img, head_c, 27.0, Color(0.06, 0.14, 0.1, 1.0), Color(0.2, 0.65, 0.45, 1.0), 2.2)
	_draw_smooth_circle(img, head_c + Vector2(0, -2), 23.0, Color(0.1, 0.24, 0.18, 1.0))
	
	# Horned Ceremonial Bone Mask
	_draw_smooth_ellipse(img, head_c + Vector2(0, 4), 18, 15, Color(0.92, 0.92, 0.85, 1.0), Color(0.3, 0.35, 0.3, 0.8), 1.5)
	_draw_smooth_ellipse(img, head_c + Vector2(-14, -8), 4, 10, Color(0.85, 0.85, 0.78, 1.0)) # Horns
	_draw_smooth_ellipse(img, head_c + Vector2(14, -8), 4, 10, Color(0.85, 0.85, 0.78, 1.0))
	
	# Glowing Emerald Eye Sockets
	var eye_l := head_c + Vector2(-6.5, 3)
	var eye_r := head_c + Vector2(6.5, 3)
	_draw_smooth_circle(img, eye_l, 5.5, Color(0.05, 0.15, 0.1, 1.0))
	_draw_smooth_circle(img, eye_r, 5.5, Color(0.05, 0.15, 0.1, 1.0))
	_draw_smooth_circle(img, eye_l, 4.0, Color(0.15, 0.95, 0.6, 1.0))
	_draw_smooth_circle(img, eye_r, 4.0, Color(0.15, 0.95, 0.6, 1.0))
	_draw_smooth_circle(img, eye_l + Vector2(-1.2, -1.2), 1.8, Color.WHITE)
	_draw_smooth_circle(img, eye_r + Vector2(-1.2, -1.2), 1.8, Color.WHITE)
	
	# Skull Nose & Teeth
	_draw_smooth_ellipse(img, head_c + Vector2(0, 9), 2.0, 3.0, Color(0.1, 0.1, 0.1, 0.8))
	_draw_smooth_ellipse(img, head_c + Vector2(0, 14), 7.0, 2.0, Color(0.15, 0.15, 0.15, 0.7))
	
	# Spectral Skull Lantern Focus Staff
	var stf := c + Vector2(34, 4)
	_draw_smooth_ellipse(img, stf + Vector2(0, 10), 3.5, 24.0, Color(0.25, 0.18, 0.12, 1.0)) # Wood staff
	_draw_smooth_circle(img, stf + Vector2(0, -18), 10.0, Color(0.1, 0.95, 0.65, 0.9), Color(1.0, 1.0, 1.0, 1.0), 1.5)
	
	img.save_png("res://assets/sprites/characters/player_soul_binder.png")

# 5. Enemies (Swarmer, Cultist, Elite)
func _gen_enemy_sprites() -> void:
	# A. Swarmer (96x96): Fiery crimson void prowler with glowing eyes and razor claws
	var sw := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var sc := Vector2(48, 48)
	_draw_smooth_ellipse(sw, sc + Vector2(0, 4), 36, 28, Color(0.95, 0.15, 0.25, 0.2))
	_draw_smooth_ellipse(sw, sc + Vector2(0, 4), 28, 22, Color(0.22, 0.04, 0.08, 1.0), Color(0.85, 0.15, 0.25, 0.95), 2.0)
	_draw_smooth_ellipse(sw, sc + Vector2(0, 2), 22, 16, Color(0.65, 0.1, 0.18, 1.0))
	# Spine ridges & Horns
	_draw_smooth_ellipse(sw, sc + Vector2(-16, -16), 5, 12, Color(0.85, 0.2, 0.28, 1.0))
	_draw_smooth_ellipse(sw, sc + Vector2(16, -16), 5, 12, Color(0.85, 0.2, 0.28, 1.0))
	_draw_smooth_circle(sw, sc + Vector2(0, -8), 10.0, Color(0.9, 0.18, 0.25, 1.0))
	# Mandibles
	_draw_smooth_ellipse(sw, sc + Vector2(-12, 18), 5, 10, Color(0.95, 0.9, 0.75, 1.0))
	_draw_smooth_ellipse(sw, sc + Vector2(12, 18), 5, 10, Color(0.95, 0.9, 0.75, 1.0))
	# Piercing Amber Eyes
	_draw_smooth_circle(sw, sc + Vector2(-8, 2), 4.5, Color(1.0, 0.85, 0.1, 1.0))
	_draw_smooth_circle(sw, sc + Vector2(8, 2), 4.5, Color(1.0, 0.85, 0.1, 1.0))
	_draw_smooth_circle(sw, sc + Vector2(-8, 2), 2.0, Color.WHITE)
	_draw_smooth_circle(sw, sc + Vector2(8, 2), 2.0, Color.WHITE)
	sw.save_png("res://assets/sprites/enemies/enemy_swarmer.png")

	# B. Cultist (96x96): Levitating shadow priest with pointed mitre hood, all-seeing void eye
	var cu := Image.create(96, 96, false, Image.FORMAT_RGBA8)
	var cc := Vector2(48, 48)
	_draw_smooth_ellipse(cu, cc + Vector2(0, 10), 38, 38, Color(0.6, 0.15, 0.85, 0.2))
	_draw_smooth_ellipse(cu, cc + Vector2(0, 14), 28, 30, Color(0.12, 0.05, 0.2, 1.0), Color(0.45, 0.18, 0.7, 0.9), 2.0)
	_draw_smooth_ellipse(cu, cc + Vector2(0, 8), 22, 24, Color(0.35, 0.12, 0.55, 1.0))
	# Tall Pointed Occult Hood
	_draw_smooth_ellipse(cu, cc + Vector2(0, -18), 18, 24, Color(0.18, 0.08, 0.3, 1.0), Color(0.65, 0.25, 0.95, 0.95), 2.0)
	# Central Cyclopean Void Eye
	_draw_smooth_circle(cu, cc + Vector2(0, -12), 8.0, Color(0.95, 0.2, 0.85, 1.0), Color(1.0, 1.0, 1.0, 1.0), 1.5)
	_draw_smooth_circle(cu, cc + Vector2(0, -12), 4.0, Color(0.2, 0.02, 0.3, 1.0))
	_draw_smooth_circle(cu, cc + Vector2(-1.5, -13.5), 1.8, Color.WHITE)
	# Floating shadow casting orb held in hands
	_draw_smooth_circle(cu, cc + Vector2(0, 16), 10.0, Color(0.85, 0.12, 0.45, 0.9), Color(1.0, 0.8, 0.9, 1.0), 1.5)
	cu.save_png("res://assets/sprites/enemies/enemy_cultist.png")

	# C. Elite Void Golem (128x128): Massive basalt armor, glowing volcanic magma core
	var el := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var ec := Vector2(64, 64)
	_draw_smooth_ellipse(el, ec + Vector2(0, 10), 54, 48, Color(1.0, 0.4, 0.05, 0.25))
	_draw_smooth_ellipse(el, ec + Vector2(0, 14), 44, 38, Color(0.1, 0.08, 0.12, 1.0), Color(0.9, 0.4, 0.05, 0.95), 2.5)
	_draw_smooth_ellipse(el, ec + Vector2(0, 8), 36, 32, Color(0.25, 0.18, 0.26, 1.0))
	# Colossal Basalt Rock Shoulders
	_draw_smooth_circle(el, ec + Vector2(-32, -4), 18.0, Color(0.15, 0.12, 0.18, 1.0), Color(1.0, 0.45, 0.05, 1.0), 2.0)
	_draw_smooth_circle(el, ec + Vector2(32, -4), 18.0, Color(0.15, 0.12, 0.18, 1.0), Color(1.0, 0.45, 0.05, 1.0), 2.0)
	# Glowing Magma Heart Core
	_draw_smooth_circle(el, ec + Vector2(0, 10), 16.0, Color(1.0, 0.35, 0.02, 1.0), Color(1.0, 0.9, 0.4, 1.0), 2.0)
	_draw_smooth_circle(el, ec + Vector2(0, 10), 8.0, Color(1.0, 0.95, 0.6, 1.0))
	# Fiery Eye Slits
	_draw_smooth_ellipse(el, ec + Vector2(-8, -22), 4, 2, Color(1.0, 0.9, 0.2, 1.0))
	_draw_smooth_ellipse(el, ec + Vector2(8, -22), 4, 2, Color(1.0, 0.9, 0.2, 1.0))
	el.save_png("res://assets/sprites/enemies/enemy_elite.png")

# 6. Boss Lord Malakar (192x192)
func _gen_boss_sprite() -> void:
	var img := Image.create(192, 192, false, Image.FORMAT_RGBA8)
	var bc := Vector2(96, 96)
	_draw_smooth_ellipse(img, bc + Vector2(0, 10), 85, 86, Color(0.65, 0.1, 0.9, 0.22))
	_draw_smooth_ellipse(img, bc + Vector2(0, 18), 66, 60, Color(0.06, 0.03, 0.09, 1.0), Color(0.85, 0.2, 0.4, 0.95), 3.0)
	_draw_smooth_ellipse(img, bc + Vector2(0, 10), 54, 48, Color(0.18, 0.08, 0.28, 1.0))
	# Massive Horned Dread Crown
	_draw_smooth_ellipse(img, bc + Vector2(-46, -42), 16, 36, Color(0.1, 0.04, 0.16, 1.0), Color(0.8, 0.15, 0.4, 1.0), 2.2)
	_draw_smooth_ellipse(img, bc + Vector2(46, -42), 16, 36, Color(0.1, 0.04, 0.16, 1.0), Color(0.8, 0.15, 0.4, 1.0), 2.2)
	_draw_smooth_circle(img, bc + Vector2(0, -56), 14.0, Color(0.95, 0.15, 0.35, 1.0), Color(1.0, 0.85, 0.3, 1.0), 2.0)
	# Dread Core (Pulsing all-seeing void eye)
	_draw_smooth_circle(img, bc + Vector2(0, 6), 24.0, Color(0.95, 0.08, 0.25, 1.0), Color(1.0, 0.9, 0.3, 1.0), 2.5)
	_draw_smooth_circle(img, bc + Vector2(0, 6), 12.0, Color(1.0, 0.85, 0.2, 1.0))
	_draw_smooth_circle(img, bc + Vector2(0, 6), 5.0, Color.WHITE)
	# Archon Visage & Eyes
	_draw_smooth_circle(img, bc + Vector2(0, -26), 24.0, Color(0.12, 0.05, 0.18, 1.0), Color(0.5, 0.15, 0.7, 1.0), 2.0)
	_draw_smooth_circle(img, bc + Vector2(-9, -26), 5.0, Color(1.0, 0.2, 0.4, 1.0))
	_draw_smooth_circle(img, bc + Vector2(9, -26), 5.0, Color(1.0, 0.2, 0.4, 1.0))
	_draw_smooth_circle(img, bc + Vector2(-9, -26), 2.0, Color.WHITE)
	_draw_smooth_circle(img, bc + Vector2(9, -26), 2.0, Color.WHITE)
	img.save_png("res://assets/sprites/bosses/boss_abyssal_dread.png")

# 7. Combat VFX & Projectiles
func _gen_combat_vfx() -> void:
	# A. Dynamic Crescent Slash (64x64)
	var sl := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var slc := Vector2(32, 32)
	_draw_smooth_circle(sl, slc, 28.0, Color(0.85, 0.35, 1.0, 0.3))
	_draw_smooth_ellipse(sl, slc + Vector2(8, 0), 22, 26, Color(0.95, 0.5, 1.0, 0.95))
	_draw_smooth_ellipse(sl, slc + Vector2(13, 0), 14, 18, Color(1.0, 1.0, 1.0, 1.0))
	sl.save_png("res://assets/sprites/projectiles/proj_slash.png")

	# B. Crackling Lightning Bolt (48x48)
	var lt := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var ltc := Vector2(24, 24)
	_draw_smooth_circle(lt, ltc, 22.0, Color(0.2, 0.8, 1.0, 0.35))
	_draw_smooth_ellipse(lt, ltc, 11, 20, Color(0.55, 0.92, 1.0, 0.95))
	_draw_smooth_circle(lt, ltc, 7.0, Color.WHITE)
	lt.save_png("res://assets/sprites/projectiles/proj_lightning.png")

	# C. Homing Soul Wisp (48x48)
	var so := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var soc := Vector2(24, 24)
	_draw_smooth_circle(so, soc, 22.0, Color(0.15, 0.95, 0.6, 0.35))
	_draw_smooth_ellipse(so, soc, 14, 18, Color(0.35, 1.0, 0.75, 0.95))
	_draw_smooth_circle(so, soc, 6.0, Color.WHITE)
	so.save_png("res://assets/sprites/projectiles/proj_soul.png")

	# D. Impact Spark Burst (48x48)
	var spk := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var spkc := Vector2(24, 24)
	_draw_smooth_circle(spk, spkc, 20.0, Color(1.0, 0.85, 0.25, 0.4))
	_draw_smooth_circle(spk, spkc, 12.0, Color(1.0, 0.95, 0.6, 0.95))
	_draw_smooth_circle(spk, spkc, 6.0, Color.WHITE)
	spk.save_png("res://assets/sprites/vfx/impact_spark.png")

	# E. Critical Hit Burst Star (64x64)
	var crit := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var cc := Vector2(32, 32)
	_draw_smooth_circle(crit, cc, 30.0, Color(1.0, 0.8, 0.1, 0.35))
	_draw_smooth_ellipse(crit, cc, 6, 28, Color(1.0, 0.9, 0.3, 0.95))
	_draw_smooth_ellipse(crit, cc, 28, 6, Color(1.0, 0.9, 0.3, 0.95))
	_draw_smooth_circle(crit, cc, 10.0, Color(1.0, 1.0, 1.0, 1.0))
	crit.save_png("res://assets/sprites/vfx/impact_crit.png")
