@tool
extends SceneTree

# Generates clean, crisp HD 2.5D sprites, weapon overlays, shadows, and combat VFX
# for Abyssal Altar's visual overhaul.

func _init() -> void:
	print("--- Generating HD 2.5D Game Assets ---")
	_ensure_dirs()
	_gen_ground_shadow()
	_gen_shadow_hunter_sprites()
	_gen_storm_reaper_sprites()
	_gen_soul_binder_sprites()
	_gen_enemy_hd_sprites()
	_gen_boss_hd_sprites()
	_gen_vfx_and_weapons()
	print("--- All HD Assets Generated Successfully! ---")
	quit()

func _ensure_dirs() -> void:
	var dirs := [
		"res://assets/sprites/characters",
		"res://assets/sprites/enemies",
		"res://assets/sprites/bosses",
		"res://assets/sprites/pets",
		"res://assets/sprites/projectiles",
		"res://assets/sprites/vfx",
		"res://assets/sprites/ui"
	]
	for d in dirs:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))

func _fill_ellipse(img: Image, center: Vector2i, rx: int, ry: int, col: Color) -> void:
	var rx2 := float(rx * rx)
	var ry2 := float(ry * ry)
	for y in range(-ry, ry + 1):
		for x in range(-rx, rx + 1):
			var val := (float(x * x) / rx2) + (float(y * y) / ry2)
			if val <= 1.0:
				var px := center.x + x
				var py := center.y + y
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					var edge := val
					var alpha := 1.0 - smoothstep(0.7, 1.0, edge)
					var curr := img.get_pixel(px, py)
					var final_col := Color(col.r, col.g, col.b, col.a * alpha)
					img.set_pixel(px, py, curr.blend(final_col))

func _fill_circle(img: Image, center: Vector2i, radius: int, col: Color) -> void:
	var r2 := radius * radius
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var dist2 := x * x + y * y
			if dist2 <= r2:
				var px := center.x + x
				var py := center.y + y
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					var edge := float(dist2) / float(r2)
					var alpha := 1.0 - smoothstep(0.8, 1.0, edge)
					var curr := img.get_pixel(px, py)
					var final_col := Color(col.r, col.g, col.b, col.a * alpha)
					img.set_pixel(px, py, curr.blend(final_col))

# Ground Contact Shadow (Archero 2 style soft oval shadow)
func _gen_ground_shadow() -> void:
	var img := Image.create(64, 32, false, Image.FORMAT_RGBA8)
	var c := Vector2i(32, 16)
	_fill_ellipse(img, c, 30, 14, Color(0.0, 0.0, 0.0, 0.65))
	_fill_ellipse(img, c, 20, 9, Color(0.0, 0.0, 0.0, 0.85))
	img.save_png("res://assets/sprites/vfx/ground_shadow.png")

# 1. Shadow Hunter — 2.5D Rogue with hood, dark cloak, leather armor, glowing cyan/purple eyes & dual daggers
func _gen_shadow_hunter_sprites() -> void:
	var img := Image.create(80, 96, false, Image.FORMAT_RGBA8)
	var c := Vector2i(40, 48)
	
	# Aura aura glow
	_fill_ellipse(img, c + Vector2i(0, 10), 32, 38, Color(0.65, 0.2, 0.95, 0.2))
	# Flowing hooded cloak (3/4 top-down angled silhouette)
	_fill_ellipse(img, c + Vector2i(0, 14), 24, 28, Color(0.08, 0.05, 0.12, 1.0)) # Dark cloak base
	_fill_ellipse(img, c + Vector2i(0, 10), 20, 24, Color(0.16, 0.1, 0.24, 1.0)) # Layered fabric
	# Leather chestplate & harness
	_fill_ellipse(img, c + Vector2i(0, 4), 16, 16, Color(0.28, 0.18, 0.38, 1.0))
	_fill_ellipse(img, c + Vector2i(0, 2), 12, 12, Color(0.42, 0.22, 0.55, 1.0))
	# Pauldrons (shoulders)
	_fill_circle(img, c + Vector2i(-16, 2), 7, Color(0.2, 0.12, 0.28, 1.0))
	_fill_circle(img, c + Vector2i(16, 2), 7, Color(0.2, 0.12, 0.28, 1.0))
	_fill_circle(img, c + Vector2i(-16, 2), 4, Color(0.5, 0.25, 0.7, 1.0))
	_fill_circle(img, c + Vector2i(16, 2), 4, Color(0.5, 0.25, 0.7, 1.0))
	# Hood silhouette
	_fill_circle(img, c + Vector2i(0, -12), 16, Color(0.1, 0.06, 0.16, 1.0))
	_fill_circle(img, c + Vector2i(0, -14), 13, Color(0.18, 0.12, 0.28, 1.0))
	# Face shadow void inside hood
	_fill_ellipse(img, c + Vector2i(0, -10), 9, 7, Color(0.02, 0.01, 0.05, 1.0))
	# Piercing glowing eyes (Cyan/Violet)
	_fill_ellipse(img, c + Vector2i(-4, -10), 3, 2, Color(0.3, 0.9, 1.0, 1.0))
	_fill_ellipse(img, c + Vector2i(4, -10), 3, 2, Color(0.3, 0.9, 1.0, 1.0))
	_fill_circle(img, c + Vector2i(-4, -10), 1, Color(1.0, 1.0, 1.0, 1.0))
	_fill_circle(img, c + Vector2i(4, -10), 1, Color(1.0, 1.0, 1.0, 1.0))
	# Belt with void sigil buckle
	_fill_circle(img, c + Vector2i(0, 18), 5, Color(0.9, 0.3, 0.8, 1.0))
	_fill_circle(img, c + Vector2i(0, 18), 2, Color(1.0, 0.8, 0.95, 1.0))
	# Dual daggers sheathed / held at angle
	_fill_ellipse(img, c + Vector2i(-18, 14), 4, 10, Color(0.7, 0.25, 0.95, 1.0))
	_fill_ellipse(img, c + Vector2i(18, 14), 4, 10, Color(0.7, 0.25, 0.95, 1.0))
	_fill_ellipse(img, c + Vector2i(-18, 14), 2, 7, Color(0.95, 0.7, 1.0, 1.0))
	_fill_ellipse(img, c + Vector2i(18, 14), 2, 7, Color(0.95, 0.7, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_shadow_hunter.png")
	img.save_png("res://assets/sprites/characters/player_base.png")

# 2. Storm Reaper — Heavy armored warrior with lightning war-scythe & electric blue crest
func _gen_storm_reaper_sprites() -> void:
	var img := Image.create(84, 98, false, Image.FORMAT_RGBA8)
	var c := Vector2i(42, 49)
	
	# Electric aura
	_fill_ellipse(img, c + Vector2i(0, 8), 34, 40, Color(0.15, 0.6, 1.0, 0.25))
	# Armored plate coat
	_fill_ellipse(img, c + Vector2i(0, 14), 26, 30, Color(0.08, 0.12, 0.18, 1.0))
	_fill_ellipse(img, c + Vector2i(0, 10), 22, 25, Color(0.18, 0.26, 0.36, 1.0))
	# Heavy steel plate & lightning runes
	_fill_ellipse(img, c + Vector2i(0, 4), 18, 17, Color(0.3, 0.45, 0.6, 1.0))
	_fill_ellipse(img, c + Vector2i(0, 2), 13, 12, Color(0.5, 0.75, 0.95, 1.0))
	# Large spiked storm pauldrons
	_fill_circle(img, c + Vector2i(-20, 2), 9, Color(0.2, 0.3, 0.45, 1.0))
	_fill_circle(img, c + Vector2i(20, 2), 9, Color(0.2, 0.3, 0.45, 1.0))
	_fill_circle(img, c + Vector2i(-20, 2), 5, Color(0.4, 0.85, 1.0, 1.0))
	_fill_circle(img, c + Vector2i(20, 2), 5, Color(0.4, 0.85, 1.0, 1.0))
	# Horned battle helm
	_fill_circle(img, c + Vector2i(0, -14), 16, Color(0.12, 0.18, 0.26, 1.0))
	_fill_circle(img, c + Vector2i(0, -16), 13, Color(0.25, 0.38, 0.52, 1.0))
	# Horns extending outwards
	_fill_ellipse(img, c + Vector2i(-16, -24), 5, 12, Color(0.35, 0.55, 0.75, 1.0))
	_fill_ellipse(img, c + Vector2i(16, -24), 5, 12, Color(0.35, 0.55, 0.75, 1.0))
	# Helm visor with crackling cyan eye slit
	_fill_ellipse(img, c + Vector2i(0, -12), 10, 4, Color(0.04, 0.06, 0.1, 1.0))
	_fill_ellipse(img, c + Vector2i(0, -12), 8, 2, Color(0.4, 0.95, 1.0, 1.0))
	_fill_ellipse(img, c + Vector2i(0, -12), 4, 1, Color(1.0, 1.0, 1.0, 1.0))
	# Lightning Scythe blade visible on back/side
	_fill_ellipse(img, c + Vector2i(24, -8), 6, 22, Color(0.2, 0.8, 1.0, 0.9))
	_fill_ellipse(img, c + Vector2i(24, -8), 3, 16, Color(0.8, 0.95, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_storm_reaper.png")

# 3. Soul Binder — Occult robe summoner with skull ceremonial mask, soul crystals & spectral staff
func _gen_soul_binder_sprites() -> void:
	var img := Image.create(84, 98, false, Image.FORMAT_RGBA8)
	var c := Vector2i(42, 49)
	
	# Spectral green soul aura
	_fill_ellipse(img, c + Vector2i(0, 10), 34, 40, Color(0.15, 0.85, 0.55, 0.25))
	# Cascading occult robe
	_fill_ellipse(img, c + Vector2i(0, 16), 26, 32, Color(0.06, 0.14, 0.1, 1.0))
	_fill_ellipse(img, c + Vector2i(0, 12), 22, 26, Color(0.12, 0.28, 0.2, 1.0))
	# Ritual vestment & talisman glyphs
	_fill_ellipse(img, c + Vector2i(0, 4), 16, 17, Color(0.2, 0.5, 0.35, 1.0))
	_fill_ellipse(img, c + Vector2i(0, 2), 12, 12, Color(0.4, 0.9, 0.65, 1.0))
	# Floating soul orbs orbiting shoulders
	_fill_circle(img, c + Vector2i(-22, -2), 7, Color(0.2, 0.9, 0.6, 0.8))
	_fill_circle(img, c + Vector2i(-22, -2), 3, Color(0.8, 1.0, 0.9, 1.0))
	_fill_circle(img, c + Vector2i(22, -2), 7, Color(0.2, 0.9, 0.6, 0.8))
	_fill_circle(img, c + Vector2i(22, -2), 3, Color(0.8, 1.0, 0.9, 1.0))
	# Occult Cowl
	_fill_circle(img, c + Vector2i(0, -12), 17, Color(0.08, 0.18, 0.12, 1.0))
	_fill_circle(img, c + Vector2i(0, -14), 14, Color(0.15, 0.32, 0.22, 1.0))
	# Bone mask
	_fill_ellipse(img, c + Vector2i(0, -10), 10, 8, Color(0.85, 0.85, 0.78, 1.0))
	_fill_ellipse(img, c + Vector2i(0, -10), 8, 6, Color(0.95, 0.95, 0.9, 1.0))
	# Glowing spectral emerald eye sockets
	_fill_circle(img, c + Vector2i(-4, -10), 3, Color(0.1, 0.9, 0.5, 1.0))
	_fill_circle(img, c + Vector2i(4, -10), 3, Color(0.1, 0.9, 0.5, 1.0))
	_fill_circle(img, c + Vector2i(-4, -10), 1, Color(1.0, 1.0, 1.0, 1.0))
	_fill_circle(img, c + Vector2i(4, -10), 1, Color(1.0, 1.0, 1.0, 1.0))
	# Soul staff focus with lantern crystal
	_fill_ellipse(img, c + Vector2i(24, 6), 4, 20, Color(0.25, 0.2, 0.15, 1.0))
	_fill_circle(img, c + Vector2i(24, -16), 8, Color(0.2, 0.95, 0.65, 0.9))
	_fill_circle(img, c + Vector2i(24, -16), 4, Color(1.0, 1.0, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_soul_binder.png")

# 4. Enemies: Swarmer, Cultist, Elite Golem with distinct top-down silhouettes
func _gen_enemy_hd_sprites() -> void:
	# Swarmer: Fierce crimson horned prowler with sharp carapace and fanged maw
	var sw := Image.create(68, 68, false, Image.FORMAT_RGBA8)
	var sc := Vector2i(34, 34)
	_fill_ellipse(sw, sc + Vector2i(0, 6), 28, 22, Color(0.9, 0.15, 0.25, 0.25))
	_fill_ellipse(sw, sc + Vector2i(0, 4), 22, 17, Color(0.22, 0.04, 0.08, 1.0))
	_fill_ellipse(sw, sc + Vector2i(0, 2), 17, 13, Color(0.65, 0.12, 0.2, 1.0))
	# Spiky spine ridges
	_fill_circle(sw, sc + Vector2i(0, -6), 8, Color(0.85, 0.18, 0.26, 1.0))
	_fill_circle(sw, sc + Vector2i(-10, -4), 6, Color(0.4, 0.06, 0.12, 1.0))
	_fill_circle(sw, sc + Vector2i(10, -4), 6, Color(0.4, 0.06, 0.12, 1.0))
	# Mandibles / fangs
	_fill_ellipse(sw, sc + Vector2i(-8, 12), 4, 8, Color(0.95, 0.85, 0.7, 1.0))
	_fill_ellipse(sw, sc + Vector2i(8, 12), 4, 8, Color(0.95, 0.85, 0.7, 1.0))
	# Fiendish amber eyes
	_fill_circle(sw, sc + Vector2i(-6, 2), 3, Color(1.0, 0.8, 0.1, 1.0))
	_fill_circle(sw, sc + Vector2i(6, 2), 3, Color(1.0, 0.8, 0.1, 1.0))
	_fill_circle(sw, sc + Vector2i(-6, 2), 1, Color(1.0, 1.0, 1.0, 1.0))
	_fill_circle(sw, sc + Vector2i(6, 2), 1, Color(1.0, 1.0, 1.0, 1.0))
	sw.save_png("res://assets/sprites/enemies/enemy_swarmer.png")

	# Cultist: Levitating shadow priest with tall pointed mitre cowl, floating orb & occult ribbons
	var cu := Image.create(72, 84, false, Image.FORMAT_RGBA8)
	var cc := Vector2i(36, 42)
	_fill_ellipse(cu, cc + Vector2i(0, 10), 28, 30, Color(0.5, 0.1, 0.75, 0.25))
	_fill_ellipse(cu, cc + Vector2i(0, 14), 20, 24, Color(0.12, 0.05, 0.2, 1.0))
	_fill_ellipse(cu, cc + Vector2i(0, 8), 16, 20, Color(0.35, 0.12, 0.55, 1.0))
	# Tall pointed occult hood
	_fill_ellipse(cu, cc + Vector2i(0, -14), 14, 18, Color(0.16, 0.07, 0.26, 1.0))
	_fill_ellipse(cu, cc + Vector2i(0, -18), 10, 14, Color(0.45, 0.18, 0.68, 1.0))
	# Eye of the Abyss (single central cyclopean void eye)
	_fill_circle(cu, cc + Vector2i(0, -10), 6, Color(0.95, 0.2, 0.85, 1.0))
	_fill_circle(cu, cc + Vector2i(0, -10), 3, Color(1.0, 0.9, 1.0, 1.0))
	# Floating shadow casting orb held in hands
	_fill_circle(cu, cc + Vector2i(0, 12), 8, Color(0.8, 0.1, 0.35, 0.9))
	_fill_circle(cu, cc + Vector2i(0, 12), 4, Color(1.0, 0.7, 0.8, 1.0))
	cu.save_png("res://assets/sprites/enemies/enemy_cultist.png")

	# Elite Void Golem: Colossal volcanic obsidian armor with jagged basalt plates and glowing magma core
	var go := Image.create(96, 104, false, Image.FORMAT_RGBA8)
	var gc := Vector2i(48, 52)
	_fill_ellipse(go, gc + Vector2i(0, 10), 42, 38, Color(0.9, 0.4, 0.05, 0.3))
	_fill_ellipse(go, gc + Vector2i(0, 14), 36, 32, Color(0.1, 0.08, 0.12, 1.0))
	_fill_ellipse(go, gc + Vector2i(0, 8), 30, 26, Color(0.25, 0.18, 0.26, 1.0))
	# Massive obsidian rock shoulders
	_fill_circle(go, gc + Vector2i(-26, -4), 14, Color(0.15, 0.12, 0.18, 1.0))
	_fill_circle(go, gc + Vector2i(26, -4), 14, Color(0.15, 0.12, 0.18, 1.0))
	_fill_circle(go, gc + Vector2i(-26, -4), 7, Color(1.0, 0.45, 0.05, 1.0))
	_fill_circle(go, gc + Vector2i(26, -4), 7, Color(1.0, 0.45, 0.05, 1.0))
	# Magma heart core
	_fill_circle(go, gc + Vector2i(0, 8), 12, Color(1.0, 0.35, 0.02, 1.0))
	_fill_circle(go, gc + Vector2i(0, 8), 6, Color(1.0, 0.85, 0.3, 1.0))
	# Head crest & dual fiery vents
	_fill_circle(go, gc + Vector2i(0, -18), 14, Color(0.12, 0.09, 0.15, 1.0))
	_fill_circle(go, gc + Vector2i(0, -18), 9, Color(0.35, 0.25, 0.35, 1.0))
	_fill_circle(go, gc + Vector2i(-6, -18), 3, Color(1.0, 0.9, 0.2, 1.0))
	_fill_circle(go, gc + Vector2i(6, -18), 3, Color(1.0, 0.9, 0.2, 1.0))
	go.save_png("res://assets/sprites/enemies/enemy_elite.png")

# 5. Boss Lord Malakar — Massive Void Archon with glowing crown, void wings, and dread core
func _gen_boss_hd_sprites() -> void:
	var img := Image.create(150, 160, false, Image.FORMAT_RGBA8)
	var bc := Vector2i(75, 80)
	
	# Colossal ethereal void aura
	_fill_ellipse(img, bc + Vector2i(0, 10), 70, 72, Color(0.6, 0.1, 0.85, 0.25))
	_fill_ellipse(img, bc + Vector2i(0, 8), 58, 60, Color(0.95, 0.15, 0.35, 0.3))
	# Heavy obsidian mantle & floating void shroud wings
	_fill_ellipse(img, bc + Vector2i(0, 22), 52, 48, Color(0.06, 0.03, 0.09, 1.0))
	_fill_ellipse(img, bc + Vector2i(0, 14), 44, 40, Color(0.18, 0.08, 0.26, 1.0))
	# Massive horned crown
	_fill_ellipse(img, bc + Vector2i(-38, -36), 14, 30, Color(0.1, 0.04, 0.16, 1.0))
	_fill_ellipse(img, bc + Vector2i(38, -36), 14, 30, Color(0.1, 0.04, 0.16, 1.0))
	_fill_ellipse(img, bc + Vector2i(-38, -36), 7, 22, Color(0.65, 0.15, 0.8, 1.0))
	_fill_ellipse(img, bc + Vector2i(38, -36), 7, 22, Color(0.65, 0.15, 0.8, 1.0))
	_fill_circle(img, bc + Vector2i(0, -48), 12, Color(0.9, 0.15, 0.35, 1.0))
	# Armored chest carapace
	_fill_ellipse(img, bc + Vector2i(0, 6), 32, 28, Color(0.28, 0.14, 0.38, 1.0))
	# Dread Core (pulsing all-seeing void eye)
	_fill_circle(img, bc + Vector2i(0, 4), 18, Color(0.95, 0.08, 0.25, 1.0))
	_fill_circle(img, bc + Vector2i(0, 4), 10, Color(1.0, 0.85, 0.2, 1.0))
	_fill_circle(img, bc + Vector2i(0, 4), 4, Color(1.0, 1.0, 1.0, 1.0))
	# Horned Archon Visage
	_fill_circle(img, bc + Vector2i(0, -22), 20, Color(0.12, 0.05, 0.18, 1.0))
	_fill_circle(img, bc + Vector2i(0, -22), 14, Color(0.22, 0.1, 0.32, 1.0))
	_fill_circle(img, bc + Vector2i(-7, -22), 4, Color(1.0, 0.2, 0.4, 1.0))
	_fill_circle(img, bc + Vector2i(7, -22), 4, Color(1.0, 0.2, 0.4, 1.0))
	_fill_circle(img, bc + Vector2i(-7, -22), 1, Color(1.0, 1.0, 1.0, 1.0))
	_fill_circle(img, bc + Vector2i(7, -22), 1, Color(1.0, 1.0, 1.0, 1.0))
	
	img.save_png("res://assets/sprites/bosses/boss_abyssal_dread.png")

# 6. VFX & Weapons: Crescent Slash, Lightning Bolt, Soul Wisp, Impact Spark, Summon Circle
func _gen_vfx_and_weapons() -> void:
	# Crescent Slash Arc (48x48)
	var sl := Image.create(48, 48, false, Image.FORMAT_RGBA8)
	var slc := Vector2i(24, 24)
	_fill_circle(sl, slc, 22, Color(0.8, 0.35, 1.0, 0.35))
	_fill_ellipse(sl, slc + Vector2i(6, 0), 16, 20, Color(0.95, 0.45, 1.0, 0.9))
	_fill_ellipse(sl, slc + Vector2i(10, 0), 10, 14, Color(1.0, 1.0, 1.0, 1.0))
	sl.save_png("res://assets/sprites/projectiles/proj_slash.png")

	# Lightning Bolt with electrical branch (36x36)
	var lt := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var ltc := Vector2i(18, 18)
	_fill_circle(lt, ltc, 16, Color(0.2, 0.75, 1.0, 0.4))
	_fill_ellipse(lt, ltc, 8, 15, Color(0.55, 0.9, 1.0, 0.95))
	_fill_circle(lt, ltc, 5, Color(1.0, 1.0, 1.0, 1.0))
	lt.save_png("res://assets/sprites/projectiles/proj_lightning.png")

	# Soul Wisp with trailing ethereal fire (36x36)
	var sw := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var swc := Vector2i(18, 18)
	_fill_circle(sw, swc, 16, Color(0.15, 0.9, 0.6, 0.35))
	_fill_ellipse(sw, swc, 10, 14, Color(0.35, 1.0, 0.75, 0.9))
	_fill_circle(sw, swc, 4, Color(1.0, 1.0, 1.0, 1.0))
	sw.save_png("res://assets/sprites/projectiles/proj_soul.png")

	# Impact Spark Burst (32x32)
	var spk := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var spkc := Vector2i(16, 16)
	_fill_circle(spk, spkc, 14, Color(1.0, 0.85, 0.2, 0.4))
	_fill_circle(spk, spkc, 8, Color(1.0, 0.95, 0.5, 0.9))
	_fill_circle(spk, spkc, 4, Color(1.0, 1.0, 1.0, 1.0))
	spk.save_png("res://assets/sprites/vfx/impact_spark.png")

	# Summoning Circle Runic Decal (80x80)
	var sc := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var scc := Vector2i(40, 40)
	_fill_circle(sc, scc, 38, Color(0.18, 0.85, 0.55, 0.2))
	_fill_circle(sc, scc, 32, Color(0.1, 0.4, 0.25, 0.5))
	_fill_circle(sc, scc, 22, Color(0.25, 0.95, 0.65, 0.6))
	_fill_circle(sc, scc, 8, Color(0.7, 1.0, 0.85, 0.9))
	sc.save_png("res://assets/sprites/vfx/summon_circle.png")

	# Shadow Dash Afterimage speed line (64x64)
	var sda := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var sdac := Vector2i(32, 32)
	_fill_ellipse(sda, sdac, 28, 14, Color(0.65, 0.2, 0.95, 0.45))
	_fill_ellipse(sda, sdac, 18, 8, Color(0.85, 0.4, 1.0, 0.7))
	_fill_ellipse(sda, sdac, 8, 3, Color(1.0, 0.9, 1.0, 0.9))
	sda.save_png("res://assets/sprites/vfx/shadow_dash_trail.png")
