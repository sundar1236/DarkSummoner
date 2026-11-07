class_name SettingsModal
extends Control

# Pause & Audio settings modal.
# Adjusts Master, Music, SFX, and Ambience buses, with mute toggle.

signal resume_requested()
signal inventory_requested()
signal abandon_run_requested()

@export var slider_master: HSlider
@export var slider_music: HSlider
@export var slider_sfx: HSlider
@export var slider_ambience: HSlider
@export var check_mute: CheckBox

@export var btn_resume: Button
@export var btn_inventory: Button
@export var btn_abandon: Button

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_signals()
	_load_current_values()

func _setup_signals() -> void:
	if btn_resume:
		btn_resume.pressed.connect(func(): resume_requested.emit())
	if btn_inventory:
		btn_inventory.pressed.connect(func(): inventory_requested.emit())
	if btn_abandon:
		btn_abandon.pressed.connect(func(): abandon_run_requested.emit())
		
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

func _load_current_values() -> void:
	if slider_master: slider_master.value = AudioManager.master_vol
	if slider_music: slider_music.value = AudioManager.music_vol
	if slider_sfx: slider_sfx.value = AudioManager.sfx_vol
	if slider_ambience: slider_ambience.value = AudioManager.ambience_vol
	if check_mute: check_mute.button_pressed = AudioManager.is_muted
