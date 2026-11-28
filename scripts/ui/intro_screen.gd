class_name IntroScreen
extends Control

# Cinematic opening splash screen for Dark Summoner: Abyssal Altar.
# Displays the Abyssal Tower splash keyart, dark-fantasy logo, loading seal bar,
# dynamic hunter status badge, and tap-to-enter interaction with safe tween lifecycles.

signal intro_completed()

@export var logo_rect: TextureRect
@export var subtitle_label: Label
@export var prompt_label: Label
@export var btn_skip: Button
@export var status_label: Label
@export var loading_bar: ProgressBar
@export var profile_pill_label: Label
@export var version_label: Label

var _has_proceeded: bool = false
var _entrance_tween: Tween = null
var _progress_tween: Tween = null
var _prompt_tween: Tween = null
var _pulse_tween: Tween = null


func _ready() -> void:
	if btn_skip and not btn_skip.pressed.is_connected(_on_proceed):
		btn_skip.pressed.connect(_on_proceed)

	_refresh_profile_badge()

	if AudioManager:
		AudioManager.play_ambience(true)
		AudioManager.play_music("none")

	_animate_entrance()
	_animate_loading_seal()
	_start_prompt_pulse()


func _exit_tree() -> void:
	_kill_active_tweens()


func _refresh_profile_badge() -> void:
	if profile_pill_label and SaveManager:
		var hunter_name: String = SaveManager.player_name if not SaveManager.player_name.is_empty() else "Hunter Raven"
		var hunter_lvl: int = maxi(1, int(SaveManager.player_level))
		profile_pill_label.text = "%s • Lv. %d • Online: Realm Abyss-1" % [hunter_name, hunter_lvl]
	if version_label:
		version_label.text = "DARK SUMMONER • v1.2.0"


func _kill_active_tweens() -> void:
	for tw in [_entrance_tween, _progress_tween, _prompt_tween, _pulse_tween]:
		if tw and is_instance_valid(tw):
			tw.kill()
	_entrance_tween = null
	_progress_tween = null
	_prompt_tween = null
	_pulse_tween = null


func _animate_entrance() -> void:
	if logo_rect:
		logo_rect.modulate.a = 0.0
		logo_rect.scale = Vector2(0.92, 0.92)
		logo_rect.pivot_offset = logo_rect.size * 0.5 if logo_rect.size != Vector2.ZERO else Vector2(230, 125)

	if subtitle_label:
		subtitle_label.modulate.a = 0.0

	_entrance_tween = create_tween()
	if logo_rect:
		_entrance_tween.tween_property(logo_rect, "modulate:a", 1.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_entrance_tween.parallel().tween_property(logo_rect, "scale", Vector2(1.0, 1.0), 0.95).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if subtitle_label:
		_entrance_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _animate_loading_seal() -> void:
	if not loading_bar:
		return
	loading_bar.value = 0.0
	if status_label:
		status_label.text = "UNSEALING THE ABYSSAL TOWER..."
	_progress_tween = create_tween()
	_progress_tween.tween_property(loading_bar, "value", 100.0, 1.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_progress_tween.tween_callback(func():
		if not is_instance_valid(self) or _has_proceeded:
			return
		if is_instance_valid(status_label):
			status_label.text = "THE ABYSSAL SEAL IS OPEN"
	)


func _start_prompt_pulse() -> void:
	if not prompt_label:
		return
	prompt_label.modulate.a = 0.0
	_prompt_tween = create_tween()
	_prompt_tween.tween_interval(0.55)
	_prompt_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.55)
	_prompt_tween.tween_callback(func():
		if not is_instance_valid(self) or not is_instance_valid(prompt_label) or _has_proceeded:
			return
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(prompt_label, "modulate:a", 0.42, 0.85).set_trans(Tween.TRANS_SINE)
		_pulse_tween.tween_property(prompt_label, "modulate:a", 1.0, 0.85).set_trans(Tween.TRANS_SINE)
	)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_proceed()
	elif event is InputEventScreenTouch and event.pressed:
		_on_proceed()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_on_proceed()


func skip_intro() -> void:
	_on_proceed()


func _on_proceed() -> void:
	if _has_proceeded:
		return
	_has_proceeded = true
	_kill_active_tweens()

	if AudioManager:
		AudioManager.play_sfx("ui_click")

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade.tween_callback(func():
		if not is_instance_valid(self):
			return
		intro_completed.emit()
	)
