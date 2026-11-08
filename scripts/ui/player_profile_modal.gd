class_name PlayerProfileModal
extends Control

signal closed()

@export var lbl_name: Label
@export var lbl_level: Label
@export var lbl_power: Label
@export var lbl_floor: Label
@export var lbl_shades: Label
@export var lbl_champions: Label
@export var btn_close: Button

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			visible = false
			closed.emit()
		)
	refresh_modal()

func open_modal() -> void:
	visible = true
	refresh_modal()
	if AudioManager: AudioManager.play_sfx("ui_click")

func refresh_modal() -> void:
	if not SaveManager: return
	if lbl_name: lbl_name.text = SaveManager.player_name
	if lbl_level: lbl_level.text = "Account Level %d" % SaveManager.player_level
	if lbl_power: lbl_power.text = "⚔ Combat Power: %d" % SaveManager.calculate_combat_power()
	if lbl_floor: lbl_floor.text = "Deepest Floor Reached: Floor %d" % SaveManager.highest_floor_unlocked
	if lbl_shades: lbl_shades.text = "Total Shades Harvested: %d" % SaveManager.shades
	if lbl_champions: lbl_champions.text = "Unlocked Champions: %d / 4" % SaveManager.unlocked_characters.size()
