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

var current_tab: int = 2

func _ready() -> void:
	if nav_dock:
		nav_dock.tab_changed.connect(_on_tab_changed)
	if screen_campaign:
		screen_campaign.start_run_requested.connect(func():
			start_run_requested.emit()
		)
		screen_campaign.camp_clicked.connect(func():
			if nav_dock: nav_dock.select_tab(1)
		)
		screen_campaign.rumble_clicked.connect(func():
			start_run_requested.emit()
		)
	if screen_loadout:
		screen_loadout.character_changed.connect(func(_char_id):
			if top_bar: top_bar.refresh_display()
		)
	if screen_shop:
		screen_shop.item_purchased.connect(func(_item_id):
			if top_bar: top_bar.refresh_display()
		)
	if screen_sanctuary:
		var back_btn = screen_sanctuary.get_node_or_null("VBox/Header/BtnBack") as Control
		if back_btn: back_btn.visible = false
	_switch_to_tab(current_tab)

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
