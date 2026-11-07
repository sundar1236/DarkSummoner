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
	custom_minimum_size = Vector2(0, 96)
	_setup_signals()
	refresh_display()
	if SaveManager:
		SaveManager.shades_changed.connect(func(_val): refresh_display())

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
	if level_label:
		level_label.text = "%d" % player_level
	if name_label:
		name_label.text = "Shadow Slayer"
	if power_label:
		power_label.text = "⚔ %s" % _format_number(player_power)
	if energy_label:
		energy_label.text = "%d/%d" % [current_energy, max_energy]
	if gold_label:
		var g := GameManager.run_gold if GameManager and GameManager.is_in_run else current_gold
		gold_label.text = _format_number(g)
	if gems_label:
		var sh := SaveManager.shades if SaveManager else current_gems
		gems_label.text = _format_number(sh)

func spend_energy(amount: int) -> bool:
	if current_energy >= amount:
		current_energy -= amount
		refresh_display()
		return true
	return false

func add_energy(amount: int) -> void:
	current_energy += amount
	refresh_display()

func spend_gold(amount: int) -> bool:
	if current_gold >= amount:
		current_gold -= amount
		refresh_display()
		return true
	return false

func add_gold(amount: int) -> void:
	current_gold += amount
	refresh_display()

func spend_gems(amount: int) -> bool:
	if SaveManager and SaveManager.spend_shades(amount):
		current_gems = SaveManager.shades
		refresh_display()
		return true
	elif current_gems >= amount:
		current_gems -= amount
		refresh_display()
		return true
	return false

func add_gems(amount: int) -> void:
	if SaveManager:
		SaveManager.add_shades(amount)
		current_gems = SaveManager.shades
	else:
		current_gems += amount
	refresh_display()

func _format_number(val: int) -> String:
	if val >= 1000000:
		return "%.1fM" % (float(val) / 1000000.0)
	elif val >= 1000:
		var thousands := val / 1000
		var remainder := val % 1000
		return "%d,%03d" % [thousands, remainder]
	return str(val)
