class_name SettingsModal
extends Control

# Pause, audio, and mobile visual-performance settings.

signal resume_requested()
signal inventory_requested()
signal abandon_run_requested()

@export var slider_master: HSlider
@export var slider_music: HSlider
@export var slider_sfx: HSlider
@export var slider_ambience: HSlider
@export var check_mute: CheckBox
@export var check_screen_shake: CheckBox
@export var check_reduced_motion: CheckBox

@export var btn_resume: Button
@export var btn_inventory: Button
@export var btn_abandon: Button

var is_confirming_abandon: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_signals()
	_load_current_values()

func _setup_signals() -> void:
	if btn_resume:
		btn_resume.pressed.connect(func():
			_reset_confirm_state()
			resume_requested.emit()
		)
	if btn_inventory:
		btn_inventory.pressed.connect(func():
			_reset_confirm_state()
			inventory_requested.emit()
		)
	if btn_abandon:
		btn_abandon.pressed.connect(_on_abandon_clicked)
		
	if slider_master:
		slider_master.value_changed.connect(func(val: float):
			AudioManager.set_master_volume(val)
			SaveManager.save_profile()
		)
	if slider_music:
		slider_music.value_changed.connect(func(val: float):
			AudioManager.set_music_volume(val)
			SaveManager.save_profile()
		)
	if slider_sfx:
		slider_sfx.value_changed.connect(func(val: float):
			AudioManager.set_sfx_volume(val)
			SaveManager.save_profile()
		)
	if slider_ambience:
		slider_ambience.value_changed.connect(func(val: float):
			AudioManager.set_ambience_volume(val)
			SaveManager.save_profile()
		)
	if check_mute:
		check_mute.toggled.connect(func(toggled: bool):
			AudioManager.set_muted(toggled)
			SaveManager.save_profile()
		)
	if check_screen_shake:
		check_screen_shake.toggled.connect(func(enabled: bool):
			SaveManager.settings_data["screen_shake"] = enabled
			SaveManager.save_profile()
		)
	if check_reduced_motion:
		check_reduced_motion.toggled.connect(func(enabled: bool):
			SaveManager.settings_data["reduced_motion"] = enabled
			SaveManager.save_profile()
		)

func _on_abandon_clicked() -> void:
	if not is_confirming_abandon:
		is_confirming_abandon = true
		if btn_abandon:
			btn_abandon.text = "CONFIRM ABANDON? (Progress lost)"
			btn_abandon.modulate = Color(1.0, 0.4, 0.4)
		if AudioManager:
			AudioManager.play_sfx("ui_click")
	else:
		_reset_confirm_state()
		abandon_run_requested.emit()

func _reset_confirm_state() -> void:
	is_confirming_abandon = false
	if btn_abandon:
		btn_abandon.text = "RETURN TO CAMPAIGN"
		btn_abandon.modulate = Color(1.0, 1.0, 1.0)

func _load_current_values() -> void:
	if slider_master: slider_master.value = AudioManager.master_vol
	if slider_music: slider_music.value = AudioManager.music_vol
	if slider_sfx: slider_sfx.value = AudioManager.sfx_vol
	if slider_ambience: slider_ambience.value = AudioManager.ambience_vol
	if check_mute: check_mute.button_pressed = AudioManager.is_muted
	if check_screen_shake: check_screen_shake.button_pressed = bool(SaveManager.settings_data.get("screen_shake", true))
	if check_reduced_motion: check_reduced_motion.button_pressed = bool(SaveManager.settings_data.get("reduced_motion", false))
