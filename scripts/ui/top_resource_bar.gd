class_name TopResourceBar
extends Control

# Persistent Top Status Header across all meta-game screens.
# Displays Avatar, Level badge, Player Name, Combat Power counter,
# and 3 pill counters with '+' buttons for Energy/Stamina, Gold, and Gems.

signal energy_clicked()
signal gold_clicked()
signal gems_clicked()
signal avatar_clicked()

@onready var avatar_rect: TextureRect = $HeaderContent/LeftCluster/AvatarAnchor/AvatarFrame/AvatarIcon
@onready var level_label: Label = $HeaderContent/LeftCluster/AvatarAnchor/LevelBadge/LevelLabel
@onready var name_label: Label = $HeaderContent/LeftCluster/InfoCluster/PlayerNameLabel
@onready var power_label: Label = $HeaderContent/LeftCluster/InfoCluster/PowerPill/PowerLabel

@onready var energy_label: Label = $HeaderContent/RightCluster/EnergyPill/HBox/ValueLabel
@onready var gold_label: Label = $HeaderContent/RightCluster/GoldPill/HBox/ValueLabel
@onready var gems_label: Label = $HeaderContent/RightCluster/GemsPill/HBox/ValueLabel

var current_energy: int = 201
var max_energy: int = 36
var current_gold: int = 48250
var current_gems: int = 1280
var player_power: int = 14850
var player_level: int = 24

func _ready() -> void:
	custom_minimum_size = Vector2(0, 116)
	_setup_signals()
	refresh_display()
	if SaveManager:
		SaveManager.energy_changed.connect(func(_c, _m): refresh_display())
		SaveManager.gold_changed.connect(func(_val): refresh_display())
		SaveManager.gems_changed.connect(func(_val): refresh_display())
		SaveManager.shades_changed.connect(func(_val): refresh_display())
		SaveManager.profile_changed.connect(func(): refresh_display())
	if GameManager:
		GameManager.gold_changed.connect(func(_g): refresh_display())

func _setup_signals() -> void:
	var btn_energy := $HeaderContent/RightCluster/EnergyPill/HBox/PlusBtn as Button
	if btn_energy: btn_energy.pressed.connect(func(): energy_clicked.emit())
	
	var btn_gold := $HeaderContent/RightCluster/GoldPill/HBox/PlusBtn as Button
	if btn_gold: btn_gold.pressed.connect(func(): gold_clicked.emit())
	
	var btn_gems := $HeaderContent/RightCluster/GemsPill/HBox/PlusBtn as Button
	if btn_gems: btn_gems.pressed.connect(func(): gems_clicked.emit())
	
	var btn_avatar := $HeaderContent/LeftCluster/AvatarAnchor/AvatarBtn as Button
	if btn_avatar: btn_avatar.pressed.connect(func(): avatar_clicked.emit())

func refresh_display() -> void:
	var lvl: int = SaveManager.player_level if SaveManager else 5
	var p_name: String = SaveManager.player_name if SaveManager else "Hunter Raven"
	var power: int = SaveManager.calculate_combat_power() if SaveManager else 14850
	var cur_eng: int = SaveManager.energy if SaveManager else 45
	var max_eng: int = SaveManager.max_energy if SaveManager else 50
	var g: int = GameManager.run_gold if (GameManager and GameManager.is_in_run) else (SaveManager.profile_gold if SaveManager else 5000)
	var gem_val: int = SaveManager.gems if SaveManager else 150
	
	if level_label:
		level_label.text = "%d" % lvl
	if name_label:
		name_label.text = p_name
	if power_label:
		power_label.text = "⚔ %s" % _format_number(power)
	if energy_label:
		energy_label.text = "%d/%d" % [cur_eng, max_eng]
	if gold_label:
		gold_label.text = _format_number(g)
	if gems_label:
		gems_label.text = _format_number(gem_val)

func spend_energy(amount: int) -> bool:
	if SaveManager:
		return SaveManager.spend_energy(amount)
	return true

func add_energy(amount: int) -> void:
	if SaveManager:
		SaveManager.add_energy(amount)

func spend_gold(amount: int) -> bool:
	if SaveManager:
		return SaveManager.spend_gold(amount)
	return true

func add_gold(amount: int) -> void:
	if SaveManager:
		SaveManager.add_gold(amount)

func spend_gems(amount: int) -> bool:
	if SaveManager:
		return SaveManager.spend_gems(amount)
	return true

func add_gems(amount: int) -> void:
	if SaveManager:
		SaveManager.add_gems(amount)

func _format_number(val: int) -> String:
	if val >= 1000000:
		return "%.1fM" % (float(val) / 1000000.0)
	elif val >= 1000:
		var thousands := val / 1000
		var remainder := val % 1000
		return "%d,%03d" % [thousands, remainder]
	return str(val)
