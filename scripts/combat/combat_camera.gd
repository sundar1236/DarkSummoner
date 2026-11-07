class_name CombatCamera
extends Camera2D

# Smooth 2.5D tracking camera with subtle combat impact response and arena clamping.

@export var target: Node2D
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 6.0
	limit_left = 0
	limit_top = 0
	limit_right = 720
	limit_bottom = 1280

func _process(delta: float) -> void:
	if is_instance_valid(target):
		global_position = target.global_position
		
	if shake_timer > 0.0:
		shake_timer -= delta
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		offset = Vector2.ZERO

func apply_impact(intensity: float = 4.5, duration: float = 0.12) -> void:
	shake_intensity = intensity
	shake_timer = duration
