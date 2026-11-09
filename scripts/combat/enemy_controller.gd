class_name EnemyController
extends CharacterBody2D

const CoinPickupClass = preload("res://scripts/combat/coin_pickup.gd")
const XpPickupClass = preload("res://scripts/combat/xp_pickup.gd")

# Unified 2.5D enemy controller for swarmers, ranged cultists, charging hunters, and elite brutes.
# Features distinct telegraph indicators, elite visual auras, crisp hit-flashes, and coin drops.

signal enemy_defeated(enemy_node: Node2D)

@export var enemy_type: String = "swarmer" # "swarmer", "cultist", "charger", "elite"
var max_hp: float = 45.0
var hp: float = 45.0
var is_dead: bool = false
var move_speed: float = 140.0
var contact_damage: float = 12.0
var attack_cooldown: float = 1.4
var attack_timer: float = 0.0
var is_telegraphing: bool = false
var is_charging: bool = false
var charge_direction: Vector2 = Vector2.ZERO
var charge_timer: float = 0.0
var charge_speed: float = 430.0
var charge_hit_player: bool = false

var gold_reward: int = 4
var shade_reward: int = 1

var player_ref: Node2D
var shadow_sprite: Sprite2D
var sprite: Sprite2D
var health_bar: ProgressBar
var elite_aura: Node2D
var burn_stacks: int = 0
var burn_timer: float = 0.0

var anim_time: float = 0.0
var lunge_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2 # Layer 2: Enemy
	collision_mask = 1 | 4 | 16 # Player, PlayerProjectile, Walls
	
	_setup_visuals()
	_init_stats()

func _setup_visuals() -> void:
	# 1. Ground contact shadow
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = TextureLoader.get_texture("res://assets/sprites/vfx/ground_shadow.png")
	shadow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.7)
	shadow_sprite.z_index = -1
	add_child(shadow_sprite)
	
	# 2. Main Enemy Sprite
	sprite = Sprite2D.new()
	add_child(sprite)
	
	# 3. Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)
	
	# 4. Clean arched Health bar
	health_bar = ProgressBar.new()
	health_bar.show_percentage = false
	health_bar.size = Vector2(40, 5)
	health_bar.position = Vector2(-20, -28)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(health_bar)

func setup(p_type: String, p_floor: int) -> void:
	enemy_type = p_type
	_init_stats(p_floor)

func _init_stats(floor_scale: int = 1) -> void:
	var hp_mult := 1.0 + (float(floor_scale - 1) * 0.35)
	match enemy_type:
		"swarmer":
			max_hp = 35.0 * hp_mult
			move_speed = 150.0
			contact_damage = 10.0
			gold_reward = 3
			shade_reward = 1
			if shadow_sprite:
				shadow_sprite.position = Vector2(0, 16)
				shadow_sprite.scale = Vector2(0.8, 0.8)
			if sprite:
				sprite.texture = TextureLoader.get_texture("res://assets/sprites/enemies/enemy_swarmer.png")
				sprite.position = Vector2(0, -4)
		"cultist":
			max_hp = 45.0 * hp_mult
			move_speed = 100.0
			contact_damage = 8.0
			gold_reward = 5
			shade_reward = 1
			if shadow_sprite:
				shadow_sprite.position = Vector2(0, 20)
				shadow_sprite.scale = Vector2(0.9, 0.9)
			if sprite:
				sprite.texture = TextureLoader.get_texture("res://assets/sprites/enemies/enemy_cultist.png")
				sprite.position = Vector2(0, -6)
		"charger":
			max_hp = 70.0 * hp_mult
			move_speed = 105.0
			contact_damage = 20.0
			attack_cooldown = 3.2
			gold_reward = 7
			shade_reward = 2
			if shadow_sprite:
				shadow_sprite.position = Vector2(0, 18)
				shadow_sprite.scale = Vector2(1.0, 1.0)
			if sprite:
				sprite.texture = TextureLoader.get_texture("res://assets/sprites/enemies/enemy_swarmer.png")
				sprite.modulate = Color(1.0, 0.48, 0.32, 1.0)
				sprite.scale = Vector2(1.12, 1.12)
		"elite":
			max_hp = 140.0 * hp_mult
			move_speed = 85.0
			contact_damage = 22.0
			gold_reward = 15
			shade_reward = 4
			if shadow_sprite:
				shadow_sprite.position = Vector2(0, 26)
				shadow_sprite.scale = Vector2(1.4, 1.4)
			if sprite:
				sprite.texture = TextureLoader.get_texture("res://assets/sprites/enemies/enemy_elite.png")
				sprite.position = Vector2(0, -10)
			if health_bar:
				health_bar.size = Vector2(56, 7)
				health_bar.position = Vector2(-28, -42)
			_setup_elite_aura()
			
	hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func _setup_elite_aura() -> void:
	if elite_aura:
		return
	elite_aura = Node2D.new()
	elite_aura.z_index = -1
	elite_aura.draw.connect(func():
		# Glowing golden-red menacing ring beneath elite brute
		var r: float = 32.0 + sin(anim_time * 5.0) * 2.0
		elite_aura.draw_arc(Vector2(0, 20), r, 0.0, TAU, 32, Color(1.0, 0.75, 0.2, 0.65), 3.0)
		elite_aura.draw_circle(Vector2(0, 20), r * 0.95, Color(1.0, 0.3, 0.1, 0.12))
	)
	add_child(elite_aura)
	
	# Crown badge over elite health bar
	var crown := Label.new()
	crown.text = "👑 ELITE"
	crown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crown.add_theme_font_size_override("font_size", 10)
	crown.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	crown.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	crown.size = Vector2(60, 14)
	crown.position = Vector2(-30, -58)
	crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(crown)

func _physics_process(delta: float) -> void:
	anim_time += delta
	if elite_aura:
		elite_aura.queue_redraw()
		
	if not is_instance_valid(player_ref):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player_ref = p_nodes[0]
			
	_handle_burn(delta)
	if is_dead:
		return
	
	if not is_instance_valid(player_ref):
		return
		
	var dist := global_position.distance_to(player_ref.global_position)
	var dir := (player_ref.global_position - global_position).normalized()
	
	attack_timer += delta
	
	# Horizontal Directional Facing
	if abs(dir.x) > 0.05 and not is_telegraphing:
		sprite.flip_h = (dir.x < 0.0)
		
	match enemy_type:
		"swarmer":
			velocity = dir * move_speed
			move_and_slide()
			# Scuttling crawling bob
			sprite.rotation = sin(anim_time * 16.0) * 0.12
			sprite.position = Vector2(0, -4.0 + abs(sin(anim_time * 14.0)) * 2.5) + lunge_offset
			
			if dist < 34.0 and attack_timer >= attack_cooldown:
				_lunge_attack(dir)
				_deal_player_damage(contact_damage)
				attack_timer = 0.0
				
		"cultist":
			if not is_telegraphing:
				if dist > 220.0:
					velocity = dir * move_speed
				elif dist < 140.0:
					velocity = -dir * move_speed
				else:
					velocity = Vector2.ZERO
				move_and_slide()
			
			# Levitating hovering bob
			sprite.rotation = 0.0
			sprite.position = Vector2(0, -6.0 + sin(anim_time * 3.5) * 4.0) + lunge_offset
			
			if attack_timer >= attack_cooldown and not is_telegraphing:
				_telegraph_cultist_attack(dir)
				attack_timer = 0.0
				
		"charger":
			sprite.rotation = 0.0
			sprite.position = Vector2(0, -5.0 + abs(sin(anim_time * 9.0)) * 2.0) + lunge_offset
			if is_charging:
				velocity = charge_direction * charge_speed
				move_and_slide()
				charge_timer -= delta
				if not charge_hit_player and is_instance_valid(player_ref) and global_position.distance_to(player_ref.global_position) < 48.0:
					_deal_player_damage(contact_damage)
					charge_hit_player = true
					is_charging = false
					velocity = Vector2.ZERO
					attack_timer = 0.0
				elif charge_timer <= 0.0:
					is_charging = false
					velocity = Vector2.ZERO
					attack_timer = 0.0
			elif not is_telegraphing:
				if dist > 190.0:
					velocity = dir * move_speed
				else:
					velocity = Vector2.ZERO
				move_and_slide()
				if attack_timer >= attack_cooldown:
					_telegraph_charger(dir)
					attack_timer = 0.0
			else:
				velocity = Vector2.ZERO

		"elite":
			velocity = dir * move_speed
			move_and_slide()
			# Heavy tectonic stomping motion
			sprite.rotation = sin(anim_time * 8.0) * 0.06
			sprite.position = Vector2(0, -10.0 + abs(sin(anim_time * 8.0)) * 3.0) + lunge_offset
			
			if dist < 48.0 and attack_timer >= attack_cooldown:
				_lunge_attack(dir)
				_deal_player_damage(contact_damage)
				attack_timer = 0.0

	# Smoothly decay lunge offset
	lunge_offset = lunge_offset.move_toward(Vector2.ZERO, 60.0 * delta)

func _lunge_attack(dir: Vector2) -> void:
	lunge_offset = dir * 14.0

func _telegraph_cultist_attack(dir: Vector2) -> void:
	is_telegraphing = true
	velocity = Vector2.ZERO
	
	# Create telegraph warning lane
	var telegraph := Node2D.new()
	telegraph.z_index = -1
	telegraph.draw.connect(func():
		var col := Color(1.0, 0.25, 0.35, 0.65)
		telegraph.draw_line(Vector2.ZERO, dir * 260.0, col, 3.0)
		telegraph.draw_circle(dir * 260.0, 6.0, col)
	)
	add_child(telegraph)
	
	# Casting windup animation pulse
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.25, 1.25), 0.18)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.16)
	
	get_tree().create_timer(0.34).timeout.connect(func():
		if is_instance_valid(telegraph):
			telegraph.queue_free()
		is_telegraphing = false
		if is_instance_valid(self) and hp > 0.0:
			_fire_cultist_projectile(dir)
	)


func _telegraph_charger(dir: Vector2) -> void:
	if is_dead or is_telegraphing or is_charging:
		return
	is_telegraphing = true
	velocity = Vector2.ZERO
	charge_direction = dir.normalized()
	var warning := Node2D.new()
	warning.z_index = -1
	warning.draw.connect(func():
		warning.draw_line(Vector2.ZERO, charge_direction * 320.0, Color(1.0, 0.28, 0.18, 0.8), 5.0)
		warning.draw_circle(charge_direction * 320.0, 8.0, Color(1.0, 0.35, 0.2, 0.9))
	)
	add_child(warning)
	if AudioManager:
		AudioManager.play_sfx("boss_warning")
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.32, 0.82), 0.24)
	tween.tween_property(sprite, "scale", Vector2(1.12, 1.12), 0.2)
	get_tree().create_timer(0.55).timeout.connect(func():
		if is_instance_valid(warning):
			warning.queue_free()
		if is_dead or not is_inside_tree():
			return
		is_telegraphing = false
		is_charging = true
		charge_timer = 0.55
		charge_hit_player = false
		if AudioManager:
			AudioManager.play_sfx("proj_launch")
	)


func _fire_cultist_projectile(dir: Vector2) -> void:
	if not ProjectileController.can_spawn_projectile():
		return
	var proj := ProjectileController.new()
	get_parent().add_child(proj)
	proj.global_position = global_position
	proj.setup(12.0, false, dir, 320.0, "enemy", false)
	if AudioManager:
		AudioManager.play_sfx("proj_launch")

func _deal_player_damage(amount: float) -> void:
	if is_instance_valid(player_ref) and player_ref.has_method("take_player_damage"):
		player_ref.take_player_damage(amount)

func apply_burn(amount: float, duration: int) -> void:
	burn_stacks = max(burn_stacks, duration)
	take_damage(amount, false)

func _handle_burn(delta: float) -> void:
	if burn_stacks <= 0:
		return
	burn_timer += delta
	if burn_timer >= 1.0:
		burn_timer = 0.0
		burn_stacks -= 1
		take_damage(5.0, false)

func take_damage(amount: float, is_crit: bool) -> void:
	if is_dead or amount <= 0.0:
		return
	hp = maxf(0.0, hp - amount)
	if health_bar:
		health_bar.value = hp
		
	# Floating damage number
	var dmg_num := DamageNumber.new()
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_crit, global_position)
	
	# High-readability white hit flash & micro squash flinch
	var tween := create_tween()
	sprite.modulate = Color(2.5, 2.5, 2.5, 1.0)
	sprite.scale = Vector2(1.18, 0.88)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_QUAD)
	tween.parallel().tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.10)
	
	if is_crit:
		if AudioManager: AudioManager.play_sfx("crit_hit")
	else:
		if AudioManager: AudioManager.play_sfx("enemy_hit")
		
	if hp <= 0.0:
		_on_death()

func _on_death() -> void:
	if is_dead:
		return
	is_dead = true
	if SaveManager:
		SaveManager.record_daily_mission_progress("enemy_slayer", 1)
		SaveManager.record_achievement_progress("abyssal_slayer", 1)
	var player_stats: Dictionary = GameManager.get_player_effective_stats()
	var kill_heal: float = float(player_stats.get("hp_on_kill", 0.0))
	if kill_heal > 0.0:
		GameManager.heal_player(kill_heal)
	GameManager.add_run_shades(shade_reward)
	if AudioManager:
		AudioManager.play_sfx("enemy_death")
	enemy_defeated.emit(self)
	
	# Spawn collectible gold coins that pop and magnetize
	var coin_count := clampi(gold_reward, 1, 5)
	for i in range(coin_count):
		var coin = CoinPickupClass.new()
		get_parent().call_deferred("add_child", coin)
		coin.setup(int(ceil(float(gold_reward) / float(coin_count))), global_position)
		
	# Spawn collectible celestial XP soul crystals
	var xp_val: float = 25.0
	if enemy_type == "cultist": xp_val = 35.0
	elif enemy_type == "charger": xp_val = 50.0
	elif enemy_type == "elite": xp_val = 75.0
	var xp_crystal = XpPickupClass.new()
	get_parent().call_deferred("add_child", xp_crystal)
	xp_crystal.setup(xp_val, global_position)
	
	# Death dissolve tween
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
