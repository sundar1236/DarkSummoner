class_name BossController
extends CharacterBody2D

const CoinPickupClass = preload("res://scripts/combat/coin_pickup.gd")
const XpPickupClass = preload("res://scripts/combat/xp_pickup.gd")
const CombatSpriteFeedback = preload("res://scripts/combat/combat_sprite_feedback.gd")

# Floor Boss controller: "Lord Malakar, the Abyssal Dread".
# Features multi-phase combat and readable animated warning telegraph danger zones.

signal boss_hp_changed(current: float, max_val: float)
signal boss_defeated()

var max_hp: float = 400.0
var hp: float = 400.0
var is_dead: bool = false
var move_speed: float = 90.0

var player_ref: Node2D
var shadow_sprite: Sprite2D
var sprite: Sprite2D
var visual_root: Node2D

var is_enraged: bool = false
var is_performing_attack: bool = false
var damage_multiplier: float = 1.0
var attack_cooldown: float = 2.8
var attack_timer: float = 0.0
var attack_index: int = 0
var anim_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 2 # Enemy
	collision_mask = 1 | 4 | 16
	
	_setup_visuals()

func setup(p_floor: int) -> void:
	var scale_mult := 1.0 + float(p_floor - 1) * 0.5
	var difficulty_mods: Dictionary = SaveManager.get_difficulty_multipliers() if SaveManager else {}
	max_hp = 380.0 * scale_mult * float(difficulty_mods.get("boss_hp", 1.0))
	damage_multiplier = float(difficulty_mods.get("boss_damage", 1.0))
	hp = max_hp
	boss_hp_changed.emit(hp, max_hp)
	if AudioManager:
		AudioManager.play_sfx("boss_intro")
		AudioManager.play_music("boss")

func _setup_visuals() -> void:
	# 1. Heavy ground contact shadow
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = TextureLoader.get_texture("res://assets/sprites/vfx/ground_shadow.png")
	shadow_sprite.position = Vector2(0, 48)
	shadow_sprite.scale = Vector2(2.4, 2.4)
	shadow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.8)
	shadow_sprite.z_index = -1
	add_child(shadow_sprite)
	
	# 2. Main Boss Sprite on a presentation-only wrapper.
	visual_root = Node2D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)
	sprite = Sprite2D.new()
	sprite.texture = TextureLoader.get_texture("res://assets/sprites/bosses/boss_abyssal_dread.png")
	sprite.position = Vector2(0, -10)
	visual_root.add_child(sprite)
	
	# 3. Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 42.0
	col.shape = shape
	add_child(col)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	anim_time += delta
	if not is_instance_valid(player_ref):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player_ref = p_nodes[0]
			
	if not is_instance_valid(player_ref):
		return
		
	# Check enrage threshold at 50% HP
	if not is_enraged and (hp / max_hp) <= 0.5:
		_enter_enraged_phase()
		
	# Floating bobbing animation
	var float_y := sin(anim_time * 2.5) * 6.0
	sprite.position = Vector2(0, -10.0 + float_y)
	
	# Directional Facing
	var dir_to_p := (player_ref.global_position - global_position).normalized()
	if abs(dir_to_p.x) > 0.05:
		sprite.flip_h = (dir_to_p.x < 0.0)
		
	if not is_performing_attack:
		velocity = dir_to_p * (move_speed * (1.3 if is_enraged else 1.0))
		move_and_slide()
		
		attack_timer += delta
		var threshold := 1.6 if is_enraged else attack_cooldown
		if attack_timer >= threshold:
			attack_timer = 0.0
			_execute_next_attack()

func _enter_enraged_phase() -> void:
	is_enraged = true
	if AudioManager:
		AudioManager.play_sfx("boss_intro")
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_impact"):
		cam.apply_impact(8.0, 0.3)
		
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1.5, 0.35, 0.35, 1.0), 0.5)

func _execute_next_attack() -> void:
	is_performing_attack = true
	velocity = Vector2.ZERO
	
	match attack_index % 4:
		0: _attack_void_eruption()
		1: _attack_abyssal_charge()
		2: _attack_nova_ring()
		3: _attack_abyssal_cross()
		
	attack_index += 1

# Attack 1: Telegraphed Ground Danger Zone with animated filling countdown disk
func _attack_void_eruption() -> void:
	if not is_instance_valid(player_ref):
		is_performing_attack = false
		return
		
	if AudioManager:
		AudioManager.play_sfx("boss_warning")
		
	var target_pos := player_ref.global_position
	
	# Spawn warning circle indicator on ground
	var warn_node := Node2D.new()
	warn_node.global_position = target_pos
	warn_node.z_index = -1
	get_parent().add_child(warn_node)
	
	var progress: float = 0.0
	warn_node.draw.connect(func():
		var radius: float = 80.0
		# Static red border circle
		warn_node.draw_arc(Vector2.ZERO, radius, 0, TAU, 36, Color(1.0, 0.25, 0.3, 0.85), 3.0)
		warn_node.draw_circle(Vector2.ZERO, radius, Color(1.0, 0.1, 0.2, 0.18))
		# Expanding danger inner fill indicating countdown
		var fill_r: float = radius * clampf(progress, 0.0, 1.0)
		warn_node.draw_circle(Vector2.ZERO, fill_r, Color(1.0, 0.15, 0.25, 0.45))
	)
	
	var tween := create_tween()
	tween.tween_method(func(v: float):
		progress = v
		if is_instance_valid(warn_node):
			warn_node.queue_redraw()
	, 0.0, 1.0, 1.0)
	
	get_tree().create_timer(1.0).timeout.connect(func():
		if is_dead or not is_inside_tree():
			if is_instance_valid(warn_node):
				warn_node.queue_free()
			is_performing_attack = false
			return
		if is_instance_valid(warn_node):
			if AudioManager:
				AudioManager.play_sfx("boss_hit")
			var cam := get_viewport().get_camera_2d()
			if cam and cam.has_method("apply_impact"):
				cam.apply_impact(6.0, 0.18)
				
			# Check if player is inside eruption zone
			if is_instance_valid(player_ref):
				var dist := warn_node.global_position.distance_to(player_ref.global_position)
				if dist <= 80.0 and player_ref.has_method("take_player_damage"):
					player_ref.take_player_damage(30.0 * damage_multiplier)
			warn_node.queue_free()
		is_performing_attack = false
	)

# Attack 2: Telegraphed Charge Dash with directional guide line
func _attack_abyssal_charge() -> void:
	if not is_instance_valid(player_ref):
		is_performing_attack = false
		return
		
	if AudioManager:
		AudioManager.play_sfx("boss_warning")
		
	var charge_dir := (player_ref.global_position - global_position).normalized()
	
	# Draw directional telegraph line
	var line_node := Node2D.new()
	line_node.z_index = -1
	line_node.draw.connect(func():
		line_node.draw_line(Vector2.ZERO, charge_dir * 320.0, Color(1.0, 0.2, 0.3, 0.7), 4.0)
		line_node.draw_circle(charge_dir * 320.0, 12.0, Color(1.0, 0.3, 0.4, 0.8))
	)
	add_child(line_node)
	
	# 0.8s charging windup pulse; physics and collision remain on the boss body.
	CombatSpriteFeedback.play_telegraph(visual_root, charge_dir, 0.8, Vector2(1.18, 0.88))
	
	get_tree().create_timer(0.8).timeout.connect(func():
		if is_instance_valid(line_node):
			line_node.queue_free()
		if is_dead or not is_inside_tree():
			is_performing_attack = false
			return
		velocity = charge_dir * 520.0
		var charge_time := 0.48
		var timer := 0.0
		while timer < charge_time:
			if not is_inside_tree() or is_dead: break
			move_and_slide()
			# Check contact with player
			if is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 58.0:
				player_ref.take_player_damage(26.0 * damage_multiplier)
				break
			await get_tree().physics_frame
			timer += get_physics_process_delta_time()
		velocity = Vector2.ZERO
		is_performing_attack = false
	)

# Attack 3: Nova Ring (360 Projectile Burst)
func _attack_nova_ring() -> void:
	if AudioManager:
		AudioManager.play_sfx("boss_warning")
		
	# Charge flare
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 0.5, 0.8, 1.0), 0.3)
	tween.tween_property(sprite, "modulate", Color(1.5, 0.35, 0.35, 1.0) if is_enraged else Color(1.0, 1.0, 1.0, 1.0), 0.3)
	
	get_tree().create_timer(0.6).timeout.connect(func():
		if is_dead or not is_inside_tree():
			is_performing_attack = false
			return
		var count: int = 14 if is_enraged else 11
		for i in range(count):
			if not ProjectileController.can_spawn_projectile():
				break
			var angle := (TAU / float(count)) * float(i)
			var dir := Vector2.RIGHT.rotated(angle)
			var proj := ProjectileController.new()
			get_parent().add_child(proj)
			proj.global_position = global_position
			proj.setup(14.0 * damage_multiplier, false, dir, 320.0, "enemy", false)
		if AudioManager:
			AudioManager.play_sfx("proj_launch")
		is_performing_attack = false
	)


func _attack_abyssal_cross() -> void:
	if AudioManager:
		AudioManager.play_sfx("boss_warning")
	var cross_telegraph := Node2D.new()
	cross_telegraph.global_position = global_position
	cross_telegraph.z_index = -1
	cross_telegraph.draw.connect(func():
		var line_color := Color(1.0, 0.22, 0.36, 0.78)
		cross_telegraph.draw_line(Vector2(-360, 0), Vector2(360, 0), line_color, 4.0)
		cross_telegraph.draw_line(Vector2(0, -360), Vector2(0, 360), line_color, 4.0)
		cross_telegraph.draw_circle(Vector2.ZERO, 34.0, Color(1.0, 0.12, 0.24, 0.18))
	)
	get_parent().add_child(cross_telegraph)
	CombatSpriteFeedback.play_telegraph(visual_root, Vector2.UP, 0.48, Vector2(1.12, 0.9))
	get_tree().create_timer(0.65).timeout.connect(func():
		if is_instance_valid(cross_telegraph):
			cross_telegraph.queue_free()
		if is_dead or not is_inside_tree():
			is_performing_attack = false
			return
		var damage: float = (20.0 if is_enraged else 16.0) * damage_multiplier
		for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
			if not ProjectileController.can_spawn_projectile():
				break
			var projectile := ProjectileController.new()
			get_parent().add_child(projectile)
			projectile.global_position = global_position
			projectile.setup(damage, false, Vector2.RIGHT.rotated(angle), 400.0, "enemy", false)
		if AudioManager:
			AudioManager.play_sfx("proj_launch")
		is_performing_attack = false
	)

static func get_attack_pattern_name(index: int) -> String:
	var patterns: Array[String] = ["void_eruption", "abyssal_charge", "nova_ring", "abyssal_cross"]
	return patterns[posmod(index, patterns.size())]


func take_damage(amount: float, is_crit: bool) -> void:
	if is_dead or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	boss_hp_changed.emit(hp, max_hp)
	
	var dmg_num := DamageNumber.new()
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_crit, global_position + Vector2(0, -20))
	
	var recoil_direction := Vector2.UP
	if is_instance_valid(player_ref):
		recoil_direction = global_position - player_ref.global_position
	CombatSpriteFeedback.play_hit(visual_root, recoil_direction, 1.15)
	
	if is_crit:
		if AudioManager: AudioManager.play_sfx("crit_hit")
	else:
		if AudioManager: AudioManager.play_sfx("boss_hit")
		
	if hp <= 0.0:
		_on_boss_death()

func _claim_boss_defeat() -> bool:
	if is_dead:
		return false
	is_dead = true
	return true

func _on_boss_death() -> void:
	if not _claim_boss_defeat():
		return
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_impact"):
		cam.apply_impact(10.0, 0.5)
		
	# Award floor victory rewards
	if SaveManager:
		SaveManager.record_daily_mission_progress("enemy_slayer", 1)
		SaveManager.record_daily_mission_progress("boss_hunter", 1)
		SaveManager.record_achievement_progress("abyssal_slayer", 1)
		SaveManager.record_achievement_progress("lord_breaker", 1)
	GameManager.add_run_shades(15)
	
	# Spawn boss gold shower
	for i in range(10):
		var coin = CoinPickupClass.new()
		get_parent().call_deferred("add_child", coin)
		coin.setup(6, global_position + Vector2(randf_range(-30, 30), randf_range(-20, 20)))
		
	# Spawn boss celestial XP crystals
	for i in range(3):
		var xp_crystal = XpPickupClass.new()
		get_parent().call_deferred("add_child", xp_crystal)
		xp_crystal.setup(50.0, global_position + Vector2(randf_range(-40, 40), randf_range(-30, 30)))
		
	boss_defeated.emit()
	GameManager.complete_current_level()
	
	# Dramatic boss dissolve is visual-only; rewards and level completion already fired above.
	var death_tween := CombatSpriteFeedback.play_death(
		visual_root,
		0.7,
		Vector2(1.3, 1.3),
		Vector2(0.1, 0.1)
	)
	if death_tween:
		death_tween.finished.connect(queue_free)
