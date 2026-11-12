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

func _ready() -> void:
	custom_minimum_size = Vector2(0, 120)
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
		var shards: int = SaveManager.character_shards.get("shadow_hunter", 0)
		var stars: int = SaveManager.character_stars.get("shadow_hunter", 1)
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
		
		if is_active:
			cont.modulate = Color(1.0, 1.0, 1.0, 1.0)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			lbl.add_theme_font_size_override("font_size", 20)
			ico.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			ico.add_theme_font_size_override("font_size", 44)
		else:
			cont.modulate = Color(0.7, 0.75, 0.85, 0.75)
			lbl.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
			lbl.add_theme_font_size_override("font_size", 17)
			ico.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8, 1.0))
			ico.add_theme_font_size_override("font_size", 36)
	refresh_badges()
