class_name MainMenu
extends Control

# Main Menu controller for Abyssal Altar.
# Cohesive dark-fantasy UI presentation with tower background, logo treatment,
# Continue button for active runs, character selection, sanctuary, settings, and version info.

signal play_pressed()
signal continue_pressed()
signal characters_pressed()
signal sanctuary_pressed()
signal prologue_pressed()
signal settings_pressed()

@export var logo_rect: TextureRect
@export var btn_continue: Button
@export var btn_play: Button
@export var btn_characters: Button
@export var btn_sanctuary: Button
@export var btn_prologue: Button
@export var btn_settings: Button
@export var btn_quit: Button
@export var lbl_shades_quick: Label
@export var lbl_version: Label
@export var hero_pedestal: HeroPedestalView = null
@export var lbl_active_hero: Label = null

func _ready() -> void:
	_setup_signals()
	_refresh_state()
	
	visibility_changed.connect(func():
		if visible:
			_refresh_state()
	)

func _setup_signals() -> void:
	if btn_continue:
		btn_continue.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			continue_pressed.emit()
		)
	if btn_play:
		btn_play.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			play_pressed.emit()
		)
	if btn_characters:
		btn_characters.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			characters_pressed.emit()
		)
	if btn_sanctuary:
		btn_sanctuary.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			sanctuary_pressed.emit()
		)
	if btn_prologue:
		btn_prologue.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			prologue_pressed.emit()
		)
	if btn_settings:
		btn_settings.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			settings_pressed.emit()
		)
	if btn_quit:
		btn_quit.pressed.connect(func():
			get_tree().quit()
		)
		
	if SaveManager:
		SaveManager.shades_changed.connect(func(_s: int):
			_update_shades_label()
		)

func _refresh_state() -> void:
	if AudioManager:
		AudioManager.play_ambience(true)
		AudioManager.play_music("horror_menu")
		
	_update_shades_label()
	
	# Check if an ongoing run exists
	var has_run: bool = GameManager.is_in_run
	if btn_continue:
		btn_continue.visible = has_run
		if has_run:
			btn_continue.text = "RESUME RUN (FLOOR %d - L%d)" % [GameManager.floor_number, GameManager.level_number]
			
	# Update play button text
	if btn_play:
		btn_play.text = "NEW DESCENT" if has_run else "ENTER THE TOWER"
		
	if lbl_version:
		lbl_version.text = "Abyssal Altar v1.2.0 • Godot 4.3 Mobile"
		
	# Refresh Central Hero Display on Home Screen
	var char_id := "shadow_hunter"
	var char_name := "Shadow Hunter"
	if GameManager and GameManager.current_character:
		char_id = GameManager.current_character.id
		char_name = GameManager.current_character.name
	if hero_pedestal:
		hero_pedestal.character_id = char_id
	if lbl_active_hero:
		lbl_active_hero.text = "✦ %s ✦" % char_name.to_upper()

func _update_shades_label() -> void:
	if lbl_shades_quick and SaveManager:
		lbl_shades_quick.text = "◆ %d Shades Collected" % SaveManager.shades
