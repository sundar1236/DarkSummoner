class_name SettingsModal
extends Control

# Pause, audio, and mobile visual-performance settings.

signal resume_requested()
signal inventory_requested()
signal abandon_run_requested()
signal main_menu_requested()

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

var btn_main_menu: Button = null
var is_confirming_abandon: bool = false
var _can_open_inventory: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_main_menu_button()
	_setup_signals()
	_load_current_values()

func set_context(can_open_inventory: bool) -> void:
	_can_open_inventory = can_open_inventory

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():
			_can_open_inventory = true
			return
		_load_current_values()
		_reset_confirm_state()
		var in_run: bool = GameManager and GameManager.is_in_run
		if btn_inventory:
			btn_inventory.visible = in_run and _can_open_inventory
		if btn_abandon:
			btn_abandon.visible = in_run
		if btn_main_menu:
			btn_main_menu.visible = not in_run
		if btn_resume:
			btn_resume.text = "RESUME" if in_run else "CLOSE"


func _ensure_main_menu_button() -> void:
	if btn_main_menu or not btn_resume or not btn_resume.get_parent():
		return
	var container := btn_resume.get_parent()
	btn_main_menu = container.get_node_or_null("BtnMainMenu") as Button
	if btn_main_menu:
		return
	btn_main_menu = Button.new()
	btn_main_menu.name = "BtnMainMenu"
	btn_main_menu.custom_minimum_size = Vector2(0, 46)
	btn_main_menu.text = "RETURN TO MAIN MENU"
	btn_main_menu.add_theme_font_size_override("font_size", 17)
	btn_main_menu.add_theme_color_override("font_color", Color(0.88, 0.9, 0.98, 1.0))
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.17, 0.25, 0.95)
	sb.border_color = Color(0.42, 0.46, 0.62, 0.85)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	btn_main_menu.add_theme_stylebox_override("normal", sb)
	btn_main_menu.add_theme_stylebox_override("hover", sb)
	btn_main_menu.add_theme_stylebox_override("pressed", sb)
	btn_main_menu.visible = false
	container.add_child(btn_main_menu)

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
	if btn_main_menu:
		btn_main_menu.pressed.connect(func():
			_reset_confirm_state()
			main_menu_requested.emit()
		)
		
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
		check_reduced_motion.toggled.connect(_on_reduced_motion_toggled)

func _on_reduced_motion_toggled(enabled: bool) -> void:
	if not SaveManager:
		return
	SaveManager.settings_data["reduced_motion"] = enabled
	for background in get_tree().get_nodes_in_group("arena_backgrounds"):
		if background.has_method("set_reduced_motion"):
			background.set_reduced_motion(enabled)
	SaveManager.save_profile()

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
