extends Node

# Visual Screen Capture Auditor for Abyssal Altar
# Loads the real main scene and captures screenshots of every major screen in portrait mobile resolution.

func _ready() -> void:
	print("Starting Abyssal Altar Visual Screen Audit...")
	var main_scene = load("res://scenes/main/main.tscn")
	if not main_scene:
		print("ERROR: Failed to load main.tscn")
		get_tree().quit(1)
		return
		
	var main_node = main_scene.instantiate() as MainController
	add_child(main_node)
	
	# Wait for ready and layout passes
	for i in range(10):
		await get_tree().process_frame
		
	# 1. Screen: Intro
	print("Capturing 1: Intro Screen...")
	main_node._show_screen("intro")
	for i in range(15): await get_tree().process_frame
	_save_screen("intro")
	
	# 1b. Screen: Story Intro
	print("Capturing 1b: Story Intro Act I...")
	main_node._show_screen("story_intro")
	if main_node.story_intro:
		main_node.story_intro.start_story()
	for i in range(15): await get_tree().process_frame
	_save_screen("story_intro")
	
	# 2. Screen: Main Menu
	print("Capturing 2: Main Menu...")
	main_node._show_screen("menu")
	for i in range(10): await get_tree().process_frame
	_save_screen("main_menu")
	
	# 3. Screen: Character Select (Shadow Hunter)
	print("Capturing 3: Character Select (Shadow Hunter)...")
	main_node._show_screen("character_select")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("shadow_hunter")
	for i in range(10): await get_tree().process_frame
	_save_screen("char_select_shadow_hunter")
	
	# 4. Screen: Character Select (Storm Reaper)
	print("Capturing 4: Character Select (Storm Reaper)...")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("storm_reaper")
	for i in range(10): await get_tree().process_frame
	_save_screen("char_select_storm_reaper")
	
	# 5. Screen: Character Select (Soul Binder)
	print("Capturing 5: Character Select (Soul Binder)...")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("soul_binder")
	for i in range(10): await get_tree().process_frame
	_save_screen("char_select_soul_binder")
	
	# 6. Screen: Progression / Sanctuary
	print("Capturing 6: Sanctuary & Upgrades...")
	main_node._show_screen("progression")
	if main_node.progression_view:
		main_node.progression_view._switch_tab("upgrades")
	for i in range(10): await get_tree().process_frame
	_save_screen("sanctuary_upgrades")
	
	# 7. Screen: Combat Arena
	print("Capturing 7: Combat Arena Gameplay...")
	main_node._clear_arena()
	GameManager.start_new_run("shadow_hunter", 1)
	main_node._show_screen("combat")
	for i in range(30): await get_tree().process_frame
	_save_screen("combat_gameplay")
	
	# 8. Screen: Altar Inventory & Grid
	print("Capturing 8: Altar Inventory Grid & Backpack...")
	main_node._clear_arena()
	for i in range(5): await get_tree().process_frame
	main_node._show_screen("inventory")
	if main_node.inventory_view:
		if not GameManager.altar_items.is_empty():
			main_node.inventory_view._select_item(GameManager.altar_items[0], "altar")
		main_node.inventory_view.refresh_inventory_ui()
	for i in range(15): await get_tree().process_frame
	_save_screen("altar_inventory")
	
	# 8b. Screen: Move Mode & Placement Preview
	print("Capturing 8b: Altar Relocate Move Mode & Destination Highlights...")
	if main_node.inventory_view and main_node.inventory_view.selected_item:
		main_node.inventory_view.start_move_mode()
		main_node.inventory_view.preview_cell = Vector2i(2, 2)
	for i in range(15): await get_tree().process_frame
	_save_screen("altar_move_mode")
	if main_node.inventory_view:
		main_node.inventory_view.cancel_move_mode()
	
	# 9. Screen: Encounter Reward Choices
	print("Capturing 9: Encounter Reward Choices...")
	main_node._show_screen("reward")
	if main_node.reward_view:
		main_node.reward_view.setup(false)
	for i in range(15): await get_tree().process_frame
	_save_screen("reward_view")
	
	# 10. Screen: Campaign World Hub (MainShell Tab 2)
	print("Capturing 10: Campaign World Hub...")
	main_node._show_screen("shell")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(2)
	for i in range(15): await get_tree().process_frame
	_save_screen("campaign_hub")
	
	# 11. Screen: Hero Loadout - Characters (MainShell Tab 1, Subtab 0)
	print("Capturing 11: Hero Loadout - Characters...")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(1)
		var hlo = main_node.main_shell.screen_loadout
		if hlo: hlo._switch_subtab(0)
	for i in range(15): await get_tree().process_frame
	_save_screen("hero_characters")
	
	# 12. Screen: Hero Loadout - Gear (MainShell Tab 1, Subtab 1)
	print("Capturing 12: Hero Loadout - Gear...")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(1)
		var hlo = main_node.main_shell.screen_loadout
		if hlo: hlo._switch_subtab(1)
	for i in range(15): await get_tree().process_frame
	_save_screen("hero_gear")
	
	# 13. Screen: Hero Loadout - Runes & Summoning Circle Altar (MainShell Tab 1, Subtab 2)
	print("Capturing 13: Hero Loadout - Summoning Circle Altar...")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(1)
		var hlo = main_node.main_shell.screen_loadout
		if hlo: hlo._switch_subtab(2)
	for i in range(15): await get_tree().process_frame
	_save_screen("hero_runes_altar")
	
	# 14. Screen: Collectibles & Talent Cards (MainShell Tab 3)
	print("Capturing 14: Collectibles & Talent Cards...")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(3)
	for i in range(15): await get_tree().process_frame
	_save_screen("talent_collectibles")
	
	# 15. Screen: Shop Screen (MainShell Tab 0)
	print("Capturing 15: Shop & Chapter Pack...")
	if main_node.main_shell:
		main_node.main_shell._switch_to_tab(0)
	for i in range(15): await get_tree().process_frame
	_save_screen("shop_market")
	
	# 16. Screen: Valkyrie Blessing Draft Modal
	print("Capturing 16: Valkyrie Blessing Draft Modal...")
	var draft_scene = load("res://scenes/ui/skill_draft_modal.tscn")
	if draft_scene:
		var modal = draft_scene.instantiate() as SkillDraftModal
		main_node.add_child(modal)
		modal.show_draft()
		for i in range(15): await get_tree().process_frame
		_save_screen("valkyrie_draft_modal")
		modal.queue_free()
	
	# 17. Screen: Combat Arena HUD & Speed Toggle
	print("Capturing 17: Combat Arena HUD...")
	main_node._show_screen("combat")
	main_node._spawn_combat_arena()
	for i in range(15): await get_tree().process_frame
	_save_screen("combat_arena_hud")
	main_node._clear_arena()
	
	print("Visual Screen Audit Captures Completed Successfully!")
	get_tree().quit(0)

func _save_screen(name: String) -> void:
	var img = get_viewport().get_texture().get_image()
	if img:
		var path = "res://screenshots/screen_%s.png" % name
		img.save_png(path)
		var brain_path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/screen_%s.png" % name
		img.save_png(brain_path)
		print("  -> Saved: ", path, " & artifact: ", brain_path)
