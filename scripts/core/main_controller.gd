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
var _pre_pause_time_scale: float = 1.0

func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_connect_subsystems()
	if SaveManager and not SaveManager.active_character_id.is_empty():
		GameManager.current_character = CharacterDatabase.get_character(SaveManager.active_character_id)
	if intro_screen:
		_show_screen("intro")
	elif story_intro:
		_show_screen("story_intro")
		story_intro.start_story()
	else:
		_show_after_story()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		handle_back_navigation()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_BACK)):
		if handle_back_navigation():
			get_viewport().set_input_as_handled()


## Routes Escape / Android hardware back across active modals, combat pause, and meta screens.
func handle_back_navigation() -> bool:
	if settings_modal and settings_modal.visible:
		if settings_modal.is_confirming_abandon:
			settings_modal._reset_confirm_state()
		else:
			settings_modal.resume_requested.emit()
		return true

	if inventory_view and inventory_view.visible:
		if inventory_view.is_move_mode:
			inventory_view.cancel_move_mode()
		elif is_inventory_from_pause:
			_on_inventory_closed()
		elif settings_modal:
			if settings_modal.has_method("set_context"):
				settings_modal.set_context(false)
			_show_modal("settings")
		return true

	if reward_view and reward_view.visible:
		if settings_modal:
			if settings_modal.has_method("set_context"):
				settings_modal.set_context(false)
			_show_modal("settings")
		return true

	if shop_view and shop_view.visible:
		shop_view.leave_shop_requested.emit()
		return true

	if game_over_view and game_over_view.visible:
		game_over_view.sanctuary_requested.emit()
		return true

	if character_select_view and character_select_view.visible:
		if not character_select_view.is_initial_selection:
			character_select_view.back_requested.emit()
		return true

	if progression_view and progression_view.visible:
		progression_view.back_requested.emit()
		return true

	if story_intro and story_intro.visible:
		if story_intro.has_method("skip_story"):
			story_intro.skip_story()
		return true

	if intro_screen and intro_screen.visible:
		if intro_screen.has_method("skip_intro"):
			intro_screen.skip_intro()
		return true

	if main_shell and main_shell.visible:
		if main_shell.has_method("handle_back_navigation") and main_shell.handle_back_navigation():
			return true
		if settings_modal:
			if settings_modal.has_method("set_context"):
				settings_modal.set_context(false)
			_show_modal("settings")
		return true

	if is_instance_valid(current_arena) and current_arena.visible:
		var draft := current_arena.get_node_or_null("HUDLayer/CombatHUD/SkillDraftModal") as SkillDraftModal
		if draft and draft.visible:
			if draft.learned_drawer and draft.learned_drawer.visible and draft.has_method("close_learned_drawer"):
				draft.close_learned_drawer()
			return true
		_pause_combat()
		return true

	if main_menu and main_menu.visible and settings_modal:
		if settings_modal.has_method("set_context"):
			settings_modal.set_context(false)
		_show_modal("settings")
		return true

	return false

func _connect_subsystems() -> void:
	# 1. Intro Screen Signal -> transitions to Story Prologue
	if intro_screen:
		intro_screen.intro_completed.connect(func():
			if story_intro:
				_show_screen("story_intro")
				story_intro.start_story()
			else:
				_show_after_story()
		)

	# 1b. Story Intro Signal -> first-time character draft, then the hub.
	if story_intro:
		story_intro.story_completed.connect(_show_after_story)

	# 1c. Main Shell Signals (Chrome Hub)
	if main_shell:
		main_shell.start_run_requested.connect(func():
			var char_id: String = GameManager.current_character.id if GameManager.current_character else "kael_varyn"
			_on_start_run_requested(char_id)
		)
		if main_shell.has_signal("settings_requested"):
			main_shell.settings_requested.connect(func():
				if settings_modal and settings_modal.has_method("set_context"):
					settings_modal.set_context(false)
				_show_modal("settings")
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
			if main_shell:
				_show_screen("shell")
				main_shell._switch_to_tab(1)
				if main_shell.screen_loadout:
					main_shell.screen_loadout._switch_subtab(0)
			else:
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
			if settings_modal and settings_modal.has_method("set_context"):
				settings_modal.set_context(false)
			_show_modal("settings")
		)

	# 3. Character Select Signals
	if character_select_view:
		character_select_view.start_run_requested.connect(_on_character_selection_confirmed)
		character_select_view.back_requested.connect(func(): _show_screen("shell" if main_shell else "menu"))

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
		if inventory_view.has_signal("settings_requested"):
			inventory_view.settings_requested.connect(func():
				if settings_modal and settings_modal.has_method("set_context"):
					settings_modal.set_context(is_inventory_from_pause)
				_show_modal("settings")
			)

	# 7. Shop Signals
	if shop_view:
		shop_view.leave_shop_requested.connect(func():
			_show_screen("inventory")
		)
		if shop_view.has_signal("settings_requested"):
			shop_view.settings_requested.connect(func():
				if settings_modal and settings_modal.has_method("set_context"):
					settings_modal.set_context(false)
				_show_modal("settings")
			)

	# 8. Reward Signals
	if reward_view:
		reward_view.reward_claimed_and_continue.connect(func():
			_show_screen("inventory")
		)
		if reward_view.has_signal("settings_requested"):
			reward_view.settings_requested.connect(func():
				if settings_modal and settings_modal.has_method("set_context"):
					settings_modal.set_context(false)
				_show_modal("settings")
			)

	# 9. Game Over Signals
	if game_over_view:
		game_over_view.retry_requested.connect(func():
			Engine.time_scale = 1.0
			get_tree().paused = false
			is_inventory_from_pause = false
			GameManager.retry_current_floor()
		)
		game_over_view.sanctuary_requested.connect(func():
			_abandon_active_run_and_return("shell" if main_shell else "menu")
		)
		game_over_view.revive_requested.connect(func():
			Engine.time_scale = 1.0
			get_tree().paused = false
			is_inventory_from_pause = false
			_show_screen("combat")
			if not is_instance_valid(current_arena):
				_spawn_combat_arena()
		)

	# 10. Settings Modal Signals
	if settings_modal:
		settings_modal.resume_requested.connect(_on_settings_resumed)
		settings_modal.inventory_requested.connect(func():
			is_inventory_from_pause = true
			settings_modal.visible = false
			_show_screen("inventory")
		)
		settings_modal.abandon_run_requested.connect(func():
			_abandon_active_run_and_return("shell" if main_shell else "menu")
		)
		if settings_modal.has_signal("main_menu_requested"):
			settings_modal.main_menu_requested.connect(func():
				get_tree().paused = false
				Engine.time_scale = 1.0
				settings_modal.visible = false
				_show_screen("menu")
			)

func _show_after_story() -> void:
	if SaveManager and not SaveManager.has_completed_initial_character_selection and character_select_view:
		character_select_view.set_initial_selection_mode(true)
		_show_screen("character_select")
	else:
		_show_screen("shell" if main_shell else "menu")

func _on_character_selection_confirmed(char_id: String) -> void:
	if character_select_view and character_select_view.is_initial_selection:
		GameManager.current_character = CharacterDatabase.get_character(char_id)
		character_select_view.set_initial_selection_mode(false)
		_show_screen("shell" if main_shell else "menu")
		return
	_on_start_run_requested(char_id)

func _show_screen(screen_name: String) -> void:
	# A hub modal must never remain visible when navigating to another root screen.
	if main_shell and main_shell.has_method("close_all_modals"):
		main_shell.close_all_modals()
	_set_active_root_screen(screen_name)
	if inventory_view:
		inventory_view.process_mode = Node.PROCESS_MODE_ALWAYS if screen_name == "inventory" and is_inventory_from_pause else Node.PROCESS_MODE_INHERIT
		if inventory_view.has_method("set_pause_mode"):
			inventory_view.set_pause_mode(screen_name == "inventory" and is_inventory_from_pause)
	if settings_modal: settings_modal.visible = false
	
	if is_instance_valid(current_arena):
		current_arena.visible = (screen_name == "combat")
		var hud_layer = current_arena.get_node_or_null("HUDLayer") as CanvasLayer
		if hud_layer:
			hud_layer.visible = (screen_name == "combat")
	
	if screen_name == "inventory" and inventory_view:
		inventory_view.refresh_inventory_ui()


func _pause_combat() -> void:
	_pre_pause_time_scale = Engine.time_scale
	Engine.time_scale = 1.0
	get_tree().paused = true
	if settings_modal and settings_modal.has_method("set_context"):
		settings_modal.set_context(true)
	_show_modal("settings")


func _on_settings_resumed() -> void:
	get_tree().paused = false
	if settings_modal:
		settings_modal.visible = false
	if is_instance_valid(current_arena) and current_arena.visible:
		var hud := current_arena.get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
		Engine.time_scale = hud.current_speed_scale if hud else _pre_pause_time_scale
	else:
		Engine.time_scale = 1.0


func _abandon_active_run_and_return(target_screen: String) -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	is_inventory_from_pause = false
	if settings_modal:
		settings_modal.visible = false
	_clear_arena()
	GameManager.abandon_run()
	_show_screen(target_screen)

# Root-screen visibility is owned here so transitions cannot leave overlapping screens.
func _set_active_root_screen(screen_name: String) -> void:
	var root_screens: Dictionary = {
		"intro": intro_screen,
		"story_intro": story_intro,
		"menu": main_menu,
		"shell": main_shell,
		"character_select": character_select_view,
		"progression": progression_view,
		"inventory": inventory_view,
		"shop": shop_view,
		"reward": reward_view,
		"game_over": game_over_view
	}
	for screen_key in root_screens:
		var screen := root_screens[screen_key] as Control
		if is_instance_valid(screen):
			screen.visible = (screen_key == screen_name)

func _show_modal(modal_name: String) -> void:
	if modal_name == "settings" and settings_modal:
		if is_instance_valid(current_arena):
			var hud := current_arena.get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
			if hud:
				hud.hide_announcement()
			var fb := current_arena.get_node_or_null("HUDLayer/CombatHUD/FeedbackBanner") as CanvasItem
			if fb:
				fb.visible = false
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
	Engine.time_scale = 1.0
	is_inventory_from_pause = false
	if shop_view and shop_view.has_method("reset_stock"):
		shop_view.reset_stock()
	GameManager.start_new_run(char_id, 1)

func _on_level_started(_floor_num: int, _level_num: int, encounter_type: String) -> void:
	_clear_arena()
	Engine.time_scale = 1.0
	is_inventory_from_pause = false
	
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
		hud.pause_requested.connect(_pause_combat)

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
		if inventory_view:
			inventory_view.visible = false
			inventory_view.process_mode = Node.PROCESS_MODE_INHERIT
		_show_screen("combat")
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
