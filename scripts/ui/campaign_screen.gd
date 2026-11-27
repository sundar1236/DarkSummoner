class_name CampaignScreen
extends Control

# Campaign World Hub (Screen A - Ref Image 2)
# Features 2.5D floating diorama island, chapter shield, difficulty selector,
# real daily-task navigation, patrol rewards, and primary Start (x5 Energy) CTA.

signal start_run_requested()
signal insufficient_energy()
signal difficulty_changed(diff_name: String)
signal hunt_clicked()
signal camp_clicked()
signal daily_tasks_requested()
signal settings_requested()

@onready var island_container: Control = $IslandStage/DioramaIsland
@onready var chapter_label: Label = $IslandStage/ChapterHeader/ChapterShield/ChapterLabel
@onready var start_button: Button = $BottomControls/MainActionRow/StartButton

# Event Carousel
@onready var banner_trophy: Label = $TopBannerSection/EventBanner/HBox/Trophy
@onready var banner_title: Label = $TopBannerSection/EventBanner/HBox/VBox/Title
@onready var banner_subtitle: Label = $TopBannerSection/EventBanner/HBox/VBox/Subtitle
@onready var banner_dots: Label = $TopBannerSection/EventBanner/HBox.get_node_or_null("Dots")
@onready var banner_btn: Button = $TopBannerSection/EventBanner.get_node_or_null("BannerBtn")

# Difficulty Selector
@onready var btn_diff_normal: Button = $IslandStage/ChapterHeader.get_node_or_null("DifficultyHBox/BtnNormal")
@onready var btn_diff_hard: Button = $IslandStage/ChapterHeader.get_node_or_null("DifficultyHBox/BtnHard")
@onready var btn_diff_torment: Button = $IslandStage/ChapterHeader.get_node_or_null("DifficultyHBox/BtnTorment")

# Sidebars
@onready var btn_privilege: Button = $LeftSidebar/PrivilegeBtn
@onready var btn_great_value: Button = $LeftSidebar/GreatValueBtn
@onready var btn_rankings: Button = $LeftSidebar/RankingsBtn
@onready var btn_tasks: Button = $RightSidebar/TasksBtn
@onready var btn_friends: Button = $RightSidebar/FriendsBtn
@onready var btn_topup: Button = $RightSidebar/TopUpBtn

var _t: float = 0.0
var _diorama_base_y: float = 152.0
var current_chapter: int = 1
var is_cleared: bool = true
var _toast_label: Label = null


func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	var btn_hunt := $BottomControls/QuickAccessRow/HuntBtn as Button
	if btn_hunt: btn_hunt.pressed.connect(_on_hunt_pressed)
	
	var btn_chest := $BottomControls/QuickAccessRow/ChestBtn as Button
	if btn_chest:
		btn_chest.visible = false
		btn_chest.disabled = true

	var btn_guild := $BottomControls/QuickAccessRow/GuildBtn as Button
	if btn_guild:
		btn_guild.visible = false
		btn_guild.disabled = true

	var hunt_button := $BottomControls/QuickAccessRow/HuntBtn as Button
	if hunt_button:
		hunt_button.text = "Patrol Rewards"

	var chat_ticker := get_node_or_null("BottomControls/ChatTicker") as Control
	if chat_ticker:
		chat_ticker.visible = false

	var rumble_button := get_node_or_null("BottomControls/MainActionRow/RumbleBtn") as Button
	if rumble_button:
		rumble_button.visible = false
		rumble_button.disabled = true
	
	var btn_camp := $BottomControls/MainActionRow/CampBtn as Button
	if btn_camp: btn_camp.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		camp_clicked.emit()
	)
	
	_nest_difficulty_buttons_in_scroll()
	_refresh_stars_display()
	_setup_difficulty_buttons()
	_setup_event_banner()
	_setup_sidebar_buttons()
	_setup_toast_label()
	if island_container:
		_diorama_base_y = island_container.position.y

func _nest_difficulty_buttons_in_scroll() -> void:
	var scroll_bg := get_node_or_null("IslandStage/ChapterHeader/DifficultyScrollBg") as PanelContainer
	var diff_hbox := get_node_or_null("IslandStage/ChapterHeader/DifficultyHBox") as HBoxContainer
	if scroll_bg and diff_hbox and diff_hbox.get_parent() != scroll_bg:
		diff_hbox.get_parent().remove_child(diff_hbox)
		scroll_bg.add_child(diff_hbox)

func _refresh_stars_display() -> void:
	var stars_count: int = SaveManager.chapter_stars.get(current_chapter, 3) if SaveManager else 3
	var gold_star := TextureLoader.get_texture("res://assets/art/ui_campaign/star_gold_single.png")
	if not gold_star:
		gold_star = TextureLoader.get_texture("res://assets/art/ui_campaign/star_gold.png")
	for i in range(1, 4):
		var star_node := get_node_or_null("IslandStage/ChapterHeader/StarsIcons/Star%d" % i) as TextureRect
		if star_node:
			var earned := i <= stars_count
			star_node.texture = gold_star
			star_node.modulate = Color(1.0, 1.0, 1.0, 1.0) if earned else Color(0.42, 0.45, 0.54, 0.65)

func _setup_difficulty_buttons() -> void:
	if btn_diff_normal:
		btn_diff_normal.pressed.connect(func(): _select_difficulty("normal"))
	if btn_diff_hard:
		btn_diff_hard.pressed.connect(func(): _select_difficulty("hard"))
	if btn_diff_torment:
		btn_diff_torment.pressed.connect(func(): _select_difficulty("torment"))
		
	var active_diff := SaveManager.difficulty if SaveManager else "normal"
	_update_difficulty_visuals(active_diff)

func _select_difficulty(diff: String) -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	if SaveManager:
		SaveManager.set_difficulty(diff)
	_update_difficulty_visuals(diff)
	
	var enemy_hp_mult := 1.0
	var enemy_damage_mult := 1.0
	if diff == "hard":
		enemy_hp_mult = 1.5
		enemy_damage_mult = 1.25
	elif diff == "torment":
		enemy_hp_mult = 2.0
		enemy_damage_mult = 1.5
	show_toast("⚔ %s — Enemy HP x%.1f · Damage x%.2f" % [diff.capitalize(), enemy_hp_mult, enemy_damage_mult])
	difficulty_changed.emit(diff)

func _update_difficulty_visuals(active_diff: String) -> void:
	var active_col := Color(1.0, 0.94, 0.65, 1.0)
	var inactive_col := Color(0.75, 0.78, 0.85, 0.85)
	var diff_active_tex := TextureLoader.get_texture("res://assets/art/ui_campaign/diff_pill_active.png")
	var diff_idle_tex := TextureLoader.get_texture("res://assets/art/ui_campaign/diff_pill_idle.png")
	var active_sb: StyleBox
	if diff_active_tex:
		var sbt := StyleBoxTexture.new()
		sbt.texture = diff_active_tex
		sbt.texture_margin_left = 14.0
		sbt.texture_margin_right = 14.0
		sbt.texture_margin_top = 8.0
		sbt.texture_margin_bottom = 8.0
		active_sb = sbt
	else:
		var sbf := StyleBoxFlat.new()
		sbf.bg_color = Color(0.45, 0.34, 0.14, 0.92)
		sbf.border_color = Color(0.92, 0.76, 0.36, 0.98)
		sbf.set_border_width_all(2)
		sbf.set_corner_radius_all(18)
		active_sb = sbf
	var inactive_sb: StyleBox
	if diff_idle_tex:
		var sbi := StyleBoxTexture.new()
		sbi.texture = diff_idle_tex
		sbi.texture_margin_left = 14.0
		sbi.texture_margin_right = 14.0
		sbi.texture_margin_top = 8.0
		sbi.texture_margin_bottom = 8.0
		inactive_sb = sbi
	else:
		inactive_sb = StyleBoxEmpty.new()

	var pairs := [
		[btn_diff_normal, "normal"],
		[btn_diff_hard, "hard"],
		[btn_diff_torment, "torment"]
	]
	for pair in pairs:
		var btn: Button = pair[0]
		var diff_id: String = pair[1]
		if not btn:
			continue
		var is_act := (active_diff == diff_id)
		btn.add_theme_color_override("font_color", active_col if is_act else inactive_col)
		btn.add_theme_color_override("font_hover_color", active_col)
		var sb: StyleBox = active_sb if is_act else inactive_sb
		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)
		btn.add_theme_stylebox_override("focus", sb)

func _setup_event_banner() -> void:
	if banner_trophy:
		banner_trophy.text = "🏰"
	if banner_title:
		banner_title.text = "Tower Expedition"
	if banner_subtitle:
		banner_subtitle.text = "Clear five levels, defeat Lord Malakar, and unlock the next floor."
	if banner_dots:
		banner_dots.visible = false
	if banner_btn:
		banner_btn.visible = false

func _setup_sidebar_buttons() -> void:
	var left_sidebar := get_node_or_null("LeftSidebar") as Control
	if left_sidebar:
		left_sidebar.visible = false
	for placeholder in [btn_privilege, btn_great_value, btn_rankings, btn_friends]:
		if placeholder:
			placeholder.visible = false
			placeholder.disabled = true
	if btn_tasks:
		btn_tasks.tooltip_text = "Open daily missions and achievements"
		btn_tasks.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			daily_tasks_requested.emit()
		)
	if btn_topup:
		btn_topup.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			var shell = get_parent().get_parent() if get_parent() else null
			if shell and "nav_dock" in shell and shell.nav_dock:
				shell.nav_dock.select_tab(0)
			else:
				show_toast("💎 Opening Shop Treasury...")
		)
	var right_sidebar := get_node_or_null("RightSidebar") as Control
	if right_sidebar and not right_sidebar.get_node_or_null("SettingsBtn"):
		var settings_btn := Button.new()
		settings_btn.name = "SettingsBtn"
		settings_btn.text = "⚙ MENU"
		settings_btn.tooltip_text = "Audio settings and Main Menu"
		settings_btn.custom_minimum_size = Vector2(96, 48)
		settings_btn.add_theme_font_size_override("font_size", 14)
		settings_btn.add_theme_color_override("font_color", Color(0.95, 0.9, 0.72, 1.0))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.12, 0.20, 0.92)
		sb.border_color = Color(0.55, 0.50, 0.72, 0.85)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(10)
		settings_btn.add_theme_stylebox_override("normal", sb)
		settings_btn.add_theme_stylebox_override("hover", sb)
		settings_btn.add_theme_stylebox_override("pressed", sb)
		settings_btn.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			settings_requested.emit()
		)
		right_sidebar.add_child(settings_btn)

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
	var cur_e: int = SaveManager.energy if SaveManager else 50
	if cur_e < 5:
		if AudioManager: AudioManager.play_sfx("ui_error")
		show_toast("Not enough Energy! Need 5 ⚡ (Have %d)" % cur_e)
		insufficient_energy.emit()
		return
		
	if SaveManager:
		SaveManager.spend_energy(5)
	if AudioManager: AudioManager.play_sfx("ui_click")
	start_run_requested.emit()

func _on_hunt_pressed() -> void:
	if not SaveManager:
		show_toast("Patrol rewards are unavailable.")
		return
	var claimed: Dictionary = SaveManager.claim_patrol_rewards()
	if not bool(claimed.get("ready", false)):
		var remaining: int = int(claimed.get("seconds_remaining", 0))
		var hours: int = remaining / 3600
		var minutes: int = (remaining % 3600) / 60
		show_toast("Patrol rewards ready in %02d:%02d" % [hours, minutes])
		return
	if AudioManager: AudioManager.play_sfx("shop_buy")
	show_toast("🏆 Patrol Rewards Claimed! +%d Gold" % int(claimed.get("gold", 0)))
	hunt_clicked.emit()

func _process(delta: float) -> void:
	_t += delta
	if island_container:
		island_container.position.y = _diorama_base_y + sin(_t * 1.5) * 5.0
