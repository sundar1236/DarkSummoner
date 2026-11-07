class_name CollectibleScreen
extends Control

# Collectibles / Talent Cards Screen (Screen C - Ref Image 1)
# Features top pill toggle (Talent Cards | Artifact),
# 4-column scrollable grid of collectible cards with 1-5 yellow stars,
# title ribbons, and level-locked overlays.

signal tab_switched(is_talent_cards: bool)
signal card_clicked(card_id: String)

@onready var btn_talent_cards: Button = $SubNav/PillToggle/HBox/BtnTalentCards
@onready var btn_artifact: Button = $SubNav/PillToggle/HBox/BtnArtifact
@onready var grid_container: GridContainer = $ScrollContainer/CardGrid

var is_talent_mode: bool = true
var _toast_label: Label = null

func _ready() -> void:
	if btn_talent_cards:
		btn_talent_cards.pressed.connect(func(): _set_mode(true))
	if btn_artifact:
		btn_artifact.pressed.connect(func(): _set_mode(false))
	_setup_card_clicks()
	_setup_toast_label()
	_set_mode(true)

func _setup_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(460, 52)
	_toast_label.anchors_preset = PRESET_CENTER
	_toast_label.position = Vector2(130, 480)
	_toast_label.add_theme_font_size_override("font_size", 15)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.95)
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
	tw.tween_interval(2.0)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _toast_label.visible = false)

func _setup_card_clicks() -> void:
	if not grid_container: return
	var descriptions := [
		"👑 Glory (5★): +25% Gold Gain & +10% Crit Chance",
		"📜 Tactics (4★): +20% Skill Cooldown Recovery",
		"💨 Swift Wind (3★): +15% Movement Speed & Dash Distance",
		"💥 Super CRIT (4★): +40% Critical Strike Damage",
		"🛡 Iron Will (3★): +200 Max HP & 10% Damage Resistance",
		"🩸 Vampiric (3★): Defeating enemies heals 2% Max HP",
		"🔒 Storm Call: Unlocks after Lv.40 in Dungeon Descent!",
		"🔒 Flame Burst: Unlocks after Lv.40 in Dungeon Descent!"
	]
	
	for i in range(grid_container.get_child_count()):
		var card := grid_container.get_child(i) as Control
		var desc: String = descriptions[i] if i < descriptions.size() else "Talent Card"
		if card:
			card.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed:
					if AudioManager: AudioManager.play_sfx("ui_click")
					show_toast(desc)
					card_clicked.emit("card_%d" % (i + 1))
			)

func _set_mode(talent: bool) -> void:
	is_talent_mode = talent
	if AudioManager:
		AudioManager.play_sfx("ui_click")
		
	var active_col := Color(1.0, 0.88, 0.35, 1.0)
	var inactive_col := Color(0.65, 0.7, 0.8, 0.8)
	if btn_talent_cards:
		btn_talent_cards.add_theme_color_override("font_color", active_col if is_talent_mode else inactive_col)
	if btn_artifact:
		btn_artifact.add_theme_color_override("font_color", inactive_col if is_talent_mode else active_col)
		
	show_toast("Viewing: %s" % ("Talent Cards" if is_talent_mode else "Ancient Artifacts"))
	tab_switched.emit(is_talent_mode)
