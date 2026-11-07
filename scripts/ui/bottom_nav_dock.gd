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

func _ready() -> void:
	custom_minimum_size = Vector2(0, 92)
	for i in range(tab_buttons.size()):
		var idx := i
		if tab_buttons[idx]:
			tab_buttons[idx].pressed.connect(func(): select_tab(idx))
	_update_tab_visuals()

func select_tab(idx: int) -> void:
	if current_tab == idx:
		return
	current_tab = idx
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_update_tab_visuals()
	tab_changed.emit(current_tab)

func _update_tab_visuals() -> void:
	for i in range(tab_containers.size()):
		var is_active := (i == current_tab)
		var cont := tab_containers[i]
		var lbl := tab_labels[i]
		var ico := tab_icons[i]
		
		if is_active:
			cont.modulate = Color(1.0, 1.0, 1.0, 1.0)
			lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			lbl.add_theme_font_size_override("font_size", 14)
			ico.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35, 1.0))
			ico.add_theme_font_size_override("font_size", 38)
		else:
			cont.modulate = Color(0.65, 0.68, 0.75, 0.8)
			lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
			lbl.add_theme_font_size_override("font_size", 12)
			ico.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75, 1.0))
			ico.add_theme_font_size_override("font_size", 30)
