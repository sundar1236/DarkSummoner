class_name EnemyController
extends CharacterBody2D

# Unified 2.5D enemy controller for regular swarmers, ranged cultists, and elite brutes.

signal enemy_defeated(enemy_node: Node2D)

@export var enemy_type: String = "swarmer" # "swarmer", "cultist", "elite"
var max_hp: float = 45.0
var hp: float = 45.0
var move_speed: float = 140.0
var contact_damage: float = 12.0
var attack_cooldown: float = 1.4
var attack_timer: float = 0.0

var gold_reward: int = 4
var shade_reward: int = 1

var player_ref: Node2D
var shadow_sprite: Sprite2D
var sprite: Sprite2D
var health_bar: ProgressBar
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
			
	hp = max_hp
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = hp

func _physics_process(delta: float) -> void:
	anim_time += delta
	if not is_instance_valid(player_ref):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player_ref = p_nodes[0]
			
	_handle_burn(delta)
	
	if not is_instance_valid(player_ref):
		return
		
	var dist := global_position.distance_to(player_ref.global_position)
	var dir := (player_ref.global_position - global_position).normalized()
	
	attack_timer += delta
	
	# Horizontal Directional Facing
	if abs(dir.x) > 0.05:
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
			
			if attack_timer >= attack_cooldown:
				_fire_cultist_projectile(dir)
				attack_timer = 0.0
				
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

func _fire_cultist_projectile(dir: Vector2) -> void:
	# Casting windup animation pulse
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.2, 1.2), 0.15)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
	
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
	hp = maxf(0.0, hp - amount)
	if health_bar:
		health_bar.value = hp
		
	# Floating damage number
	var dmg_num := DamageNumber.new()
	get_parent().add_child(dmg_num)
	dmg_num.setup(amount, is_crit, global_position)
	
	# Hit flash & flinch
	var tween := create_tween()
	sprite.modulate = Color(1.8, 0.35, 0.35, 1.0)
	if is_crit:
		sprite.scale = Vector2(1.15, 1.15)
		tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	
	if is_crit:
		if AudioManager: AudioManager.play_sfx("crit_hit")
	else:
		if AudioManager: AudioManager.play_sfx("enemy_hit")
		
	if hp <= 0.0:
		_on_death()

func _on_death() -> void:
	GameManager.add_gold(gold_reward)
	GameManager.add_run_shades(shade_reward)
	if AudioManager:
		AudioManager.play_sfx("enemy_death")
	enemy_defeated.emit(self)
	
	# Death dissolve tween
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(0.1, 0.1), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(sprite, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
