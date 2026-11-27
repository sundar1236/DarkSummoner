class_name DirectionalSprite8
extends Node2D

# Renders an 8-directional split sprite strip (8 horizontal frames:
# 0=e, 1=se, 2=s, 3=sw, 4=w, 5=nw, 6=n, 7=ne) with smooth octant facing
# and responsive 2.5D procedural animation states.

const DIRECTION_NAMES: Array[String] = ["e", "se", "s", "sw", "w", "nw", "n", "ne"]

var sprite: Sprite2D
var current_direction_index: int = 2 # Default facing South (toward camera)
var current_direction_name: String = "s"
var base_scale: Vector2 = Vector2.ONE
var base_offset_y: float = 0.0
var is_loaded: bool = false
var _base_tint: Color = Color.WHITE
var _enraged: bool = false
var _anim_state: String = "idle"
var _attack_flash_timer: float = 0.0

func _init() -> void:
	sprite = Sprite2D.new()
	sprite.name = "Sprite8Dir"
	sprite.centered = true
	sprite.hframes = 8
	sprite.vframes = 1
	sprite.frame = current_direction_index
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)

func setup(strip_path: String, desired_height_px: float = 88.0, foot_offset_y: float = 20.0) -> bool:
	is_loaded = false
	if strip_path.is_empty():
		return false
	var tex := TextureLoader.get_texture(strip_path)
	if tex == null:
		return false

	var tex_h := maxf(float(tex.get_height()), 1.0)
	var s := desired_height_px / tex_h
	base_scale = Vector2(s, s)
	# Frames are foot-aligned at ~94% height; center sprite vertically above foot_offset_y.
	base_offset_y = foot_offset_y - (tex_h * 0.44 * s)

	sprite.texture = tex
	sprite.hframes = 8
	sprite.vframes = 1
	sprite.frame = current_direction_index
	sprite.scale = base_scale
	sprite.position = Vector2(0.0, base_offset_y)
	sprite.modulate = _resolved_tint()
	is_loaded = true
	return true

func set_facing_vector(dir: Vector2) -> void:
	if dir.length_squared() < 0.0025:
		return
	var octant := posmod(roundi(dir.angle() / (PI / 4.0)), 8)
	if octant != current_direction_index:
		current_direction_index = octant
		current_direction_name = DIRECTION_NAMES[octant]
		if is_instance_valid(sprite):
			sprite.frame = octant

func set_direction_name(dir_name: String) -> void:
	var idx := DIRECTION_NAMES.find(dir_name.to_lower())
	if idx < 0:
		return
	current_direction_index = idx
	current_direction_name = DIRECTION_NAMES[idx]
	if is_instance_valid(sprite):
		sprite.frame = idx

func set_tint(tint: Color) -> void:
	_base_tint = tint
	if is_instance_valid(sprite):
		sprite.modulate = _resolved_tint()

func set_enraged(enraged: bool) -> void:
	_enraged = enraged
	if is_instance_valid(sprite):
		sprite.modulate = _resolved_tint()

func trigger_attack_pulse() -> void:
	_attack_flash_timer = 0.16

func _resolved_tint() -> Color:
	if _enraged:
		return _base_tint * Color(1.28, 0.52, 0.48, 1.0)
	return _base_tint

func update_pose(state: String, anim_time: float, delta: float = 0.016, velocity: Vector2 = Vector2.ZERO) -> void:
	if not is_loaded or not is_instance_valid(sprite):
		return
	_anim_state = state
	if _attack_flash_timer > 0.0:
		_attack_flash_timer = maxf(0.0, _attack_flash_timer - delta)

	var bob_y := 0.0
	var sx := 1.0
	var sy := 1.0
	var rot := 0.0

	match state:
		"move", "run":
			var speed_factor := clampf(velocity.length() / 160.0, 0.7, 1.4) if velocity.length_squared() > 1.0 else 1.0
			var bounce := absf(sin(anim_time * 12.0 * speed_factor))
			bob_y = -bounce * 5.0
			sx = 0.96 + bounce * 0.05
			sy = 1.04 - bounce * 0.05
			rot = sin(anim_time * 12.0 * speed_factor) * 0.05
		"attack", "attack_1", "attack_2", "attack_3":
			var swing := sin(anim_time * 24.0)
			bob_y = -3.0 + swing * 2.0
			sx = 1.12
			sy = 0.92
			rot = swing * 0.09
		"skill":
			bob_y = -7.0 + sin(anim_time * 10.0) * 3.0
			sx = 1.08
			sy = 1.08
		"dodge":
			sx = 1.18
			sy = 0.86
		"hurt":
			sx = 0.90
			sy = 1.12
			rot = -0.10
		"defeat", "death":
			bob_y = 10.0
			sx = 1.18
			sy = 0.55
			rot = 0.35
		"victory":
			bob_y = -absf(sin(anim_time * 6.5)) * 10.0
			sx = 1.04
			sy = 1.06
		_:
			# Subtle living breathing idle
			var breath := sin(anim_time * 3.2)
			bob_y = breath * 1.8
			sx = 1.0 - breath * 0.02
			sy = 1.0 + breath * 0.025

	if _enraged:
		sx *= 1.08
		sy *= 1.08

	sprite.position = Vector2(0.0, base_offset_y + bob_y)
	sprite.scale = Vector2(base_scale.x * sx, base_scale.y * sy)
	sprite.rotation = rot
