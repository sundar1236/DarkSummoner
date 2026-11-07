extends SceneTree

# Visual Screen Capture Auditor for Abyssal Altar
# Loads the real main scene and captures screenshots of every major screen in portrait mobile resolution.

func _init() -> void:
	print("Starting Abyssal Altar Visual Screen Audit...")
	var main_scene = load("res://scenes/main/main.tscn")
	if not main_scene:
		print("ERROR: Failed to load main.tscn")
		quit(1)
		return
		
	var main_node = main_scene.instantiate() as MainController
	root.add_child(main_node)
	
	# Wait for ready and layout passes
	for i in range(10):
		await process_frame
		
	# 1. Screen: Intro
	print("Capturing 1: Intro Screen...")
	main_node._show_screen("intro")
	for i in range(15): await process_frame
	_save_screen("intro")
	
	# 2. Screen: Main Menu
	print("Capturing 2: Main Menu...")
	main_node._show_screen("menu")
	for i in range(10): await process_frame
	_save_screen("main_menu")
	
	# 3. Screen: Character Select (Shadow Hunter)
	print("Capturing 3: Character Select (Shadow Hunter)...")
	main_node._show_screen("character_select")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("shadow_hunter")
	for i in range(10): await process_frame
	_save_screen("char_select_shadow_hunter")
	
	# 4. Screen: Character Select (Storm Reaper)
	print("Capturing 4: Character Select (Storm Reaper)...")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("storm_reaper")
	for i in range(10): await process_frame
	_save_screen("char_select_storm_reaper")
	
	# 5. Screen: Character Select (Soul Binder)
	print("Capturing 5: Character Select (Soul Binder)...")
	if main_node.character_select_view:
		main_node.character_select_view._select_character("soul_binder")
	for i in range(10): await process_frame
	_save_screen("char_select_soul_binder")
	
	# 6. Screen: Progression / Sanctuary
	print("Capturing 6: Sanctuary & Upgrades...")
	main_node._show_screen("progression")
	if main_node.progression_view:
		main_node.progression_view._switch_tab("upgrades")
	for i in range(10): await process_frame
	_save_screen("sanctuary_upgrades")
	
	# 7. Screen: Combat Arena
	print("Capturing 7: Combat Arena Gameplay...")
	main_node._clear_arena()
	GameManager.start_new_run("shadow_hunter", 1)
	main_node._show_screen("combat")
	main_node._spawn_combat_arena()
	for i in range(30): await process_frame
	_save_screen("combat_gameplay")
	
	print("Visual Screen Audit Captures Completed Successfully!")
	quit(0)

func _save_screen(name: String) -> void:
	var img = root.get_viewport().get_texture().get_image()
	if img:
		var path = "res://screenshots/screen_%s.png" % name
		img.save_png(path)
		print("  -> Saved: ", path, " (", img.get_size(), ")")
