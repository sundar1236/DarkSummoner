class_name PlayerController
extends CharacterBody2D

const CharacterAnimationControllerClass = preload("res://scripts/combat/character_animation_controller.gd")
const CharacterVisualContractClass = preload("res://scripts/combat/character_visual_contract.gd")
const OverheadHealthBarClass = preload("res://scripts/combat/overhead_health_bar.gd")

# Lone Hunter player controller for Abyssal Altar.
# Handles Archero 2-style stutter-step auto-aiming & movement, 3-stage combo attacks,
# state-driven 2.5D chibi animations, overhead floating health bar, weapon sockets,
# character-specific visual ambience (Shadow Hunter streaks, Storm Reaper lightning sparks,
# Soul Binder orbiting spirit companion), dodge shadow afterimages, and active skills.

signal skill_cooldown_updated(current: float, max_val: float)
signal dodge_cooldown_updated(current: float, max_val: float)

@export var move_joystick: VirtualJoystick

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

# Animation & Visual Subsystems
var anim_ctrl: CharacterAnimationController
var overhead_hp_bar: OverheadHealthBar
var anim_time: float = 0.0
var footstep_timer: float = 0.0

var visual_root: Node2D
var authored_rig_root: Node2D
var shadow_sprite: Sprite2D
var ground_ring: Node2D
var sprite: Sprite2D
var weapon_sprite: Sprite2D
var aim_indicator: Node2D
var pet_container: Node2D
var weapon_socket: Marker2D

# Character-Specific Visuals
var spirit_wisp: Node2D
var storm_sparks: Node2D
var combo_streak: int = 0
var combo_streak_timer: float = 0.0
var combo_streak_label: Label

func _ready() -> void:
	add_to_group("player")
	collision_layer = 1 # Layer 1: Player
	collision_mask = 2 | 8 | 16 # Enemy, EnemyProjectile, Walls
	
	_setup_visuals()
	_refresh_stats()
	_spawn_pets()
	
	GameManager.inventory_changed.connect(_on_inventory_changed)
	GameManager.player_hp_changed.connect(_on_player_hp_changed)
	GameManager.run_skill_applied.connect(func(_id, _lvl): _refresh_stats(); _spawn_pets())
	
	if overhead_hp_bar:
		overhead_hp_bar.set_health(GameManager.player_hp, GameManager.player_max_hp)

func _setup_visuals() -> void:
	# Keep presentation separate from the CharacterBody2D gameplay/collision root.
	# This container is the future host for Skeleton2D or authored sprite animations.
	visual_root = Node2D.new()
	visual_root.name = "CharacterVisualRoot"
	add_child(visual_root)
	
	# 1. Ground contact shadow (Archero 2 style soft oval shadow)
	shadow_sprite = Sprite2D.new()
	shadow_sprite.texture = TextureLoader.get_texture("res://assets/sprites/vfx/ground_shadow.png")
	shadow_sprite.position = Vector2(0, 22)
	shadow_sprite.scale = Vector2(1.15, 1.15)
	shadow_sprite.modulate = Color(1.0, 1.0, 1.0, 0.78)
	shadow_sprite.z_index = -2
	visual_root.add_child(shadow_sprite)
	
	# 2. Ground subtle hero indicator ring
	ground_ring = Node2D.new()
	ground_ring.z_index = -1
	ground_ring.draw.connect(_draw_ground_ring)
	visual_root.add_child(ground_ring)
	
	# 3. Main Character Sprite
	sprite = Sprite2D.new()
	_update_character_sprite()
	sprite.position = Vector2(0, -6)
	sprite.scale = Vector2(0.44, 0.44)
	visual_root.add_child(sprite)
	
	# 4. Collision shape
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	col.shape = shape
	add_child(col)
	
	# 5. Weapon socket for projectile/slash spawning
	weapon_socket = Marker2D.new()
	weapon_socket.position = Vector2(16, 0)
	visual_root.add_child(weapon_socket)
	
	weapon_sprite = Sprite2D.new()
	weapon_sprite.scale = Vector2(0.35, 0.35)
	weapon_sprite.position = Vector2(10, 0)
	weapon_sprite.visible = false # Hero sprite already holds dual glowing blades
	weapon_socket.add_child(weapon_sprite)
	
	# 6. Animation Controller
	anim_ctrl = CharacterAnimationControllerClass.new()
	visual_root.add_child(anim_ctrl)
	anim_ctrl.setup(sprite, weapon_socket, weapon_sprite)

	# Dedicated attachment point for the future layered/Skeleton2D character scene.
	# The legacy sprite remains visible until a valid authored clip is available.
	authored_rig_root = Node2D.new()
	authored_rig_root.name = "AuthoredRigRoot"
	authored_rig_root.visible = false
	visual_root.add_child(authored_rig_root)
	var authored_animation_player := AnimationPlayer.new()
	authored_animation_player.name = "AuthoredAnimationPlayer"
	authored_rig_root.add_child(authored_animation_player)
	anim_ctrl.bind_authored_animation_player(authored_animation_player, {}, authored_rig_root)

	# 7. Aim reticle indicator line
	aim_indicator = Node2D.new()
	aim_indicator.draw.connect(_draw_aim_reticle)
	visual_root.add_child(aim_indicator)
	
	# 8. Overhead floating health bar
	overhead_hp_bar = OverheadHealthBarClass.new()
	overhead_hp_bar.position = Vector2(0, -42)
	add_child(overhead_hp_bar)
	
	# 9. Combo streak badge label
	combo_streak_label = Label.new()
	combo_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	combo_streak_label.add_theme_font_size_override("font_size", 10)
	combo_streak_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	combo_streak_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	combo_streak_label.size = Vector2(80, 16)
	combo_streak_label.position = Vector2(-40, -58)
	combo_streak_label.visible = false
	combo_streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(combo_streak_label)
	
	# 10. Companions container
	pet_container = Node2D.new()
	add_child(pet_container)
	
	# 11. Character-Specific Ambience Nodes
	_setup_character_ambience()

# Installs a production character visual scene without replacing the gameplay body.
# The supplied scene must have an AnimationPlayer somewhere beneath its Node2D root.
func install_authored_visual(rig_scene: PackedScene, clip_names: Dictionary = {}) -> bool:
	if rig_scene == null or not is_instance_valid(visual_root) or not is_instance_valid(anim_ctrl):
		return false

	var rig_instance := rig_scene.instantiate()
	if not rig_instance is Node2D:
		rig_instance.free()
		push_warning("Authored character visual scene root must inherit Node2D.")
		return false

	var rig_root := rig_instance as Node2D
	var animation_player := rig_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var contract_issues: Array[String] = CharacterVisualContractClass.validate(rig_root, animation_player, clip_names)
	if not contract_issues.is_empty():
		rig_root.free()
		for issue in contract_issues:
			push_warning("Authored character visual rejected: %s" % issue)
		return false

	if is_instance_valid(authored_rig_root):
		authored_rig_root.free()
		authored_rig_root = null

	rig_root.name = "AuthoredRigRoot"
	rig_root.visible = false
	visual_root.add_child(rig_root)
	authored_rig_root = rig_root
	# Animation tracks resolve from the rig root regardless of where the player
	# sits inside the scene hierarchy.
	animation_player.root_node = animation_player.get_path_to(rig_root)
	anim_ctrl.bind_authored_animation_player(animation_player, clip_names, rig_root)
	return true

# Resolve a named attachment point from the active authored rig.
# Returns null while the legacy sprite fallback is active or when the socket is absent.
func get_authored_socket(socket_name: String) -> Node2D:
	if not is_instance_valid(authored_rig_root) or not anim_ctrl or not anim_ctrl.authored_animation_active:
		return null
	return CharacterVisualContractClass.find_socket(authored_rig_root, socket_name)


func _setup_character_ambience() -> void:
	var char_id := "shadow_hunter"
	if GameManager.current_character:
		char_id = GameManager.current_character.id
		
	# Clean up previous ambience
	if spirit_wisp:
		spirit_wisp.queue_free()
		spirit_wisp = null
	if storm_sparks:
		storm_sparks.queue_free()
		storm_sparks = null
		
	match char_id:
		"soul_binder":
			# Clearly visible floating spirit companion orbiting Soul Binder
			spirit_wisp = Node2D.new()
			spirit_wisp.z_index = 5
			spirit_wisp.draw.connect(_draw_spirit_wisp)
			visual_root.add_child(spirit_wisp)
		"storm_reaper":
			# Ambient electric crackle sparks for Storm Reaper
			storm_sparks = Node2D.new()
			storm_sparks.z_index = 4
			storm_sparks.draw.connect(_draw_storm_sparks)
			visual_root.add_child(storm_sparks)

func _draw_ground_ring() -> void:
	# Subtle hero circle indicator matching character primary color
	var col := Color(0.8, 0.4, 1.0, 0.4)
	if GameManager.current_character:
		col = Color(GameManager.current_character.primary_color.r, GameManager.current_character.primary_color.g, GameManager.current_character.primary_color.b, 0.35)
	ground_ring.draw_arc(Vector2(0, 22), 22.0, 0.0, TAU, 32, col, 1.5, true)

func _draw_spirit_wisp() -> void:
	if not spirit_wisp:
		return
	# Orbit around player at radius 36.0, height -16.0
	var orbit_angle := anim_time * 3.2
	var wisp_pos := Vector2(cos(orbit_angle) * 36.0, -16.0 + sin(orbit_angle) * 12.0)
	
	# Outer soft soul glow
	spirit_wisp.draw_circle(wisp_pos, 8.0, Color(0.2, 0.95, 0.6, 0.35))
	# Inner bright spirit core
	spirit_wisp.draw_circle(wisp_pos, 4.5, Color(0.5, 1.0, 0.8, 0.9))
	spirit_wisp.draw_circle(wisp_pos + Vector2(1, -1), 1.8, Color(1.0, 1.0, 1.0, 0.95))
	# Little ethereal tail
	var tail_pos := wisp_pos - Vector2(cos(orbit_angle + 0.3), sin(orbit_angle + 0.3)) * 6.0
	spirit_wisp.draw_circle(tail_pos, 2.5, Color(0.2, 0.9, 0.55, 0.4))

func _draw_storm_sparks() -> void:
	if not storm_sparks:
		return
	# Crackling intermittent cyan electric arcs around the storm armor
	var spark_cycle: float = fmod(anim_time * 6.0, 1.0)
	if spark_cycle < 0.4:
		var p1 := Vector2(randf_range(-14, 14), randf_range(-24, 6))
		var p2 := p1 + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		var p3 := p2 + Vector2(randf_range(-8, 8), randf_range(-8, 8))
		storm_sparks.draw_polyline([p1, p2, p3], Color(0.4, 0.9, 1.0, 0.85), 1.6)

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
		weapon_sprite.texture = TextureLoader.get_texture(weap_path)

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
	
	var cdr: float = stats.get("dodge_cdr", 0.0)
	dodge_cooldown = maxf(0.45, 1.3 * (1.0 - cdr))
	
	if GameManager.current_character:
		skill_cooldown = GameManager.current_character.active_skill_cooldown
	_update_character_sprite()
	_setup_character_ambience()

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

	var skill_stats := GameManager.get_player_effective_stats()
	if skill_stats.get("pet", false):
		var skill_pet := PetController.new()
		pet_container.add_child(skill_pet)
		skill_pet.target_offset = Vector2(offset_x, -35.0)
		skill_pet.setup("wolf", 15.0 + float(skill_stats.get("pet_damage", 0.0)), self)

func _on_inventory_changed() -> void:
	_refresh_stats()
	_spawn_pets()

func _on_player_hp_changed(curr: float, max_v: float) -> void:
	if overhead_hp_bar:
		overhead_hp_bar.set_health(curr, max_v)

func _physics_process(delta: float) -> void:
	anim_time += delta
	_handle_movement(delta)
	_handle_aim_and_attack(delta)
	_handle_animations(delta)
	_handle_cooldowns(delta)
	_handle_autonomous_projectiles(delta)
	_handle_combo_streak(delta)

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
	
	# Single-stick Archero controls: move while moving, auto-aim and attack when stationary.
	if is_moving:
		# Moving suppresses attack; hunter aims toward movement vector for intuitive tactical positioning
		if move_vec.length_squared() > 0.01:
			aim_direction = move_vec.normalized()
		elif velocity.length_squared() > 0.01:
			aim_direction = velocity.normalized()
		is_attacking = false
		# Prime the attack timer so as soon as movement stops, hunter immediately auto-fires
		attack_timer = minf(attack_timer + delta * 0.85, 1.0 / maxf(attack_rate, 0.5))
	else:
		# Stationary: Automatically lock onto nearest alive enemy in the arena and unleash continuous attacks
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
	# Shadow Hunter consecutive hits slightly accelerate firing speed
	var effective_attack_rate := attack_rate
	if combo_streak >= 3:
		effective_attack_rate *= (1.0 + float(combo_streak) * 0.05)
		
	var fire_interval: float = 1.0 / maxf(effective_attack_rate, 0.5)
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
			if "is_dead" in e and e.is_dead:
				continue
			if "hp" in e and e.hp <= 0.0:
				continue
			if "current_hp" in e and e.current_hp <= 0:
				continue
			var d_sq := global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				nearest = e
	return nearest

func _handle_animations(delta: float) -> void:
	var is_moving: bool = velocity.length_squared() > 100.0
	
	if anim_ctrl:
		if is_moving and not is_dodging:
			anim_ctrl.play_run()
		elif not is_dodging and not is_attacking and anim_ctrl.current_state != CharacterAnimationController.AnimState.ATTACK:
			anim_ctrl.play_idle()
		anim_ctrl.update(delta, velocity, aim_direction, current_speed)
		
	if spirit_wisp:
		spirit_wisp.queue_redraw()
	if storm_sparks:
		storm_sparks.queue_redraw()

func _handle_combo_streak(delta: float) -> void:
	if combo_streak_timer > 0.0:
		combo_streak_timer -= delta
		if combo_streak_timer <= 0.0:
			combo_streak = 0
			if combo_streak_label:
				combo_streak_label.visible = false

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
			
	# Trigger 3-stage combo via CharacterAnimationController
	var combo_stage: int = 0
	if anim_ctrl:
		combo_stage = anim_ctrl.trigger_attack(aim_direction, attack_type)
		
	# Combo stage scaling: Stage 2 (heavy thrust) deals +30% bonus damage
	if combo_stage == 2:
		final_dmg *= 1.30
		_trigger_camera_impact(2.0, 0.1)
		
	# Shadow Hunter consecutive streak tracking
	var char_id := "shadow_hunter"
	if GameManager.current_character:
		char_id = GameManager.current_character.id
	if char_id == "shadow_hunter":
		combo_streak = mini(combo_streak + 1, 10)
		combo_streak_timer = 1.4
		if combo_streak >= 2 and combo_streak_label:
			combo_streak_label.text = "COMBO x%d!" % combo_streak
			combo_streak_label.visible = true
			if combo_streak >= 4:
				_spawn_afterimage()
		
	# Slash crescent visual swing
	_spawn_slash_vfx(aim_direction, attack_type, combo_stage)
	if not ProjectileController.can_spawn_projectile():
		return
	var proj := ProjectileController.new()
	get_parent().add_child(proj)
	proj.global_position = weapon_socket.global_position
	
	var p_speed := 720.0 if attack_type == "lightning" else 600.0
	proj.setup(final_dmg, is_crit, aim_direction, p_speed, attack_type, true)
	
	if stats.get("burn_on_hit", false) or stats.get("synergies", {}).get("has_burn_on_hit", false):
		proj.has_burn = true
	if stats.get("life_steal", false) or stats.get("synergies", {}).get("has_life_steal", false):
		proj.has_life_steal = true
		
	# Spawn extra spread projectiles from Shadow Flurry or blessing skills
	var extra_projs: int = stats.get("extra_projectiles", 0)
	for i in range(extra_projs):
		var sign_mult := 1.0 if i % 2 == 0 else -1.0
		var spread_angle := (float(i / 2 + 1) * 0.18) * sign_mult
		var side_dir := aim_direction.rotated(spread_angle)
		if not ProjectileController.can_spawn_projectile():
			break
		var extra_proj := ProjectileController.new()
		get_parent().add_child(extra_proj)
		extra_proj.global_position = weapon_socket.global_position
		extra_proj.setup(final_dmg * 0.75, is_crit, side_dir, p_speed, attack_type, true)
		if proj.has_burn: extra_proj.has_burn = true
		if proj.has_life_steal: extra_proj.has_life_steal = true
		
	if AudioManager:
		AudioManager.play_sfx(sfx_name, 0.06)

func _spawn_slash_vfx(dir: Vector2, atk_type: String, stage_idx: int = 0) -> void:
	var slash := Sprite2D.new()
	slash.texture = TextureLoader.get_texture("res://assets/sprites/projectiles/proj_slash.png")
	slash.global_position = weapon_socket.global_position + dir * 10.0
	slash.rotation = dir.angle()
	
	# Combo stage visual variance
	var initial_scale := Vector2(0.65, 0.65)
	var target_scale := Vector2(1.3, 1.1)
	if stage_idx == 1:
		initial_scale = Vector2(0.7, -0.7) # Reverse mirrored swing
		target_scale = Vector2(1.35, -1.15)
	elif stage_idx == 2:
		initial_scale = Vector2(0.8, 0.8) # Heavy piercing thrust
		target_scale = Vector2(1.6, 1.25)
		
	slash.scale = initial_scale
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
	tw.tween_property(slash, "scale", target_scale, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(slash, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD)
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
	
	# Cleanly interrupt attack with dodge in animation controller
	if anim_ctrl:
		anim_ctrl.trigger_dodge(dash_dir)
		
	# Spawn initial shadow afterimage
	_spawn_afterimage()
	
	if AudioManager:
		AudioManager.play_sfx("dodge")
		
	get_tree().create_timer(dodge_duration).timeout.connect(func():
		is_dodging = false
		is_invulnerable = false
	)
	return true

func _spawn_afterimage() -> void:
	if SaveManager and bool(SaveManager.settings_data.get("reduced_motion", false)):
		return
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
		
	if anim_ctrl:
		anim_ctrl.trigger_skill()
		
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
				if not ProjectileController.can_spawn_projectile():
					break
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
				if not ProjectileController.can_spawn_projectile():
					break
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
	var stats: Dictionary = GameManager.get_player_effective_stats()

	# Auto soul missiles (Soul Urn)
	if syn.get("has_auto_projectile", false):
		soul_auto_timer += delta
		if soul_auto_timer >= 2.0:
			soul_auto_timer = 0.0
			if not ProjectileController.can_spawn_projectile():
				return
			var proj := ProjectileController.new()
			get_parent().add_child(proj)
			proj.global_position = global_position
			proj.setup(16.0, false, Vector2.RIGHT.rotated(randf() * TAU), 440.0, "soul", true)
			if AudioManager: AudioManager.play_sfx("proj_launch")

	# Storm Conduit, Thunder Tempest, and Storm Wolf automatically strike the nearest living target.
	if syn.get("has_storm_conduit", false) or syn.get("has_chain_lightning", false) or stats.get("chain_lightning", false):
		lightning_auto_timer += delta
		if lightning_auto_timer >= 2.5:
			lightning_auto_timer = 0.0
			var target := _find_nearest_enemy()
			if target:
				var dir := (target.global_position - global_position).normalized()
				if not ProjectileController.can_spawn_projectile():
					return
				var proj := ProjectileController.new()
				get_parent().add_child(proj)
				proj.global_position = global_position
				proj.setup(float(stats.get("atk", 20.0)) * 0.8, true, dir, 750.0, "lightning", true)

func take_player_damage(amount: float) -> void:
	if is_invulnerable or GameManager.player_hp <= 0:
		return
		
	GameManager.damage_player(amount)
	_trigger_camera_impact(5.5, 0.16)
	
	# Hurt interrupt in animation controller
	if anim_ctrl:
		anim_ctrl.trigger_hurt(aim_direction)
		
	# Combo streak reset on damage taken
	combo_streak = 0
	if combo_streak_label:
		combo_streak_label.visible = false
	
	if AudioManager:
		AudioManager.play_sfx("enemy_hit")

func trigger_victory() -> void:
	if anim_ctrl:
		anim_ctrl.trigger_victory()

func _trigger_camera_impact(intensity: float, duration: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam and cam.has_method("apply_impact"):
		cam.apply_impact(intensity, duration)
