class_name BottomNavDock
extends Control

# Persistent Bottom Navigation Dock across all meta-game screens.
# Supports 5 tabs: Shop (0), Gear (1), Campaign (2 - default), Collectible (3), Events (4).
# Highlights active tab with golden styling and vertical pop-up.

signal tab_changed(tab_index: int)

@export var current_tab: int = 2

@onready var tab_buttons: Array[Button] = [
	$NavPanel/TabHBox/TabShop/Button,
	$NavPanel/TabHBox/TabGear/Button,
	$NavPanel/TabHBox/TabCampaign/Button,
	$NavPanel/TabHBox/TabCollectible/Button,
	$NavPanel/TabHBox/TabEvents/Button
]

@onready var tab_containers: Array[Control] = [
	$NavPanel/TabHBox/TabShop,
	$NavPanel/TabHBox/TabGear,
	$NavPanel/TabHBox/TabCampaign,
	$NavPanel/TabHBox/TabCollectible,
	$NavPanel/TabHBox/TabEvents
]

@onready var tab_labels: Array[Label] = [
	$NavPanel/TabHBox/TabShop/VBox/Label,
	$NavPanel/TabHBox/TabGear/VBox/Label,
	$NavPanel/TabHBox/TabCampaign/VBox/Label,
	$NavPanel/TabHBox/TabCollectible/VBox/Label,
	$NavPanel/TabHBox/TabEvents/VBox/Label
]

@onready var tab_icons: Array[Label] = [
	$NavPanel/TabHBox/TabShop/VBox/Icon,
	$NavPanel/TabHBox/TabGear/VBox/Icon,
	$NavPanel/TabHBox/TabCampaign/VBox/Icon,
	$NavPanel/TabHBox/TabCollectible/VBox/Icon,
	$NavPanel/TabHBox/TabEvents/VBox/Icon
]

@onready var badge_shop: Control = $NavPanel/TabHBox/TabShop.get_node_or_null("Badge")
@onready var badge_gear: Control = $NavPanel/TabHBox/TabGear.get_node_or_null("Badge")
@onready var badge_collectible: Control = $NavPanel/TabHBox/TabCollectible.get_node_or_null("Badge")

const NAV_TAB_ICONS: Array[Dictionary] = [
	{"idle": "res://assets/art/ui_nav/nav_shop_idle.png", "active": "res://assets/art/ui_nav/nav_shop_active.png"},
	{"idle": "res://assets/art/ui_nav/nav_gear_idle.png", "active": "res://assets/art/ui_nav/nav_gear_active.png"},
	{"idle": "res://assets/art/ui_nav/nav_campaign_idle.png", "active": "res://assets/art/ui_nav/nav_campaign_active.png"},
	{"idle": "res://assets/art/ui_nav/nav_collectible_idle.png", "active": "res://assets/art/ui_nav/nav_collectible_active.png"},
	{"idle": "res://assets/art/ui_nav/nav_events_idle.png", "active": "res://assets/art/ui_nav/nav_events_active.png"}
]

func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)
	_ensure_tab_icon_textures()
	for i in range(tab_buttons.size()):
		var idx := i
		if tab_buttons[idx]:
			tab_buttons[idx].pressed.connect(func(): select_tab(idx))
	if SaveManager:
		SaveManager.profile_changed.connect(refresh_badges)
		SaveManager.daily_missions_changed.connect(refresh_badges)
		SaveManager.energy_changed.connect(func(_c, _m): refresh_badges())
	refresh_badges()
	_update_tab_visuals()

func _ensure_tab_icon_textures() -> void:
	for i in range(tab_containers.size()):
		var cont := tab_containers[i]
		var vbox := cont.get_node_or_null("VBox") as VBoxContainer
		if not vbox:
			continue
		vbox.add_theme_constant_override("separation", 2)
		var ico_lbl := tab_icons[i]
		if ico_lbl:
			ico_lbl.visible = false
		if not vbox.get_node_or_null("IconTex"):
			var tex_rect := TextureRect.new()
			tex_rect.name = "IconTex"
			tex_rect.custom_minimum_size = Vector2(56, 56)
			tex_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			vbox.add_child(tex_rect)
			vbox.move_child(tex_rect, 0)

func select_tab(idx: int) -> void:
	if idx < 0 or idx >= tab_buttons.size() or current_tab == idx:
		return
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	set_selected_tab(idx, true)

func set_selected_tab(idx: int, emit_change: bool = false) -> void:
	if idx < 0 or idx >= tab_buttons.size():
		push_warning("BottomNavDock ignored invalid tab index: %d" % idx)
		return
	current_tab = idx
	_update_tab_visuals()
	if emit_change:
		tab_changed.emit(current_tab)

func refresh_badges() -> void:
	if not SaveManager: return
	SaveManager.refresh_daily_shop_state()
	if badge_shop:
		var claimable_mission := false
		for mission in SaveManager.get_daily_missions():
			if bool(mission.get("completed", false)) and not bool(mission.get("claimed", false)):
				claimable_mission = true
				break
		var free_energy_available := not SaveManager.daily_free_energy_claimed
		badge_shop.visible = free_energy_available or claimable_mission
	if badge_gear:
		# Character can be starred up
		var active_id: String = SaveManager.active_character_id if not SaveManager.active_character_id.is_empty() else "kael_varyn"
		var shards: int = SaveManager.character_shards.get(active_id, 0)
		var stars: int = SaveManager.character_stars.get(active_id, 1)
		badge_gear.visible = (shards >= stars * 15 and stars < 6)
	if badge_collectible:
		# Can claim/upgrade
		var storm_card: Variant = SaveManager.talent_cards.get("storm_call", {})
		var storm_unlocked: bool = storm_card.get("unlocked", false) if storm_card is Dictionary else false
		badge_collectible.visible = (SaveManager.player_level >= 5 and not storm_unlocked)

func _update_tab_visuals() -> void:
	for i in range(tab_containers.size()):
		var is_active := (i == current_tab)
		var cont := tab_containers[i]
		var lbl := tab_labels[i]
		var ico := tab_icons[i]
		
		var indicator: ColorRect = cont.get_node_or_null("ActiveIndicator")
		if not indicator:
			indicator = ColorRect.new()
			indicator.name = "ActiveIndicator"
			indicator.custom_minimum_size = Vector2(0, 3)
			indicator.color = Color(1.0, 0.88, 0.35, 0.95)
			indicator.anchors_preset = Control.PRESET_TOP_WIDE
			indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			cont.add_child(indicator)
		indicator.visible = is_active
		
		var tex_rect := cont.get_node_or_null("VBox/IconTex") as TextureRect
		if tex_rect and i < NAV_TAB_ICONS.size():
			var icon_path: String = NAV_TAB_ICONS[i]["active" if is_active else "idle"]
			var icon_tex := TextureLoader.get_texture(icon_path)
			if icon_tex:
				tex_rect.texture = icon_tex
			tex_rect.custom_minimum_size = Vector2(64, 62) if is_active else Vector2(52, 52)

		var active_glow: Panel = cont.get_node_or_null("ActiveSlotBg")
		if not active_glow:
			active_glow = Panel.new()
			active_glow.name = "ActiveSlotBg"
			active_glow.anchors_preset = Control.PRESET_FULL_RECT
			active_glow.offset_left = 4.0
			active_glow.offset_right = -4.0
			active_glow.offset_top = 4.0
			active_glow.offset_bottom = -4.0
			active_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var gs := StyleBoxFlat.new()
			gs.bg_color = Color(0.24, 0.19, 0.1, 0.42)
			gs.border_color = Color(0.95, 0.78, 0.32, 0.78)
			gs.set_border_width_all(1)
			gs.set_corner_radius_all(8)
			active_glow.add_theme_stylebox_override("panel", gs)
			cont.add_child(active_glow)
			cont.move_child(active_glow, 0)
		active_glow.visible = is_active

		if is_active:
			cont.modulate = Color(1.0, 1.0, 1.0, 1.0)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			lbl.add_theme_font_size_override("font_size", 20)
			ico.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			ico.add_theme_font_size_override("font_size", 44)
		else:
			cont.modulate = Color(0.84, 0.86, 0.92, 0.92)
			lbl.add_theme_color_override("font_color", Color(0.75, 0.78, 0.84, 1.0))
			lbl.add_theme_font_size_override("font_size", 17)
			ico.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
			ico.add_theme_font_size_override("font_size", 36)
	refresh_badges()
