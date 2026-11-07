class_name CombatHUD
extends Control

# Coordinates the Combat HUD elements: dual virtual sticks, action buttons,
# health bars, boss bars, cooldown indicators, and pause menu trigger.

signal pause_requested()

@export var move_joystick: VirtualJoystick
@export var aim_joystick: VirtualJoystick = null

@export var player_hp_bar: ProgressBar
@export var player_hp_label: Label
@export var floor_level_label: Label
@export var gold_label: Label
@export var shades_label: Label

@export var boss_bar: ProgressBar
@export var boss_label: Label

@export var btn_dodge: Button
@export var btn_skill: Button
@export var btn_potion: Button
@export var potion_count_label: Label
@export var btn_pause: Button
@export var btn_speed: Button = null
@export var xp_bar: ProgressBar = null
@export var xp_label: Label = null
@export var timer_label: Label = null
@export var wave_objective_label: Label = null
@export var revive_objective_label: Label = null

var player_ref: PlayerController
var battle_seconds: float = 0.0
var current_speed_scale: float = 1.0

func _process(delta: float) -> void:
	battle_seconds += delta
	if timer_label:
		var mins := int(battle_seconds) / 60
		var secs := int(battle_seconds) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]

func _ready() -> void:
	if btn_dodge:
		btn_dodge.icon = TextureLoader.get_texture("res://assets/art/ui/btn_dash.png")
		btn_dodge.expand_icon = true
	if btn_skill:
		btn_skill.icon = TextureLoader.get_texture("res://assets/art/ui/btn_skill.png")
		btn_skill.expand_icon = true
	if btn_potion:
		btn_potion.icon = TextureLoader.get_texture("res://assets/art/ui/btn_potion.png")
		btn_potion.expand_icon = true
		
	_connect_signals()
	_update_displays()

func setup(player: PlayerController) -> void:
	player_ref = player
	if is_instance_valid(player_ref):
		player_ref.move_joystick = move_joystick
		player_ref.dodge_cooldown_updated.connect(_on_dodge_cooldown)
		player_ref.skill_cooldown_updated.connect(_on_skill_cooldown)

func _connect_signals() -> void:
	if btn_dodge:
		btn_dodge.pressed.connect(_on_dodge_pressed)
	if btn_skill:
		btn_skill.pressed.connect(_on_skill_pressed)
	if btn_potion:
		btn_potion.pressed.connect(_on_potion_pressed)
	if btn_pause:
		btn_pause.pressed.connect(func(): pause_requested.emit())
	if btn_speed:
		btn_speed.pressed.connect(_on_speed_toggle)
		
	GameManager.player_hp_changed.connect(_on_hp_changed)
	GameManager.gold_changed.connect(func(g: int): if gold_label: gold_label.text = str(g))
	GameManager.run_shades_changed.connect(func(s: int): if shades_label: shades_label.text = str(s))
	GameManager.potion_count_changed.connect(func(p: int): if potion_count_label: potion_count_label.text = "x%d" % p)

func _update_displays() -> void:
	if floor_level_label:
		var lvl_str := "BOSS" if GameManager.level_number == 5 else ("Level %d" % GameManager.level_number)
		floor_level_label.text = "FLOOR %d — %s" % [GameManager.floor_number, lvl_str]
	if gold_label:
		gold_label.text = str(GameManager.run_gold)
	if shades_label:
		shades_label.text = str(GameManager.run_shades)
	if potion_count_label:
		potion_count_label.text = "x%d" % GameManager.potions
	_on_hp_changed(GameManager.player_hp, GameManager.player_max_hp)

func _on_speed_toggle() -> void:
	current_speed_scale = 2.0 if current_speed_scale == 1.0 else 1.0
	Engine.time_scale = current_speed_scale
	if btn_speed:
		btn_speed.text = "x%d" % int(current_speed_scale)
	if AudioManager:
		AudioManager.play_sfx("ui_click")

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _on_hp_changed(curr: float, max_v: float) -> void:
	if player_hp_bar:
		player_hp_bar.max_value = max_v
		var tween := create_tween()
		tween.tween_property(player_hp_bar, "value", curr, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if player_hp_label:
		player_hp_label.text = "%d / %d" % [int(curr), int(max_v)]

func _on_dodge_pressed() -> void:
	if is_instance_valid(player_ref):
		player_ref.trigger_dodge()

func _on_skill_pressed() -> void:
	if is_instance_valid(player_ref):
		player_ref.trigger_active_skill()

func _on_potion_pressed() -> void:
	GameManager.use_potion()

func _on_dodge_cooldown(current: float, max_v: float) -> void:
	if btn_dodge:
		if current > 0.0:
			btn_dodge.text = "%.1f" % current
			btn_dodge.disabled = true
		else:
			btn_dodge.text = ""
			btn_dodge.disabled = false

func _on_skill_cooldown(current: float, max_v: float) -> void:
	if btn_skill:
		if current > 0.0:
			btn_skill.text = "%.1f" % current
			btn_skill.disabled = true
		else:
			btn_skill.text = ""
			btn_skill.disabled = false
