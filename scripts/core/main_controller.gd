class_name MainController
extends Control

# Master screen and game loop coordinator for Abyssal Altar.
# Integrates Intro, MainMenu, Character Selection, Sanctuary/Progression, Combat Arena,
# Altar/Backpack Inventory, Bazaar Shop, Rewards, Game Over / Retry, and Audio Settings.

@export var intro_screen: IntroScreen
@export var story_intro: StoryIntro
@export var main_menu: MainMenu
@export var main_shell: MainShellUI = null
@export var character_select_view: CharacterSelectView
@export var progression_view: ProgressionView
@export var inventory_view: InventoryView
@export var shop_view: ShopView
@export var reward_view: RewardView
@export var game_over_view: GameOverView
@export var settings_modal: SettingsModal
@export var combat_container: Node2D

var current_arena: CombatManager = null
var is_inventory_from_pause: bool = false

func _ready() -> void:
	_connect_subsystems()
	if main_shell:
		_show_screen("shell")
	elif intro_screen:
		_show_screen("intro")
	else:
		_show_screen("menu")

func _connect_subsystems() -> void:
	# 1. Intro Screen Signal -> transitions to Story Prologue
	if intro_screen:
		intro_screen.intro_completed.connect(func():
			if story_intro:
				_show_screen("story_intro")
				story_intro.start_story()
			else:
				_show_screen("menu")
		)

	# 1b. Story Intro Signal -> transitions to Main Menu or Main Shell
	if story_intro:
		story_intro.story_completed.connect(func():
			if main_shell:
				_show_screen("shell")
			else:
				_show_screen("menu")
		)

	# 1c. Main Shell Signals (Chrome Hub)
	if main_shell:
		main_shell.start_run_requested.connect(func():
			var char_id: String = GameManager.current_character.id if GameManager.current_character else "shadow_hunter"
			_on_start_run_requested(char_id)
		)

	# 2. Main Menu Signals
	if main_menu:
		main_menu.play_pressed.connect(func():
			if main_shell:
				_show_screen("shell")
			else:
				_show_screen("character_select")
		)
		main_menu.continue_pressed.connect(_on_continue_pressed)
		main_menu.characters_pressed.connect(func():
			_show_screen("character_select")
		)
		main_menu.sanctuary_pressed.connect(func():
			_show_screen("progression")
			if progression_view: progression_view._switch_tab("upgrades")
		)
		main_menu.prologue_pressed.connect(func():
			if story_intro:
				_show_screen("story_intro")
				story_intro.start_story()
		)
		main_menu.settings_pressed.connect(func():
			_show_modal("settings")
		)

	# 3. Character Select Signals
	if character_select_view:
		character_select_view.start_run_requested.connect(_on_start_run_requested)
		character_select_view.back_requested.connect(func(): _show_screen("menu"))

	# 4. Progression View Signals (Sanctuary)
	if progression_view:
		progression_view.start_run_requested.connect(_on_start_run_requested)
		progression_view.back_requested.connect(func(): _show_screen("menu"))

	# 5. Game Manager Signals
	GameManager.level_started.connect(_on_level_started)
	GameManager.level_completed.connect(func(_f: int, _l: int): _on_encounter_won(false))
	GameManager.boss_defeated.connect(func(_f: int): _on_encounter_won(true))
	GameManager.player_defeated.connect(_on_player_defeated)

	# 6. Inventory View Signals
	if inventory_view:
		inventory_view.close_requested.connect(_on_inventory_closed)

	# 7. Shop Signals
	if shop_view:
		shop_view.leave_shop_requested.connect(func():
			_show_screen("inventory")
		)

	# 8. Reward Signals
	if reward_view:
		reward_view.reward_claimed_and_continue.connect(func():
			_show_screen("inventory")
		)

	# 9. Game Over Signals
	if game_over_view:
		game_over_view.retry_requested.connect(func():
			GameManager.retry_current_floor()
		)
		game_over_view.sanctuary_requested.connect(func():
			_show_screen("shell" if main_shell else "menu")
		)
		game_over_view.revive_requested.connect(func():
			_show_screen("combat")
		)

	# 10. Settings Modal Signals
	if settings_modal:
		settings_modal.resume_requested.connect(func():
			get_tree().paused = false
			settings_modal.visible = false
		)
		settings_modal.inventory_requested.connect(func():
			is_inventory_from_pause = true
			settings_modal.visible = false
			_show_screen("inventory")
		)
		settings_modal.abandon_run_requested.connect(func():
			get_tree().paused = false
			settings_modal.visible = false
			_clear_arena()
			_show_screen("shell" if main_shell else "menu")
		)

func _show_screen(screen_name: String) -> void:
	if intro_screen: intro_screen.visible = (screen_name == "intro")
	if story_intro: story_intro.visible = (screen_name == "story_intro")
	if main_menu: main_menu.visible = (screen_name == "menu")
	if main_shell: main_shell.visible = (screen_name == "shell")
	if character_select_view: character_select_view.visible = (screen_name == "character_select")
	if progression_view: progression_view.visible = (screen_name == "progression")
	if inventory_view: inventory_view.visible = (screen_name == "inventory")
	if shop_view: shop_view.visible = (screen_name == "shop")
	if reward_view: reward_view.visible = (screen_name == "reward")
	if game_over_view: game_over_view.visible = (screen_name == "game_over")
	if settings_modal: settings_modal.visible = false
	
	if is_instance_valid(current_arena):
		current_arena.visible = (screen_name == "combat")
		var hud_layer = current_arena.get_node_or_null("HUDLayer") as CanvasLayer
		if hud_layer:
			hud_layer.visible = (screen_name == "combat")
	
	if screen_name == "inventory" and inventory_view:
		inventory_view.refresh_inventory_ui()

func _show_modal(modal_name: String) -> void:
	if modal_name == "settings" and settings_modal:
		settings_modal.visible = true

func _on_continue_pressed() -> void:
	if not GameManager.is_in_run:
		_show_screen("character_select")
		return
		
	if is_instance_valid(current_arena):
		_show_screen("combat")
	elif GameManager.current_encounter_type == "shop":
		_show_screen("shop")
	else:
		_show_screen("combat")
		_spawn_combat_arena()

func _on_start_run_requested(char_id: String) -> void:
	_clear_arena()
	GameManager.start_new_run(char_id, 1)

func _on_level_started(_floor_num: int, _level_num: int, encounter_type: String) -> void:
	_clear_arena()
	
	if encounter_type == "shop":
		_show_screen("shop")
	else:
		_show_screen("combat")
		_spawn_combat_arena()

func _spawn_combat_arena() -> void:
	_clear_arena()
	var arena_scene := load("res://scenes/combat/combat_arena.tscn")
	if not arena_scene: return
	
	current_arena = arena_scene.instantiate() as CombatManager
	if combat_container:
		combat_container.add_child(current_arena)
		
	# Connect HUD pause button
	var hud := current_arena.get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
	if hud:
		hud.setup(current_arena.player)
		hud.pause_requested.connect(func():
			get_tree().paused = true
			_show_modal("settings")
		)

func _clear_arena() -> void:
	if is_instance_valid(current_arena):
		var hud_layer = current_arena.get_node_or_null("HUDLayer") as CanvasLayer
		if hud_layer:
			hud_layer.visible = false
		current_arena.visible = false
		current_arena.queue_free()
		current_arena = null
	if combat_container:
		for c in combat_container.get_children():
			if c is CanvasLayer:
				c.visible = false
			c.queue_free()

func _on_encounter_won(is_boss: bool) -> void:
	_clear_arena()
	_show_screen("reward")
	if reward_view:
		reward_view.setup(is_boss)

func _on_inventory_closed() -> void:
	if is_inventory_from_pause:
		is_inventory_from_pause = false
		if settings_modal:
			settings_modal.visible = true
	else:
		# Advance to next level!
		GameManager.advance_to_next_level()

func _on_player_defeated(floor_num: int, level_num: int) -> void:
	_clear_arena()
	_show_screen("game_over")
	if game_over_view:
		game_over_view.setup(floor_num, level_num)
