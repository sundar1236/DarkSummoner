class_name CombatCamera
extends Camera2D

# 2.5D fixed arena camera centered permanently on the bounded 720x1280 combat field
# with subtle combat impact response and screen shake.

@export var target: Node2D
var shake_intensity: float = 0.0
var shake_timer: float = 0.0

const ARENA_CENTER := Vector2(360.0, 640.0)

func _ready() -> void:
	position_smoothing_enabled = false
	global_position = ARENA_CENTER
	limit_left = 0
	limit_top = 0
	limit_right = 720
	limit_bottom = 1280

func _process(delta: float) -> void:
	global_position = ARENA_CENTER
		
	if shake_timer > 0.0:
		shake_timer -= delta
		offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		offset = Vector2.ZERO

func apply_impact(intensity: float = 4.5, duration: float = 0.12) -> void:
	if SaveManager and (not bool(SaveManager.settings_data.get("screen_shake", true)) or bool(SaveManager.settings_data.get("reduced_motion", false))):
		shake_intensity = 0.0
		shake_timer = 0.0
		offset = Vector2.ZERO
		return
	shake_intensity = intensity
	shake_timer = duration

