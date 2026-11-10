class_name PlayerProfileModal
extends Control

# Hunter Profile & Account Status Modal for Dark Summoner.
# Features weathered gothic iron frames, double gold borders, dark slate textures,
# 3D gold-and-ruby ritual sword icon, Combat Power banner, and progression stats.

signal closed()

@export var lbl_name: Label
@export var lbl_level: Label
@export var lbl_power: Label
@export var lbl_floor: Label
@export var lbl_shades: Label
@export var lbl_champions: Label
@export var btn_close: Button

@onready var backdrop: Control = $Backdrop
@onready var card: Control = $CenterContainer/Card
@onready var sword_texture: TextureRect = $CenterContainer/Card/VBox/HeaderIcon/SwordTexture

var _is_animating: bool = false

func _ready() -> void:
	if sword_texture:
		sword_texture.texture = TextureLoader.get_texture("res://assets/art/items/icon_ritual_sword.png")
		
	if btn_close:
		btn_close.pressed.connect(close_modal)
		
	if backdrop:
		backdrop.gui_input.connect(_on_backdrop_gui_input)
		
	refresh_modal()

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		close_modal()

func open_modal() -> void:
	if _is_animating: return
	visible = true
	refresh_modal()
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_click")
		
	if card:
		card.scale = Vector2.ONE
		card.modulate.a = 1.0

func close_modal() -> void:
	if _is_animating: return
	_is_animating = true
	
	if has_node("/root/AudioManager"):
		get_node("/root/AudioManager").play_sfx("ui_click")
		
	visible = false
	_is_animating = false
	closed.emit()

func refresh_modal() -> void:
	var p_name := SaveManager.player_name if SaveManager else "Hunter Raven"
	var p_level := SaveManager.player_level if SaveManager else 5
	var p_power := SaveManager.calculate_combat_power() if SaveManager else 42745
	var p_floor := SaveManager.highest_floor_unlocked if SaveManager and SaveManager.highest_floor_unlocked >= 2 else 2
	var p_shades := SaveManager.shades if SaveManager and SaveManager.shades > 0 else 3350
	var p_champions := SaveManager.unlocked_characters.size() if SaveManager else 1
	
	if lbl_name:
		lbl_name.text = p_name
	if lbl_level:
		lbl_level.text = "Account Level %d" % p_level
	if lbl_power:
		lbl_power.text = "⚔ Combat Power: %s" % _format_number(p_power)
	if lbl_floor:
		lbl_floor.text = "Deepest Floor Reached: Floor %d" % p_floor
	if lbl_shades:
		lbl_shades.text = "Total Shades Harvested: %s" % _format_number(p_shades)
	if lbl_champions:
		lbl_champions.text = "Unlocked Champions: %d / 4" % p_champions

func _format_number(value: int) -> String:
	var s := str(value)
	var formatted := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		formatted = s[i] + formatted
		count += 1
		if count % 3 == 0 and i > 0:
			formatted = "," + formatted
	return formatted
