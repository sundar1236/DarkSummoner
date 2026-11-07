@tool
extends SceneTree

# Generates clean, crisp HD 2D sprites and icons for Abyssal Altar.
# Guarantees zero missing textures and sharp, consistent dark-fantasy art.

func _init() -> void:
	print("Generating game textures...")
	_ensure_dirs()
	_gen_player_sprite()
	_gen_enemy_sprites()
	_gen_boss_sprite()
	_gen_pet_sprites()
	_gen_projectile_sprites()
	_gen_ui_sprites()
	print("All textures generated successfully!")
	quit()

func _ensure_dirs() -> void:
	var dirs := [
		"res://assets/sprites/characters",
		"res://assets/sprites/enemies",
		"res://assets/sprites/bosses",
		"res://assets/sprites/pets",
		"res://assets/sprites/projectiles",
		"res://assets/sprites/ui"
	]
	for d in dirs:
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(d))

func _fill_circle(img: Image, center: Vector2i, radius: int, col: Color) -> void:
	var r2 := radius * radius
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			var dist2 := x * x + y * y
			if dist2 <= r2:
				var px := center.x + x
				var py := center.y + y
				if px >= 0 and px < img.get_width() and py >= 0 and py < img.get_height():
					# Smooth edge antialiasing
					var edge := float(dist2) / float(r2)
					var alpha := 1.0 - smoothstep(0.85, 1.0, edge)
					var curr := img.get_pixel(px, py)
					var final_col := Color(col.r, col.g, col.b, col.a * alpha)
					img.set_pixel(px, py, curr.blend(final_col))

func _fill_rect(img: Image, rect: Rect2i, col: Color) -> void:
	for y in range(rect.position.y, rect.position.y + rect.size.y):
		for x in range(rect.position.x, rect.position.x + rect.size.x):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, col)

# 1. Player Sprite (72x72) - Dark cloak, glowing hood/eyes, purple energy core
func _gen_player_sprite() -> void:
	var img := Image.create(72, 72, false, Image.FORMAT_RGBA8)
	var c := Vector2i(36, 36)
	
	# Glow halo
	_fill_circle(img, c, 34, Color(0.6, 0.2, 0.9, 0.25))
	_fill_circle(img, c, 26, Color(0.7, 0.3, 1.0, 0.35))
	# Cloak body
	_fill_circle(img, c, 20, Color(0.12, 0.08, 0.18, 1.0))
	_fill_circle(img, c, 17, Color(0.2, 0.12, 0.28, 1.0))
	# Hood and shoulders
	_fill_circle(img, c - Vector2i(0, 4), 13, Color(0.15, 0.09, 0.22, 1.0))
	# Glowing eyes (dual cyan/violet points)
	_fill_circle(img, c + Vector2i(-5, -6), 3, Color(0.4, 0.9, 1.0, 1.0))
	_fill_circle(img, c + Vector2i(5, -6), 3, Color(0.4, 0.9, 1.0, 1.0))
	# Core crystal
	_fill_circle(img, c + Vector2i(0, 5), 4, Color(0.9, 0.3, 0.8, 1.0))
	_fill_circle(img, c + Vector2i(0, 5), 2, Color(1.0, 0.8, 0.95, 1.0))
	
	img.save_png("res://assets/sprites/characters/player_base.png")

# 2. Enemy Sprites: Swarmer (Fiend), Ranged (Cultist), Elite (Void Golem)
func _gen_enemy_sprites() -> void:
	# Swarmer: Spiky crimson fiend
	var swarmer := Image.create(56, 56, false, Image.FORMAT_RGBA8)
	var sc := Vector2i(28, 28)
	_fill_circle(swarmer, sc, 26, Color(0.9, 0.15, 0.2, 0.25))
	_fill_circle(swarmer, sc, 18, Color(0.3, 0.05, 0.08, 1.0))
	_fill_circle(swarmer, sc, 14, Color(0.75, 0.12, 0.18, 1.0))
	# Sharp glowing eyes
	_fill_circle(swarmer, sc + Vector2i(-4, -4), 3, Color(1.0, 0.8, 0.2, 1.0))
	_fill_circle(swarmer, sc + Vector2i(4, -4), 3, Color(1.0, 0.8, 0.2, 1.0))
	# Horns/Spikes
	_fill_circle(swarmer, sc + Vector2i(-12, -10), 4, Color(0.2, 0.02, 0.05, 1.0))
	_fill_circle(swarmer, sc + Vector2i(12, -10), 4, Color(0.2, 0.02, 0.05, 1.0))
	swarmer.save_png("res://assets/sprites/enemies/enemy_swarmer.png")

	# Cultist: Dark hooded caster with violet aura
	var cultist := Image.create(60, 60, false, Image.FORMAT_RGBA8)
	var cc := Vector2i(30, 30)
	_fill_circle(cultist, cc, 28, Color(0.5, 0.1, 0.7, 0.25))
	_fill_circle(cultist, cc, 20, Color(0.12, 0.06, 0.2, 1.0))
	_fill_circle(cultist, cc, 15, Color(0.4, 0.15, 0.65, 1.0))
	# Eye of the void
	_fill_circle(cultist, cc - Vector2i(0, 3), 5, Color(0.9, 0.2, 0.9, 1.0))
	_fill_circle(cultist, cc - Vector2i(0, 3), 2, Color(1.0, 1.0, 1.0, 1.0))
	cultist.save_png("res://assets/sprites/enemies/enemy_cultist.png")

	# Elite: Heavy obsidian golem with cracked magma lines
	var golem := Image.create(84, 84, false, Image.FORMAT_RGBA8)
	var gc := Vector2i(42, 42)
	_fill_circle(golem, gc, 40, Color(0.8, 0.4, 0.1, 0.3))
	_fill_circle(golem, gc, 32, Color(0.1, 0.08, 0.1, 1.0))
	_fill_circle(golem, gc, 26, Color(0.25, 0.2, 0.25, 1.0))
	# Magma core and shoulder runes
	_fill_circle(golem, gc, 10, Color(1.0, 0.45, 0.05, 1.0))
	_fill_circle(golem, gc, 5, Color(1.0, 0.9, 0.4, 1.0))
	_fill_circle(golem, gc + Vector2i(-18, -12), 6, Color(0.9, 0.3, 0.05, 0.9))
	_fill_circle(golem, gc + Vector2i(18, -12), 6, Color(0.9, 0.3, 0.05, 0.9))
	golem.save_png("res://assets/sprites/enemies/enemy_elite.png")

# 3. Boss Sprite (128x128) - Abyssal Dread / Lord Malakar
func _gen_boss_sprite() -> void:
	var boss := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	var bc := Vector2i(64, 64)
	
	# Massive void halo
	_fill_circle(boss, bc, 62, Color(0.6, 0.1, 0.8, 0.25))
	_fill_circle(boss, bc, 52, Color(0.9, 0.15, 0.3, 0.3))
	# Main armored chassis
	_fill_circle(boss, bc, 44, Color(0.08, 0.05, 0.12, 1.0))
	_fill_circle(boss, bc, 36, Color(0.22, 0.12, 0.3, 1.0))
	# Crown horns
	_fill_circle(boss, bc + Vector2i(-30, -32), 10, Color(0.1, 0.04, 0.15, 1.0))
	_fill_circle(boss, bc + Vector2i(30, -32), 10, Color(0.1, 0.04, 0.15, 1.0))
	_fill_circle(boss, bc + Vector2i(0, -42), 8, Color(0.7, 0.1, 0.3, 1.0))
	# Dread Core (pulsing eye)
	_fill_circle(boss, bc, 16, Color(0.95, 0.1, 0.3, 1.0))
	_fill_circle(boss, bc, 9, Color(1.0, 0.85, 0.2, 1.0))
	_fill_circle(boss, bc, 4, Color(1.0, 1.0, 1.0, 1.0))
	# Runes
	_fill_circle(boss, bc + Vector2i(-24, 18), 6, Color(0.7, 0.2, 0.9, 0.9))
	_fill_circle(boss, bc + Vector2i(24, 18), 6, Color(0.7, 0.2, 0.9, 0.9))
	boss.save_png("res://assets/sprites/bosses/boss_abyssal_dread.png")

# 4. Pets (Wolf, Hellhound, Demon)
func _gen_pet_sprites() -> void:
	# Spectral Wolf (Cyan)
	var wolf := Image.create(44, 44, false, Image.FORMAT_RGBA8)
	var wc := Vector2i(22, 22)
	_fill_circle(wolf, wc, 20, Color(0.2, 0.8, 1.0, 0.3))
	_fill_circle(wolf, wc, 13, Color(0.1, 0.4, 0.6, 1.0))
	_fill_circle(wolf, wc, 9, Color(0.3, 0.9, 1.0, 1.0))
	_fill_circle(wolf, wc + Vector2i(-3, -3), 2, Color(1.0, 1.0, 1.0, 1.0))
	_fill_circle(wolf, wc + Vector2i(3, -3), 2, Color(1.0, 1.0, 1.0, 1.0))
	wolf.save_png("res://assets/sprites/pets/pet_wolf.png")

	# Hellhound (Fiery Orange/Red)
	var hound := Image.create(50, 50, false, Image.FORMAT_RGBA8)
	var hc := Vector2i(25, 25)
	_fill_circle(hound, hc, 24, Color(1.0, 0.4, 0.05, 0.4))
	_fill_circle(hound, hc, 16, Color(0.4, 0.08, 0.02, 1.0))
	_fill_circle(hound, hc, 11, Color(1.0, 0.35, 0.05, 1.0))
	_fill_circle(hound, hc + Vector2i(-4, -4), 3, Color(1.0, 0.9, 0.2, 1.0))
	_fill_circle(hound, hc + Vector2i(4, -4), 3, Color(1.0, 0.9, 0.2, 1.0))
	hound.save_png("res://assets/sprites/pets/pet_hellhound.png")

# 5. Projectiles (Player slash/bolt, Soul orb, Enemy projectile, Fireball)
func _gen_projectile_sprites() -> void:
	# Slash wave (36x36)
	var slash := Image.create(36, 36, false, Image.FORMAT_RGBA8)
	var sc := Vector2i(18, 18)
	_fill_circle(slash, sc, 16, Color(0.7, 0.3, 1.0, 0.35))
	_fill_circle(slash, sc, 10, Color(0.9, 0.4, 1.0, 0.9))
	_fill_circle(slash, sc, 5, Color(1.0, 1.0, 1.0, 1.0))
	slash.save_png("res://assets/sprites/projectiles/proj_slash.png")

	# Lightning bolt orb (28x28)
	var bolt := Image.create(28, 28, false, Image.FORMAT_RGBA8)
	var bc := Vector2i(14, 14)
	_fill_circle(bolt, bc, 13, Color(0.2, 0.7, 1.0, 0.4))
	_fill_circle(bolt, bc, 8, Color(0.5, 0.9, 1.0, 0.9))
	_fill_circle(bolt, bc, 4, Color(1.0, 1.0, 1.0, 1.0))
	bolt.save_png("res://assets/sprites/projectiles/proj_lightning.png")

	# Soul orb (30x30)
	var soul := Image.create(30, 30, false, Image.FORMAT_RGBA8)
	var soc := Vector2i(15, 15)
	_fill_circle(soul, soc, 14, Color(0.1, 0.9, 0.6, 0.4))
	_fill_circle(soul, soc, 8, Color(0.3, 1.0, 0.75, 0.95))
	_fill_circle(soul, soc, 4, Color(1.0, 1.0, 1.0, 1.0))
	soul.save_png("res://assets/sprites/projectiles/proj_soul.png")

	# Enemy dark orb (32x32)
	var e_orb := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var ec := Vector2i(16, 16)
	_fill_circle(e_orb, ec, 15, Color(0.85, 0.1, 0.25, 0.35))
	_fill_circle(e_orb, ec, 10, Color(0.25, 0.02, 0.06, 1.0))
	_fill_circle(e_orb, ec, 7, Color(1.0, 0.2, 0.35, 1.0))
	_fill_circle(e_orb, ec, 3, Color(1.0, 0.8, 0.3, 1.0))
	e_orb.save_png("res://assets/sprites/projectiles/proj_enemy.png")

	# Fireball (32x32)
	var fball := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var fc := Vector2i(16, 16)
	_fill_circle(fball, fc, 15, Color(1.0, 0.35, 0.05, 0.4))
	_fill_circle(fball, fc, 9, Color(1.0, 0.6, 0.1, 0.95))
	_fill_circle(fball, fc, 4, Color(1.0, 0.95, 0.4, 1.0))
	fball.save_png("res://assets/sprites/projectiles/proj_fireball.png")

# 6. UI Sprites (Joystick base, Joystick knob, Button frames, Icons)
func _gen_ui_sprites() -> void:
	# Joystick Ring Base (140x140)
	var j_base := Image.create(140, 140, false, Image.FORMAT_RGBA8)
	var jc := Vector2i(70, 70)
	_fill_circle(j_base, jc, 68, Color(0.1, 0.08, 0.16, 0.45))
	_fill_circle(j_base, jc, 65, Color(0.5, 0.3, 0.8, 0.35))
	_fill_circle(j_base, jc, 62, Color(0.08, 0.06, 0.12, 0.5))
	j_base.save_png("res://assets/sprites/ui/joystick_base.png")

	# Joystick Knob (70x70)
	var j_knob := Image.create(70, 70, false, Image.FORMAT_RGBA8)
	var kc := Vector2i(35, 35)
	_fill_circle(j_knob, kc, 34, Color(0.6, 0.3, 0.9, 0.5))
	_fill_circle(j_knob, kc, 28, Color(0.2, 0.12, 0.3, 0.9))
	_fill_circle(j_knob, kc, 22, Color(0.4, 0.2, 0.6, 0.95))
	_fill_circle(j_knob, kc, 8, Color(0.9, 0.5, 1.0, 1.0))
	j_knob.save_png("res://assets/sprites/ui/joystick_knob.png")

	# Action Button Frame (80x80)
	var btn := Image.create(80, 80, false, Image.FORMAT_RGBA8)
	var bc := Vector2i(40, 40)
	_fill_circle(btn, bc, 39, Color(0.5, 0.25, 0.7, 0.6))
	_fill_circle(btn, bc, 36, Color(0.12, 0.08, 0.18, 0.9))
	_fill_circle(btn, bc, 32, Color(0.2, 0.14, 0.28, 0.95))
	btn.save_png("res://assets/sprites/ui/button_circle.png")

	# Currency Gem / Shade (32x32)
	var shade := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var sc := Vector2i(16, 16)
	_fill_circle(shade, sc, 14, Color(0.65, 0.2, 0.9, 0.4))
	_fill_circle(shade, sc, 10, Color(0.85, 0.3, 1.0, 1.0))
	_fill_circle(shade, sc, 5, Color(1.0, 0.8, 1.0, 1.0))
	shade.save_png("res://assets/sprites/ui/icon_shade.png")

	# Gold Coin (32x32)
	var gold := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var gc := Vector2i(16, 16)
	_fill_circle(gold, gc, 14, Color(0.8, 0.6, 0.1, 0.5))
	_fill_circle(gold, gc, 11, Color(1.0, 0.8, 0.1, 1.0))
	_fill_circle(gold, gc, 7, Color(1.0, 0.95, 0.5, 1.0))
	gold.save_png("res://assets/sprites/ui/icon_gold.png")
