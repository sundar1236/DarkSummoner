class_name MainShellUI
extends Control

# Global Persistent HUD Chrome (Part 3.1)
# Manages TopResourceBar, BottomNavDock, and transitions between the 5 meta screens:
# Tab 0: ShopScreen (Screen D)
# Tab 1: HeroLoadoutScreen (Screen B: Characters | Gear | Runes)
# Tab 2: CampaignScreen (Screen A: Floating Diorama World Hub) [Default]
# Tab 3: CollectibleScreen (Screen C: Talent Cards & Artifacts)
# Tab 4: Sanctuary / Events (ProgressionView)

signal start_run_requested()
signal screen_selected(tab_index: int)

@onready var top_bar = $TopResourceBar
@onready var nav_dock = $BottomNavDock
@onready var screens_container = $ScreensContainer

@onready var screen_shop = $ScreensContainer/ShopScreen
@onready var screen_loadout = $ScreensContainer/HeroLoadoutScreen
@onready var screen_campaign = $ScreensContainer/CampaignScreen
@onready var screen_collectible = $ScreensContainer/CollectibleScreen
@onready var screen_sanctuary = $ScreensContainer.get_node_or_null("SanctuaryView")

@onready var modal_energy: Control = get_node_or_null("EnergyReplenishModal")
@onready var modal_profile: Control = get_node_or_null("PlayerProfileModal")
@onready var modal_blacksmith: Control = get_node_or_null("BlacksmithModal")

const SafeAreaHelper = preload("res://scripts/ui/safe_area_helper.gd")

var current_tab: int = 2

func _ready() -> void:
	_apply_safe_area()
	if not get_tree().root.size_changed.is_connected(_apply_safe_area):
		get_tree().root.size_changed.connect(_apply_safe_area)
	
	if nav_dock:
		nav_dock.tab_changed.connect(_on_tab_changed)
	if top_bar:
		top_bar.energy_clicked.connect(open_energy_modal)
		top_bar.avatar_clicked.connect(open_profile_modal)
		top_bar.gold_clicked.connect(func():
			if nav_dock: nav_dock.select_tab(0)
		)
		top_bar.gems_clicked.connect(func():
			if nav_dock: nav_dock.select_tab(0)
		)
	if screen_campaign:
		screen_campaign.start_run_requested.connect(func():
			start_run_requested.emit()
		)
		screen_campaign.camp_clicked.connect(func():
			if nav_dock: nav_dock.select_tab(1)
		)
		if screen_campaign.has_signal("daily_tasks_requested"):
			screen_campaign.daily_tasks_requested.connect(func():
				if nav_dock: nav_dock.select_tab(0)
				if screen_shop and screen_shop.has_method("focus_daily_missions"):
					screen_shop.call_deferred("focus_daily_missions")
			)
		if screen_campaign.has_signal("insufficient_energy"):
			screen_campaign.insufficient_energy.connect(open_energy_modal)
	if screen_loadout:
		screen_loadout.character_changed.connect(func(_char_id):
			if top_bar: top_bar.refresh_display()
		)
		if screen_loadout.has_signal("blacksmith_requested"):
			screen_loadout.blacksmith_requested.connect(open_blacksmith_modal)
	if screen_shop:
		screen_shop.item_purchased.connect(func(_item_id):
			if top_bar: top_bar.refresh_display()
			if nav_dock: nav_dock.refresh_badges()
		)
	if modal_energy:
		modal_energy.energy_purchased.connect(func(_amount):
			if top_bar: top_bar.refresh_display()
			if nav_dock: nav_dock.refresh_badges()
		)
	if modal_blacksmith:
		modal_blacksmith.gear_upgraded.connect(func(_slot, _lvl):
			if top_bar: top_bar.refresh_display()
			if screen_loadout and screen_loadout.has_method("refresh_loadout"):
				screen_loadout.refresh_loadout()
		)
		if modal_blacksmith.has_signal("gear_purchased"):
			modal_blacksmith.gear_purchased.connect(func(_item_id):
				if top_bar: top_bar.refresh_display()
				if screen_loadout and screen_loadout.has_method("refresh_loadout"):
					screen_loadout.refresh_loadout()
			)
	if screen_sanctuary:
		var back_btn = screen_sanctuary.get_node_or_null("VBox/Header/BtnBack") as Control
		if back_btn: back_btn.visible = false
	_switch_to_tab(current_tab)

func open_energy_modal() -> void:
	if modal_energy and modal_energy.has_method("open_modal"):
		modal_energy.open_modal()
	elif modal_energy:
		modal_energy.visible = true

func open_profile_modal() -> void:
	if modal_profile and modal_profile.has_method("open_modal"):
		modal_profile.open_modal()
	elif modal_profile:
		modal_profile.visible = true

func open_blacksmith_modal() -> void:
	if modal_blacksmith and modal_blacksmith.has_method("open_modal"):
		modal_blacksmith.open_modal()
	elif modal_blacksmith:
		modal_blacksmith.visible = true

func _on_tab_changed(tab_idx: int) -> void:
	_switch_to_tab(tab_idx)

func _switch_to_tab(tab_idx: int) -> void:
	current_tab = tab_idx
	if screen_shop: screen_shop.visible = (tab_idx == 0)
	if screen_loadout: screen_loadout.visible = (tab_idx == 1)
	if screen_campaign: screen_campaign.visible = (tab_idx == 2)
	if screen_collectible: screen_collectible.visible = (tab_idx == 3)
	if screen_sanctuary: screen_sanctuary.visible = (tab_idx == 4)
	
	if top_bar:
		top_bar.refresh_display()
	screen_selected.emit(tab_idx)

func _apply_safe_area() -> void:
	var safe: Dictionary = SafeAreaHelper.get_safe_margins()
	var top_inset: float = safe.get("top", 46.0)
	var bot_inset: float = safe.get("bottom", 28.0)
	var left_inset: float = safe.get("left", 14.0)
	var right_inset: float = safe.get("right", 14.0)
	
	if top_bar:
		top_bar.offset_top = top_inset
		top_bar.offset_bottom = top_inset + 116.0
		top_bar.offset_left = left_inset
		top_bar.offset_right = -right_inset
		
	if nav_dock:
		nav_dock.offset_bottom = -bot_inset
		nav_dock.offset_top = -bot_inset - 120.0
		nav_dock.offset_left = left_inset
		nav_dock.offset_right = -right_inset
		
	if screens_container:
		screens_container.offset_top = top_inset + 116.0
		screens_container.offset_bottom = -bot_inset - 120.0
		screens_container.offset_left = 0.0
		screens_container.offset_right = 0.0
