class_name CampaignScreen
extends Control

# Campaign World Hub (Screen A - Ref Image 2)
# Features 2.5D floating diorama island, chapter shield, difficulty selector,
# interactive event carousel, sidebars, quick-access hunt rewards, and primary Start (x5 Energy) CTA.

signal start_run_requested()
signal insufficient_energy()
signal difficulty_changed(diff_name: String)
signal event_clicked(event_idx: int)
signal hunt_clicked()
signal chest_clicked()
signal guild_clicked()
signal camp_clicked()
signal rumble_clicked()

@onready var island_container: Control = $IslandStage/DioramaIsland
@onready var chapter_label: Label = $IslandStage/ChapterHeader/ChapterShield/ChapterLabel
@onready var start_button: Button = $BottomControls/MainActionRow/StartButton
@onready var chat_label: Label = $BottomControls/ChatTicker/HBox/ChatLabel

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
var current_chapter: int = 1
var is_cleared: bool = true
var _toast_label: Label = null

# Event Carousel Data
var events_data: Array[Dictionary] = [
	{"icon": "🏆", "title": "All-Star Cup — Season 4", "sub": "Climb the tower for Mythic Relics! (2d 14h left)"},
	{"icon": "💀", "title": "Abyssal Incursion — Raid", "sub": "Defeat the Void Harvester with Guild! (18h left)"},
	{"icon": "🏰", "title": "Tower of Torment — Floor 10", "sub": "Double Shades & High-Tier Runes Active! (5d left)"}
]
var current_event_idx: int = 0
var _event_timer: float = 0.0

# Chat Ticker Data
var chat_messages: Array[String] = [
	" [System] Hunter Raven unlocked Hellhound Evolution on Floor 3!",
	" [World] Shadowblade harvested 12,000 Shades in Torment mode!",
	" [Guild] Frost Valkyrie defeated Void Goliath on Floor 8!",
	" [Altar] Arcane Convergence active: +20% Rune Resonance!",
	" [Broadcast] Player Moros forged a Mythic Abyssal Blade (+7)!"
]
var current_chat_idx: int = 0
var _chat_timer: float = 0.0

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
	
	_setup_difficulty_buttons()
	_setup_event_banner()
	_setup_sidebar_buttons()
	_setup_toast_label()

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
	
	var mult_str := "1.0x"
	if diff == "hard": mult_str = "1.5x"
	elif diff == "torment": mult_str = "2.0x"
	show_toast("⚔ Difficulty Set: %s Mode (%s Multiplier)" % [diff.capitalize(), mult_str])
	difficulty_changed.emit(diff)

func _update_difficulty_visuals(active_diff: String) -> void:
	var active_col := Color(1.0, 0.9, 0.35, 1.0)
	var inactive_col := Color(0.65, 0.72, 0.85, 0.75)
	
	if btn_diff_normal:
		btn_diff_normal.add_theme_color_override("font_color", active_col if active_diff == "normal" else inactive_col)
	if btn_diff_hard:
		btn_diff_hard.add_theme_color_override("font_color", active_col if active_diff == "hard" else inactive_col)
	if btn_diff_torment:
		btn_diff_torment.add_theme_color_override("font_color", active_col if active_diff == "torment" else inactive_col)

func _setup_event_banner() -> void:
	if banner_btn:
		banner_btn.pressed.connect(_cycle_event)
	_update_event_visuals()

func _cycle_event() -> void:
	current_event_idx = (current_event_idx + 1) % events_data.size()
	_update_event_visuals()
	if AudioManager: AudioManager.play_sfx("ui_click")
	show_toast("📌 Event: %s" % events_data[current_event_idx].title)
	event_clicked.emit(current_event_idx)

func _update_event_visuals() -> void:
	var ev: Dictionary = events_data[current_event_idx]
	if banner_trophy: banner_trophy.text = ev.icon
	if banner_title: banner_title.text = ev.title
	if banner_subtitle: banner_subtitle.text = ev.sub
	if banner_dots:
		var dots_str := ""
		for i in range(events_data.size()):
			dots_str += "● " if i == current_event_idx else "○ "
		banner_dots.text = dots_str.strip_edges()

func _setup_sidebar_buttons() -> void:
	if btn_privilege:
		btn_privilege.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("👑 VIP Privilege: Daily +10 ⚡ & +15% Patrol Gold active!")
		)
	if btn_great_value:
		btn_great_value.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("🎁 7-Day Festival: Day 3/7 Claimable in Sanctuary Tab!")
		)
	if btn_rankings:
		btn_rankings.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("🏅 Leaderboard: #142 Hunter Raven (Top 5% Global)")
		)
	if btn_tasks:
		btn_tasks.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("📜 Daily Quests: 3/5 Completed (+120 💎 ready to claim)")
		)
	if btn_friends:
		btn_friends.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("👥 Abyssal Alliance: 6 Guildmates currently online")
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
	if AudioManager: AudioManager.play_sfx("shop_buy")
	if SaveManager:
		var claimed: Dictionary = SaveManager.claim_patrol_rewards()
		show_toast("🏆 Patrol Hunt Claimed! +%d Gold, +%d Shades" % [claimed.get("gold", 2400), claimed.get("shades", 60)])
	else:
		show_toast("🏆 Patrol Hunt Claimed! +2,400 Gold")
	hunt_clicked.emit()

func _on_chest_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("upgrade")
	if SaveManager:
		SaveManager.add_gold(500)
		SaveManager.add_gems(50)
	show_toast("🎁 Chapter 1 Chest Claimed! +500 🪙, +50 💎")
	chest_clicked.emit()

func _on_guild_pressed() -> void:
	if AudioManager: AudioManager.play_sfx("ui_click")
	show_toast("🛡 Guild Outpost: Unlocks at Chapter 3 (24/30 Members)")
	guild_clicked.emit()

func _process(delta: float) -> void:
	_t += delta
	# Subtle floating bob on the central diorama island
	if island_container:
		island_container.position.y = sin(_t * 1.5) * 6.0
		
	# Carousel auto-cycling
	_event_timer += delta
	if _event_timer >= 5.0:
		_event_timer = 0.0
		current_event_idx = (current_event_idx + 1) % events_data.size()
		_update_event_visuals()
		
	# Chat ticker auto-cycling
	_chat_timer += delta
	if _chat_timer >= 4.0:
		_chat_timer = 0.0
		current_chat_idx = (current_chat_idx + 1) % chat_messages.size()
		if chat_label:
			chat_label.text = chat_messages[current_chat_idx]
