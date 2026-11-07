class_name CampaignScreen
extends Control

# Campaign World Hub (Screen A - Ref Image 2)
# Features 2.5D floating diorama island, chapter shield, sidebars,
# quick-access hunt rewards, and primary Start (x5 Energy) CTA.

signal start_run_requested()
signal hunt_clicked()
signal chest_clicked()
signal guild_clicked()
signal camp_clicked()
signal rumble_clicked()

@onready var island_container: Control = $IslandStage/DioramaIsland
@onready var chapter_label: Label = $IslandStage/ChapterHeader/ChapterShield/ChapterLabel
@onready var start_button: Button = $BottomControls/MainActionRow/StartButton
@onready var chat_label: Label = $BottomControls/ChatTicker/HBox/ChatLabel

var _t: float = 0.0
var current_chapter: int = 1
var is_cleared: bool = true
var _toast_label: Label = null

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	var btn_hunt := $BottomControls/QuickAccessRow/HuntBtn as Button
	if btn_hunt: btn_hunt.pressed.connect(_on_hunt_pressed)
	
	var btn_chest := $BottomControls/QuickAccessRow/ChestBtn as Button
	if btn_chest: btn_chest.pressed.connect(_on_chest_pressed)
	
	var btn_guild := $BottomControls/QuickAccessRow/GuildBtn as Button
	if btn_guild: btn_guild.pressed.connect(_on_guild_pressed)
	
	var btn_camp := $BottomControls/MainActionRow/CampBtn as Button
	if btn_camp: btn_camp.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		camp_clicked.emit()
	)
	
	var btn_rumble := $BottomControls/MainActionRow/RumbleBtn as Button
	if btn_rumble: btn_rumble.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		rumble_clicked.emit()
	)
	
	_setup_toast_label()

func _setup_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(400, 48)
	_toast_label.anchors_preset = PRESET_CENTER
	_toast_label.position = Vector2(160, 480)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	sb.border_color = Color(0.85, 0.72, 0.25, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	_toast_label.add_theme_stylebox_override("normal", sb)
	_toast_label.visible = false
	_toast_label.z_index = 50
	add_child(_toast_label)

func show_toast(text: String) -> void:
	if not _toast_label: return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _toast_label.visible = false)

func _on_start_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	# Deduct 5 energy from main shell if present
	var shell := get_parent().get_parent() as MainShellUI
	if shell and shell.top_bar:
		if not shell.top_bar.spend_energy(5):
			if AudioManager: AudioManager.play_sfx("ui_error")
			show_toast("Not enough Energy! (Need 5 ⚡)")
			return
	start_run_requested.emit()

func _on_hunt_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("shop_buy")
	var shell := get_parent().get_parent() as MainShellUI
	if shell and shell.top_bar:
		shell.top_bar.add_gold(2400)
	show_toast("🏆 Patrol Hunt Claimed! +2,400 Gold")
	hunt_clicked.emit()

func _on_chest_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("upgrade")
	var shell := get_parent().get_parent() as MainShellUI
	if shell and shell.top_bar:
		shell.top_bar.add_gold(500)
		shell.top_bar.add_gems(50)
	show_toast("🎁 Chapter 1 Chest Claimed! +500 🪙, +50 💎")
	chest_clicked.emit()

func _on_guild_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	show_toast("🛡 Guild Outpost: Unlocks at Chapter 3")
	guild_clicked.emit()

func _process(delta: float) -> void:
	_t += delta
	# Subtle floating bob on the central diorama island
	if island_container:
		island_container.position.y = sin(_t * 1.5) * 6.0
