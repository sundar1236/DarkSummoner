class_name IntroScreen
extends Control

# Cinematic opening intro screen for Abyssal Altar.
# Atmospheric dark tower chamber, ascending soul embers, smooth logo reveal,
# and clear tap-to-continue interaction with skip button.

signal intro_completed()

@export var logo_rect: TextureRect
@export var subtitle_label: Label
@export var prompt_label: Label
@export var btn_skip: Button

var _can_proceed: bool = true
var _has_proceeded: bool = false

func _ready() -> void:
	if btn_skip:
		btn_skip.pressed.connect(_on_proceed)

	if AudioManager:
		AudioManager.play_ambience(true)
		AudioManager.play_music("none")

	_animate_entrance()
	_start_prompt_pulse()

func _animate_entrance() -> void:
	if logo_rect:
		logo_rect.modulate.a = 0.0
		logo_rect.scale = Vector2(0.92, 0.92)
		logo_rect.pivot_offset = Vector2(250, 100)
		var tween := create_tween()
		tween.tween_property(logo_rect, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(logo_rect, "scale", Vector2(1.0, 1.0), 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_prompt_pulse() -> void:
	if not prompt_label: return
	prompt_label.modulate.a = 1.0
	var pulse := create_tween().set_loops()
	pulse.tween_property(prompt_label, "modulate:a", 0.35, 0.7).set_trans(Tween.TRANS_SINE)
	pulse.tween_property(prompt_label, "modulate:a", 1.0, 0.7).set_trans(Tween.TRANS_SINE)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_proceed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_proceed()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_on_proceed()

func _on_proceed() -> void:
	if _has_proceeded:
		return
	_has_proceeded = true
	
	if AudioManager:
		AudioManager.play_sfx("ui_click")
		
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade.tween_callback(func():
		intro_completed.emit()
	)
