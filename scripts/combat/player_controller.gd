class_name PlayerController
extends CharacterBody2D

# Lone Hunter player controller for Abyssal Altar.
# Handles independent dual-stick movement and aim, continuous hold-to-attack firing,
# 2.5D character animations, weapon sockets, dodge shadow afterimages, active skills,
# and autonomous pet coordination.

signal skill_cooldown_updated(current: float, max_val: float)
signal dodge_cooldown_updated(current: float, max_val: float)

@export var move_joystick: VirtualJoystick
@export var aim_joystick: VirtualJoystick

var base_speed: float = 240.0
var current_speed: float = 240.0
var attack_rate: float = 2.2 # Attacks per sec
var attack_timer: float = 0.0

var aim_direction: Vector2 = Vector2.RIGHT
var is_attacking: bool = false

# Dodge State
var is_dodging: bool = false
var is_invulnerable: bool = false
var dodge_cooldown: float = 1.3
var dodge_timer: float = 0.0
var dodge_duration: float = 0.25
var dodge_speed_mult: float = 2.8
var afterimage_timer: float = 0.0

# Active Skill State
var skill_cooldown: float = 6.0
var skill_timer: float = 0.0

# Auto-projectile timers
var soul_auto_timer: float = 0.0
var lightning_auto_timer: float = 0.0

# Animation & Visuals
var anim_time: float = 0.0
var footstep_timer: float = 0.0
var attack_lurch_offset: Vector2 = Vector2.ZERO

var shadow_sprite: Sprite2D
var sprite: Sprite2D
var weapon_sprite: Sprite2D
var aim_indicator: Node2D
var pet_container: Node2D
var weapon_socket: Marker2D

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1 # Layer 1: Player
	collision_mask = 2 | 8 | 16 # Enemy, EnemyProjectile, Walls
	
	_setup_visuals()
	_refresh_stats()
	_spawn_pets()
	
	GameManager.inventory_changed.connect(_on_inventory_changed)

func _setup_visuals() -> void:
	# 1. Ground contact shadow (Archero 2 style soft oval shadow)
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = TextureLoader.get_texture("res://assets/sprites/vfx/ground_shadow.png")
	shadow_sprite.position = Vector2(0, 22)
	shadow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.75)
	shadow_sprite.z_index = -1
	add_child(shadow_sprite)
	
	# 2. Main Character Sprite
	sprite = Sprite2D.new()
	_update_character_sprite()
	sprite.position = Vector2(0, -6)
	add_child(sprite)
	
	# 3. Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)
	
	# 4. Weapon socket for projectile/slash spawning
	weapon_socket = Marker2D.new()
	weapon_socket.position = Vector2(16, 0)
	add_child(weapon_socket)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.scale = Vector2(0.22, 0.22)
	weapon_sprite.position = Vector2(2, 0)
	weapon_socket.add_child(weapon_sprite)
	
	# 5. Aim reticle indicator line
	aim_indicator = Node2D.new()
	aim_indicator.draw.connect(_draw_aim_reticle)
	add_child(aim_indicator)
	
	# 6. Companions container
	pet_container = Node2D.new()
	add_child(pet_container)

func _update_character_sprite() -> void:
	if not sprite:
		return
	var char_id := "shadow_hunter"
	if GameManager.current_character:
		char_id = GameManager.current_character.id
		
	var tex_path := "res://assets/sprites/characters/player_shadow_hunter.png"
	var weap_path := "res://assets/art/items/item_shadow_blade.png"
	match char_id:
		"storm_reaper":
			tex_path = "res://assets/sprites/characters/player_storm_reaper.png"
			weap_path = "res://assets/art/items/item_abyssal_scythe.png"
		"soul_binder":
			tex_path = "res://assets/sprites/characters/player_soul_binder.png"
			weap_path = "res://assets/art/items/item_lightning_orb.png"
		_:
			tex_path = "res://assets/sprites/characters/player_shadow_hunter.png"
			weap_path = "res://assets/art/items/item_shadow_blade.png"
			
	sprite.texture = TextureLoader.get_texture(tex_path)
	if weapon_sprite:
		weapon_sprite.texture = load(weap_path) as Texture2D

func _draw_aim_reticle() -> void:
	if not is_attacking:
		return
	# Sleek target lock reticle indicating auto-aim locked enemy
	var line_len := 46.0
	var col := Color(0.8, 0.4, 1.0, 0.65)
	if GameManager.current_character:
		col = Color(GameManager.current_character.primary_color.r, GameManager.current_character.primary_color.g, GameManager.current_character.primary_color.b, 0.75)
	aim_indicator.draw_line(Vector2(14, 0), Vector2(line_len, 0), col, 2.0)
	aim_indicator.draw_circle(Vector2(line_len, 0), 3.5, Color(1.0, 1.0, 1.0, 0.9))
	aim_indicator.draw_arc(Vector2(line_len, 0), 6.0, 0.0, TAU, 16, col, 1.5, true)

func _refresh_stats() -> void:
	var stats := GameManager.get_player_effective_stats()
	current_speed = stats.get("speed", 240.0)
	attack_rate = stats.get("attack_rate", 2.2)
	
	if GameManager.current_character:
		skill_cooldown = GameManager.current_character.active_skill_cooldown
	_update_character_sprite()

func _spawn_pets() -> void:
	for child in pet_container.get_children():
		child.queue_free()
		
	var synergies: Dictionary = GameManager.cached_synergies
	var pets: Array = synergies.get("pets", [])
	
	var offset_x: float = -50.0
	for p_info in pets:
		var pet := PetController.new()
		pet_container.add_child(pet)
		pet.target_offset = Vector2(offset_x, -35.0)
		pet.setup(p_info.get("id", "wolf"), p_info.get("damage", 12.0), self)
		offset_x += 100.0

func _on_inventory_changed() -> void:
	_refresh_stats()
	_spawn_pets()

func _physics_process(delta: float) -> void:
	anim_time += delta
	_handle_movement(delta)
	_handle_aim_and_attack(delta)
	_handle_animations(delta)
	_handle_cooldowns(delta)
	_handle_autonomous_projectiles(delta)

func _handle_movement(_delta: float) -> void:
	if is_dodging:
		move_and_slide()
		# Emit shadow afterimages during dash
		afterimage_timer += _delta
		if afterimage_timer >= 0.05:
			afterimage_timer = 0.0
			_spawn_afterimage()
		return
		
	var move_vec := Vector2.ZERO
	if move_joystick:
		move_vec = move_joystick.get_effective_movement()
		
	if move_vec.length_squared() > 0.01:
		velocity = move_vec * current_speed
		# Footstep sound sync
		footstep_timer += _delta
		if footstep_timer >= (0.28 * (240.0 / current_speed)):
			footstep_timer = 0.0
			if AudioManager:
				AudioManager.play_sfx("footstep", 0.1)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, current_speed * 10.0 * _delta)
		footstep_timer = 0.0
		
	move_and_slide()

func _handle_aim_and_attack(delta: float) -> void:
	var move_vec := Vector2.ZERO
	if move_joystick:
		move_vec = move_joystick.get_effective_movement()
		
	var is_moving: bool = move_vec.length_squared() > 0.04 or velocity.length_squared() > 100.0
	
	if is_moving:
		# Archero Stutter-Step Mechanic: Single joystick controls movement and orienting.
		# Moving suppresses attack; hunter must stop to shoot, making positioning tactical.
		if move_vec.length_squared() > 0.01:
			aim_direction = move_vec.normalized()
		elif velocity.length_squared() > 0.01:
			aim_direction = velocity.normalized()
		is_attacking = false
		# Prime the attack timer so as soon as movement stops, hunter immediately auto-fires
		attack_timer = minf(attack_timer + delta * 0.85, 1.0 / maxf(attack_rate, 0.5))
	else:
		# Stationary: Lock onto nearest alive enemy in the arena and auto-fire
		var target := _find_nearest_enemy()
		if target:
			var diff := target.global_position - global_position
			if diff.length_squared() > 1.0:
				aim_direction = diff.normalized()
			is_attacking = true
		else:
			is_attacking = false
			
	aim_indicator.rotation = aim_direction.angle()
	aim_indicator.queue_redraw()
	weapon_socket.position = aim_direction * 20.0
	weapon_socket.rotation = aim_direction.angle()
	
	# Attack continuous firing while stationary and targeting an enemy
	var fire_interval: float = 1.0 / maxf(attack_rate, 0.5)
	if is_attacking:
		attack_timer += delta
		if attack_timer >= fire_interval:
			_fire_basic_attack()
			attack_timer = 0.0

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist_sq: float = 1600.0 * 1600.0 # Full screen arena targeting
	for e in enemies:
		if is_instance_valid(e) and e is Node2D:
			if "current_hp" in e and e.current_hp <= 0:
				continue
			var d_sq := global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = e
	return nearest

func _handle_animations(delta: float) -> void:
	var is_moving: bool = velocity.length_squared() > 100.0
	
	# Directional Facing: Flip horizontally based on movement when running, or enemy aim when shooting
	var face_left: bool = (velocity.x < 0.0) if is_moving else (aim_direction.x < 0.0)
	sprite.flip_h = face_left
	
	if is_moving:
		# Dynamic running stride with forward lean
		var target_rot: float = (velocity.x / current_speed) * 0.12
		sprite.rotation = lerp_angle(sprite.rotation, target_rot, 12.0 * delta)
		var stride_bounce: float = abs(sin(anim_time * 14.0)) * 3.5
		sprite.position = Vector2(0, -6.0 - stride_bounce) + attack_lurch_offset
	else:
		# Idle breathing bob
		sprite.rotation = lerp_angle(sprite.rotation, 0.0, 10.0 * delta)
		var idle_bob: float = sin(anim_time * 3.5) * 1.8
		sprite.position = Vector2(0, -6.0 + idle_bob) + attack_lurch_offset

	# Decay attack recoil lurch smoothly
	attack_lurch_offset = attack_lurch_offset.move_toward(Vector2.ZERO, 50.0 * delta)

func _fire_basic_attack() -> void:
	var stats := GameManager.get_player_effective_stats()
	var base_dmg: float = stats.get("atk", 18.0)
	var crit_chance: float = stats.get("crit_chance", 0.15)
	
	var is_crit := randf() < crit_chance
	var final_dmg := base_dmg * (2.0 if is_crit else 1.0)
	
	var attack_type := "slash"
	var sfx_name := "shoot_slash"
	if GameManager.current_character:
		match GameManager.current_character.attack_type:
			"lightning_bolts":
				attack_type = "lightning"
				sfx_name = "shoot_lightning"
			"soul_missiles":
				attack_type = "soul"
				sfx_name = "shoot_soul"
			_:
				attack_type = "slash"
				sfx_name = "shoot_slash"
			
	# Attack recoil lurch in aim direction
	attack_lurch_offset = aim_direction * 6.0
	
	# Weapon sprite thrust/swing
	if weapon_sprite:
		weapon_sprite.position = Vector2(8, 0)
		var w_tw := weapon_sprite.create_tween()
		w_tw.tween_property(weapon_sprite, "position", Vector2(2, 0), 0.1).set_trans(Tween.TRANS_QUAD)
		
	# Slash crescent visual swing
	_spawn_slash_vfx(aim_direction, attack_type)
	
	var proj := ProjectileController.new()
	get_parent().add_child(proj)
	proj.global_position = weapon_socket.global_position
	
	var p_speed := 720.0 if attack_type == "lightning" else 600.0
	proj.setup(final_dmg, is_crit, aim_direction, p_speed, attack_type, true)
	
	if stats.get("synergies", {}).get("has_burn_on_hit", false):
		proj.has_burn = true
	if stats.get("synergies", {}).get("has_life_steal", false):
		proj.has_life_steal = true
		
	if AudioManager:
		AudioManager.play_sfx(sfx_name, 0.06)

func _spawn_slash_vfx(dir: Vector2, atk_type: String) -> void:
	var slash := Sprite2D.new()
	slash.texture = TextureLoader.get_texture("res://assets/sprites/projectiles/proj_slash.png")
	slash.global_position = weapon_socket.global_position + dir * 10.0
	slash.rotation = dir.angle()
	slash.scale = Vector2(0.65, 0.65)
	var col := Color(0.95, 0.75, 1.0, 0.85)
	match atk_type:
		"lightning":
			col = Color(0.4, 0.9, 1.0, 0.9)
		"soul":
			col = Color(0.3, 1.0, 0.65, 0.9)
		_:
			col = Color(0.95, 0.75, 1.0, 0.85)
	slash.modulate = col
	slash.z_index = 1
	get_parent().add_child(slash)
	
	var tw := slash.create_tween()
	tw.tween_property(slash, "scale", Vector2(1.3, 1.1), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(slash, "modulate:a", 0.0, 0.11).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(slash.queue_free)

func trigger_dodge() -> bool:
	if dodge_timer > 0.0 or is_dodging:
		return false
		
	is_dodging = true
	is_invulnerable = true
	dodge_timer = dodge_cooldown
	afterimage_timer = 0.0
	
	# Determine dash direction
	var dash_dir := velocity.normalized()
	if dash_dir.length_squared() < 0.01:
		dash_dir = aim_direction
	velocity = dash_dir * (current_speed * dodge_speed_mult)
	
	# Spawn initial shadow afterimage
	_spawn_afterimage()
	
	# Visual ghost flash
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.35, 0.08)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.16)
	
	if AudioManager:
		AudioManager.play_sfx("dodge")
		
	get_tree().create_timer(dodge_duration).timeout.connect(func():
		is_dodging = false
		is_invulnerable = false
	)
	return true

func _spawn_afterimage() -> void:
	if not sprite or not sprite.texture:
		return
	var afterimage := ShadowAfterimage.new()
	var tint := Color(0.65, 0.25, 1.0, 0.6)
	if GameManager.current_character:
		tint = Color(GameManager.current_character.primary_color.r, GameManager.current_character.primary_color.g, GameManager.current_character.primary_color.b, 0.65)
	afterimage.setup(sprite.texture, global_position + sprite.position, sprite.rotation, sprite.flip_h, tint)
	get_parent().add_child(afterimage)

func trigger_active_skill() -> bool:
	if skill_timer > 0.0:
		return false
		
	skill_timer = skill_cooldown
	if AudioManager:
		AudioManager.play_sfx("skill")
		
	var char_id := GameManager.current_character.id if GameManager.current_character else "shadow_hunter"
	var stats := GameManager.get_player_effective_stats()
	var atk: float = stats.get("atk", 20.0)
	
	# Impact feedback
	_trigger_camera_impact(4.0, 0.15)
	
	match char_id:
		"shadow_hunter":
			# Shadow Flurry: 8 piercing blades in 360 ring
			var count: int = 8
			for i in range(count):
				var angle := (TAU / float(count)) * float(i)
				var dir := Vector2.RIGHT.rotated(angle)
				var proj := ProjectileController.new()
				get_parent().add_child(proj)
				proj.global_position = global_position
				proj.setup(atk * 1.5, true, dir, 600.0, "slash", true)
			# Visual burst ring
			_spawn_afterimage()
				
		"storm_reaper":
			# Chain Lightning: Strike nearest enemy and chain up to 5 consecutive enemies!
			var enemies := get_tree().get_nodes_in_group("enemies")
			var valid_targets: Array[Node2D] = []
			for e in enemies:
				if is_instance_valid(e) and e is Node2D:
					valid_targets.append(e)
					
			valid_targets.sort_custom(func(a, b):
				return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
			)
			
			var chain_points: Array[Vector2] = [global_position]
			var chained_count: int = mini(5, valid_targets.size())
			for i in range(chained_count):
				var target: Node2D = valid_targets[i]
				chain_points.append(target.global_position)
				if target.has_method("take_damage"):
					target.take_damage(atk * 1.8, true)
					
			if chain_points.size() > 1:
				var vfx := ChainLightningVFX.new()
				get_parent().add_child(vfx)
				vfx.setup(chain_points)
				if AudioManager: AudioManager.play_sfx("lightning_zap")
				
		"soul_binder":
			# Soul Swarm: Spawns summoning circle decal & 6 homing soul spirits
			_spawn_summon_circle()
			if AudioManager: AudioManager.play_sfx("summon_chime")
			for i in range(6):
				var angle := randf() * TAU
				var dir := Vector2.RIGHT.rotated(angle)
				var proj := ProjectileController.new()
				get_parent().add_child(proj)
				proj.global_position = global_position
				proj.setup(atk * 1.3, false, dir, 460.0, "soul", true)
				proj.is_homing = true
				
	return true

func _spawn_summon_circle() -> void:
	var circle := Sprite2D.new()
	circle.texture = TextureLoader.get_texture("res://assets/sprites/vfx/summon_circle.png")
	circle.global_position = global_position + Vector2(0, 10)
	circle.z_index = -1
	circle.modulate = Color(0.2, 0.9, 0.6, 0.8)
	get_parent().add_child(circle)
	
	var tween := circle.create_tween()
	tween.tween_property(circle, "scale", Vector2(1.3, 1.3), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(circle, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(circle.queue_free)

func _handle_cooldowns(delta: float) -> void:
	if dodge_timer > 0.0:
		dodge_timer = maxf(0.0, dodge_timer - delta)
		dodge_cooldown_updated.emit(dodge_timer, dodge_cooldown)
		
	if skill_timer > 0.0:
		skill_timer = maxf(0.0, skill_timer - delta)
		skill_cooldown_updated.emit(skill_timer, skill_cooldown)

func _handle_autonomous_projectiles(delta: float) -> void:
	var syn: Dictionary = GameManager.cached_synergies
	
	# Auto soul missiles (Soul Urn)
	if syn.get("has_auto_projectile", false):
		soul_auto_timer += delta
		if soul_auto_timer >= 2.0:
			soul_auto_timer = 0.0
			var proj := ProjectileController.new()
			get_parent().add_child(proj)
			proj.global_position = global_position
			proj.setup(16.0, false, Vector2.RIGHT.rotated(randf() * TAU), 440.0, "soul", true)
			if AudioManager: AudioManager.play_sfx("proj_launch")
			
	# Storm Conduit electric discharge
	if syn.get("has_storm_conduit", false) or syn.get("has_chain_lightning", false):
		lightning_auto_timer += delta
		if lightning_auto_timer >= 2.5:
			lightning_auto_timer = 0.0
			var enemies := get_tree().get_nodes_in_group("enemies")
			if not enemies.is_empty():
				var target: Node2D = enemies.pick_random()
				if is_instance_valid(target):
					var dir := (target.global_position - global_position).normalized()
					var proj := ProjectileController.new()
					get_parent().add_child(proj)
					proj.global_position = global_position
					proj.setup(22.0, true, dir, 750.0, "lightning", true)

func take_player_damage(amount: float) -> void:
	if is_invulnerable or GameManager.player_hp <= 0:
		return
		
	GameManager.damage_player(amount)
	_trigger_camera_impact(5.5, 0.16)
	
	# Hit flash & flinch recoil
	var tween := create_tween()
	sprite.modulate = Color(1.8, 0.3, 0.3, 1.0)
	attack_lurch_offset = -aim_direction * 8.0
	tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.18)
	
	if AudioManager:
		AudioManager.play_sfx("enemy_hit")

func _trigger_camera_impact(intensity: float, duration: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_impact"):
		cam.apply_impact(intensity, duration)
