class_name CharacterAnimationController
extends Node

# State-driven procedural animation controller for 2.5D chibi characters.
# Manages Idle, Run, 3-Stage Attack Combo, Active Skill, Hurt, Dodge, Defeat, and Victory.
# Supports full state interrupts (Dodge/Hurt/Defeat immediately cancel attack locks).

enum AnimState {
	IDLE,
	RUN,
	ATTACK,
	SKILL,
	HURT,
	DODGE,
	DEFEAT,
	VICTORY
}

signal state_changed(old_state: AnimState, new_state: AnimState)
signal combo_stage_executed(stage_index: int)
signal attack_completed()

var current_state: AnimState = AnimState.IDLE
var anim_time: float = 0.0

# Target node references
var sprite: Sprite2D
var weapon_socket: Marker2D
var weapon_sprite: Sprite2D

# Optional authored animation driver. When a matching AnimationPlayer clip exists,
# it owns the character rig; the existing procedural sprite animation remains fallback.
var authored_animation_player: AnimationPlayer
var authored_rig_root: Node2D
var authored_animation_active: bool = false
var animation_direction: String = "s"
var authored_animation_names: Dictionary = {
	"idle": "idle",
	"run": "run",
	"attack_1": "attack_1",
	"attack_2": "attack_2",
	"attack_3": "attack_3",
	"skill": "skill",
	"hurt": "hurt",
	"dodge": "dodge",
	"defeat": "defeat",
	"victory": "victory"
}

# Combo Tracking
var combo_stage: int = 0 # 0, 1, 2
var combo_reset_timer: float = 0.0
const COMBO_WINDOW: float = 0.9 # Seconds before combo resets to stage 0
var attack_anim_timer: float = 0.0
var attack_duration: float = 0.22

# State lock
var is_locked: bool = false
var hurt_timer: float = 0.0

# Base transforms for procedural offsets
var base_sprite_pos: Vector2 = Vector2(0, -6)
var base_sprite_scale: Vector2 = Vector2.ONE
var procedural_offset: Vector2 = Vector2.ZERO
var procedural_scale: Vector2 = Vector2.ONE
var procedural_rotation: float = 0.0

func setup(p_sprite: Sprite2D, p_socket: Marker2D = null, p_weapon_sprite: Sprite2D = null) -> void:
	sprite = p_sprite
	weapon_socket = p_socket
	weapon_sprite = p_weapon_sprite
	if sprite:
		base_sprite_pos = sprite.position
		base_sprite_scale = sprite.scale

# Bind an AnimationPlayer owned by the character visual rig. Clip names can be
# overridden per character; missing clips safely fall back to the legacy controller.
func bind_authored_animation_player(player: AnimationPlayer, clip_names: Dictionary = {}, rig_root: Node2D = null) -> void:
	authored_animation_player = player
	authored_rig_root = rig_root
	for key in clip_names:
		authored_animation_names[key] = str(clip_names[key])
	authored_animation_active = false
	_set_authored_visual_active(false)
	_play_authored_clip(_state_clip_name())

func _set_authored_visual_active(active: bool) -> void:
	authored_animation_active = active
	if is_instance_valid(authored_rig_root):
		authored_rig_root.visible = active
	if is_instance_valid(sprite):
		sprite.visible = not active

func _get_active_visual_target() -> CanvasItem:
	if authored_animation_active and is_instance_valid(authored_rig_root):
		return authored_rig_root
	if is_instance_valid(sprite):
		return sprite
	return null

func _state_clip_name() -> String:
	match current_state:
		AnimState.IDLE: return "idle"
		AnimState.RUN: return "run"
		AnimState.ATTACK: return "attack_1"
		AnimState.SKILL: return "skill"
		AnimState.HURT: return "hurt"
		AnimState.DODGE: return "dodge"
		AnimState.DEFEAT: return "defeat"
		AnimState.VICTORY: return "victory"
	return "idle"

func _resolve_authored_clip_name(clip_key: String) -> String:
	if not is_instance_valid(authored_animation_player):
		return ""
	var base_name := str(authored_animation_names.get(clip_key, clip_key))
	var directional_name := "%s_%s" % [base_name, animation_direction]
	if authored_animation_player.has_animation(directional_name):
		return directional_name
	return base_name if authored_animation_player.has_animation(base_name) else ""

func get_authored_clip_duration(clip_key: String) -> float:
	var animation_name := _resolve_authored_clip_name(clip_key)
	if animation_name.is_empty():
		return 0.0
	var animation := authored_animation_player.get_animation(animation_name)
	return animation.length if animation else 0.0

func _play_authored_clip(clip_key: String, force_restart: bool = false) -> bool:
	if not is_instance_valid(authored_animation_player):
		_set_authored_visual_active(false)
		return false

	var animation_name := _resolve_authored_clip_name(clip_key)
	if animation_name.is_empty():
		_set_authored_visual_active(false)
		return false
	if force_restart or authored_animation_player.current_animation != animation_name:
		authored_animation_player.play(animation_name)
	_set_authored_visual_active(true)
	return true

func _get_direction_suffix(direction: Vector2) -> String:
	if direction.length_squared() < 0.01:
		return animation_direction
	var angle := direction.angle()
	var octant := int(round(angle / (PI / 4.0)))
	match posmod(octant, 8):
		0: return "e"
		1: return "se"
		2: return "s"
		3: return "sw"
		4: return "w"
		5: return "nw"
		6: return "n"
		7: return "ne"
	return "s"

func update(delta: float, velocity: Vector2, aim_dir: Vector2, move_speed: float) -> void:
	anim_time += delta
	
	# Combo reset countdown
	if combo_reset_timer > 0.0:
		combo_reset_timer -= delta
		if combo_reset_timer <= 0.0:
			combo_stage = 0
			
	# Hurt recovery
	if hurt_timer > 0.0:
		hurt_timer -= delta
		if hurt_timer <= 0.0 and current_state == AnimState.HURT:
			is_locked = false
			_transition_to(AnimState.IDLE)
			
	# Attack recovery
	if current_state == AnimState.ATTACK:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			is_locked = false
			attack_completed.emit()
			_transition_to(AnimState.IDLE)

	# Track an eight-way facing direction for authored directional clips.
	# Directional locomotion clips can change while moving. One-shot actions keep
	# the direction captured when their trigger was called, preventing mid-swing flips.
	if current_state == AnimState.IDLE or current_state == AnimState.RUN:
		var direction_source := velocity if velocity.length_squared() > 100.0 else aim_dir
		var next_direction := _get_direction_suffix(direction_source)
		if next_direction != animation_direction:
			animation_direction = next_direction
			_play_authored_clip(_state_clip_name())

	# Facing logic
	if sprite and current_state != AnimState.DEFEAT:
		var face_left: bool = false
		if velocity.length_squared() > 100.0:
			face_left = velocity.x < 0.0
		elif aim_dir.length_squared() > 0.01:
			face_left = aim_dir.x < 0.0
		sprite.flip_h = face_left

	# Procedural animation is retained only when no authored clip is available.
	if not authored_animation_active:
		match current_state:
			AnimState.IDLE:
				_process_idle(delta)
			AnimState.RUN:
				_process_run(delta, velocity, move_speed)
			AnimState.ATTACK:
				_process_attack(delta)
			AnimState.SKILL:
				_process_skill(delta)
			AnimState.HURT:
				_process_hurt(delta)
			AnimState.DODGE:
				_process_dodge(delta, velocity)
			AnimState.DEFEAT:
				_process_defeat(delta)
			AnimState.VICTORY:
				_process_victory(delta)

	# Apply final transforms to sprite
	if sprite and not authored_animation_active:
		sprite.position = base_sprite_pos + procedural_offset
		sprite.scale = base_sprite_scale * procedural_scale
		sprite.rotation = procedural_rotation

func _process_idle(delta: float) -> void:
	# Breathing bob and slight organic squash/stretch
	var bob_y: float = sin(anim_time * 3.5) * 2.0
	procedural_offset = procedural_offset.move_toward(Vector2(0, bob_y), 40.0 * delta)
	
	var squash_y: float = 1.0 + sin(anim_time * 3.5) * 0.03
	var squash_x: float = 1.0 - sin(anim_time * 3.5) * 0.02
	procedural_scale = procedural_scale.move_toward(Vector2(squash_x, squash_y), 4.0 * delta)
	procedural_rotation = lerp_angle(procedural_rotation, 0.0, 10.0 * delta)

func _process_run(delta: float, velocity: Vector2, move_speed: float) -> void:
	# Stride bounce and dynamic running lean
	var stride_freq: float = 14.0 * clampf(velocity.length() / maxf(move_speed, 1.0), 0.5, 1.5)
	var stride_bounce: float = -abs(sin(anim_time * stride_freq)) * 4.0
	procedural_offset = Vector2(0, stride_bounce)
	
	var target_rot: float = (velocity.x / maxf(move_speed, 1.0)) * 0.14
	procedural_rotation = lerp_angle(procedural_rotation, target_rot, 14.0 * delta)
	
	# Running forward stretch
	procedural_scale = Vector2(0.96, 1.04)

func _process_attack(delta: float) -> void:
	# Smoothly return procedural offset and scale towards neutral
	procedural_offset = procedural_offset.move_toward(Vector2.ZERO, 50.0 * delta)
	procedural_scale = procedural_scale.move_toward(Vector2.ONE, 6.0 * delta)
	procedural_rotation = lerp_angle(procedural_rotation, 0.0, 12.0 * delta)

func _process_skill(delta: float) -> void:
	# Levitation pulse
	var float_y: float = sin(anim_time * 8.0) * 3.0 - 4.0
	procedural_offset = Vector2(0, float_y)
	procedural_scale = Vector2(1.1, 1.1)

func _process_hurt(delta: float) -> void:
	procedural_offset = procedural_offset.move_toward(Vector2.ZERO, 60.0 * delta)
	procedural_scale = procedural_scale.move_toward(Vector2.ONE, 8.0 * delta)

func _process_dodge(delta: float, velocity: Vector2) -> void:
	# Dash stretch in velocity direction
	if velocity.length_squared() > 10.0:
		procedural_scale = Vector2(1.25, 0.85)
	procedural_offset = procedural_offset.move_toward(Vector2.ZERO, 40.0 * delta)

func _process_defeat(delta: float) -> void:
	# Sink into ground and slump
	procedural_offset = procedural_offset.move_toward(Vector2(0, 8), 10.0 * delta)
	procedural_scale = procedural_scale.move_toward(Vector2(1.2, 0.4), 4.0 * delta)
	procedural_rotation = lerp_angle(procedural_rotation, 0.4, 5.0 * delta)

func _process_victory(delta: float) -> void:
	# Celebration jump bob
	var jump_y: float = -abs(sin(anim_time * 6.0)) * 12.0
	procedural_offset = Vector2(0, jump_y)
	procedural_scale = Vector2(1.05, 1.15) if jump_y < -4.0 else Vector2(1.15, 0.9)
	procedural_rotation = sin(anim_time * 6.0) * 0.1

# Transition handler
func _transition_to(new_state: AnimState) -> void:
	if current_state == new_state:
		return
	var old_state := current_state
	current_state = new_state
	_play_authored_clip(_state_clip_name())
	state_changed.emit(old_state, new_state)

# State triggers
func play_idle() -> void:
	if is_locked and current_state != AnimState.ATTACK:
		return
	_transition_to(AnimState.IDLE)

func play_run() -> void:
	if is_locked and current_state != AnimState.ATTACK:
		return
	_transition_to(AnimState.RUN)

func trigger_attack(aim_dir: Vector2, _attack_type: String = "slash") -> int:
	# Capture the attack facing before selecting its directional authored clip.
	animation_direction = _get_direction_suffix(aim_dir)
	# Immediately interrupt previous attack or idle/run
	_transition_to(AnimState.ATTACK)
	is_locked = true
	attack_duration = 0.20
	combo_reset_timer = COMBO_WINDOW
	
	var executed_stage: int = combo_stage
	combo_stage_executed.emit(executed_stage)
	
	# Execute 3-stage combo mechanics
	match executed_stage:
		0:
			# Combo Stage 1: Horizontal Cleave Swing
			procedural_offset = aim_dir * 8.0
			procedural_scale = Vector2(1.18, 0.88)
			procedural_rotation = 0.12 if not (sprite and sprite.flip_h) else -0.12
			if weapon_sprite:
				weapon_sprite.position = Vector2(10, -4)
				weapon_sprite.rotation = -0.5
				var tw := weapon_sprite.create_tween()
				tw.tween_property(weapon_sprite, "rotation", 0.6, 0.12).set_trans(Tween.TRANS_QUAD)
				tw.parallel().tween_property(weapon_sprite, "position", Vector2(4, 4), 0.12)
				tw.tween_property(weapon_sprite, "position", Vector2(2, 0), 0.08)
				tw.parallel().tween_property(weapon_sprite, "rotation", 0.0, 0.08)
			combo_stage = 1
			
		1:
			# Combo Stage 2: Reverse Uppercut Cross Slash
			procedural_offset = aim_dir * 10.0
			procedural_scale = Vector2(0.9, 1.2)
			procedural_rotation = -0.15 if not (sprite and sprite.flip_h) else 0.15
			if weapon_sprite:
				weapon_sprite.position = Vector2(6, 6)
				weapon_sprite.rotation = 0.7
				var tw := weapon_sprite.create_tween()
				tw.tween_property(weapon_sprite, "rotation", -0.7, 0.12).set_trans(Tween.TRANS_QUAD)
				tw.parallel().tween_property(weapon_sprite, "position", Vector2(8, -6), 0.12)
				tw.tween_property(weapon_sprite, "position", Vector2(2, 0), 0.08)
				tw.parallel().tween_property(weapon_sprite, "rotation", 0.0, 0.08)
			combo_stage = 2
			
		2:
			# Combo Stage 3: Heavy Forward Thrust & Piercing Lunge
			procedural_offset = aim_dir * 16.0
			procedural_scale = Vector2(1.3, 0.82)
			procedural_rotation = 0.0
			if weapon_sprite:
				weapon_sprite.position = Vector2(18, 0)
				weapon_sprite.scale = Vector2(0.28, 0.28)
				var tw := weapon_sprite.create_tween()
				tw.tween_property(weapon_sprite, "position", Vector2(2, 0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(weapon_sprite, "scale", Vector2(0.22, 0.22), 0.14)
			combo_stage = 0 # Cycle back
			
	var attack_clip_key := "attack_%d" % (executed_stage + 1)
	_play_authored_clip(attack_clip_key, true)
	attack_duration = maxf(0.20, get_authored_clip_duration(attack_clip_key))
	attack_anim_timer = attack_duration
	return executed_stage

func trigger_skill() -> void:
	_transition_to(AnimState.SKILL)
	_play_authored_clip("skill", true)
	is_locked = true
	var skill_duration := maxf(0.45, get_authored_clip_duration("skill"))
	var tw := create_tween()
	tw.tween_property(self, "procedural_scale", Vector2(1.25, 1.25), 0.2).set_trans(Tween.TRANS_BACK)
	tw.tween_property(self, "procedural_scale", Vector2.ONE, 0.25)
	if skill_duration > 0.45:
		tw.tween_interval(skill_duration - 0.45)
	tw.tween_callback(func():
		is_locked = false
		_transition_to(AnimState.IDLE)
	)

func trigger_hurt(hit_direction: Vector2 = Vector2.ZERO) -> void:
	# Hurt has high interrupt priority over attack!
	if hit_direction.length_squared() > 0.01:
		animation_direction = _get_direction_suffix(-hit_direction)
	_transition_to(AnimState.HURT)
	is_locked = true
	hurt_timer = maxf(0.16, get_authored_clip_duration("hurt"))
	
	# Recoil flinch backwards
	procedural_offset = -hit_direction * 10.0
	procedural_scale = Vector2(1.15, 0.85)
	
	var visual_target := _get_active_visual_target()
	if visual_target:
		var tw := visual_target.create_tween()
		visual_target.modulate = Color(2.0, 0.3, 0.3, 1.0)
		tw.tween_property(visual_target, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.16)

func trigger_dodge(dash_dir: Vector2) -> void:
	# Dodge cleanly cancels any attack lock immediately
	animation_direction = _get_direction_suffix(dash_dir)
	_transition_to(AnimState.DODGE)
	is_locked = true
	procedural_offset = dash_dir * 8.0
	procedural_scale = Vector2(1.3, 0.75)
	
	var visual_target := _get_active_visual_target()
	if visual_target:
		var dodge_duration := maxf(0.22, get_authored_clip_duration("dodge"))
		var tw := visual_target.create_tween()
		visual_target.modulate.a = 0.4
		tw.tween_property(visual_target, "modulate:a", 1.0, 0.22)
		if dodge_duration > 0.22:
			tw.tween_interval(dodge_duration - 0.22)
		tw.tween_callback(func():
			is_locked = false
			_transition_to(AnimState.IDLE)
		)

func trigger_defeat() -> void:
	_transition_to(AnimState.DEFEAT)
	is_locked = true
	var visual_target := _get_active_visual_target()
	if visual_target:
		var tw := visual_target.create_tween()
		tw.tween_property(visual_target, "modulate", Color(0.4, 0.4, 0.5, 0.0), 0.8)

func trigger_victory() -> void:
	_transition_to(AnimState.VICTORY)
	is_locked = true
