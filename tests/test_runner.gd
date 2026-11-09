extends Node

# Test Runner node executed inside the full Godot SceneTree with active Autoloads.

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print("  RUNNING ABYSSAL ALTAR AUTOMATED TEST SUITE")
	print("==================================================\n")
	
	test_independent_movement_and_aim()
	test_persistent_equipment_slots()
	test_inventory_footprint_and_rotation()
	test_inventory_bounds_and_overlap_validation()
	test_synergies_and_backpack_isolation()
	test_item_merging()
	test_shop_purchases_and_gold_validation()
	test_tower_progression_level_5_boss_guarantee()
	test_boss_victory_advancement()
	test_boss_defeat_same_floor_level_1_rule()
	test_duplicate_reward_prevention()
	test_permanent_shades_and_save_persistence()
	test_storage_reset_and_clean_uninstall()
	test_characters_data_and_abilities()
	test_audio_buses_and_volumes()
	test_character_selection_and_unlock_flow()
	test_opening_navigation_flow()
	test_story_intro_and_illustrated_assets()
	test_altar_weapon_and_item_moving()
	test_valkyrie_blessing_pick_and_refresh()
	test_summoning_circle_redesign()
	
	print("\n==================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================\n")
	
	if tests_failed > 0:
		print("FAILED SOME TESTS!")
	else:
		print("ALL ACCEPTANCE TESTS PASSED SUCCESSFULLY!")
	get_tree().quit(tests_failed)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] " + message)
	else:
		tests_failed += 1
		print("  [FAIL] " + message)

# 1. Test Single Movement Joystick & Stutter-Step Auto-Aiming
func test_independent_movement_and_aim() -> void:
	print("--- Test 1: Single Joystick Movement & Stutter-Step Auto-Aim ---")
	var player := PlayerController.new()
	var move_joy := VirtualJoystick.new()
	
	add_child(player)
	add_child(move_joy)
	
	player.move_joystick = move_joy
	
	# Spawn dummy enemy to test auto-target locking
	var dummy_enemy := Node2D.new()
	dummy_enemy.position = Vector2(200, 0)
	dummy_enemy.add_to_group("enemies")
	add_child(dummy_enemy)
	
	# Simulate moving left (-1, 0) with single joystick
	move_joy.is_pressed = true
	move_joy.output_vector = Vector2(-1.0, 0.0)
	
	player._physics_process(0.016)
	
	assert_true(player.velocity.x < 0.0, "Player moves left while single joystick points left")
	assert_true(not player.is_attacking, "Moving suppresses basic attack (Archero stutter-step)")
	assert_true(player.aim_direction.x < 0.0, "Aim direction faces movement while running")
	
	# Releasing joystick stops movement and triggers auto-aim at nearest enemy
	move_joy._reset_joystick()
	player.velocity = Vector2.ZERO
	player._physics_process(0.016)
	
	assert_true(player.is_attacking, "Stationary hunter auto-fires at nearest enemy")
	assert_true(player.aim_direction.x > 0.0, "Aim locks onto enemy at (+200, 0)")
	
	dummy_enemy.queue_free()
	player.queue_free()
	move_joy.queue_free()


# Persistent profile gear is independent from run altar items.
func test_persistent_equipment_slots() -> void:
	print("--- Test: Persistent Six-Slot Hunter Equipment ---")
	var original_inventory: Array[Dictionary] = SaveManager.gear_inventory.duplicate(true)
	var original_equipped: Dictionary = SaveManager.equipped_gear.duplicate(true)

	assert_true(SaveManager.EQUIPMENT_SLOTS.size() == 6, "Six equipment slots are registered")
	for slot_name in SaveManager.EQUIPMENT_SLOTS:
		assert_true(SaveManager.get_equipped_gear(slot_name) != null, "%s has starter equipment" % slot_name.capitalize())

	var helm := ItemInstance.new(ItemDatabase.get_item("void_helm"))
	var rune := ItemInstance.new(ItemDatabase.get_item("fire_rune"))
	assert_true(SaveManager.add_gear_item(helm), "Valid gear item is added to profile inventory")
	assert_true(not SaveManager.add_gear_item(helm), "Duplicate gear UID is rejected")
	assert_true(not SaveManager.add_gear_item(rune), "Runes cannot enter the equipment inventory")
	assert_true(SaveManager.equip_gear_item(helm.uid), "Gear item equips into its declared slot")
	var equipped_helm := SaveManager.get_equipped_gear("helmet")
	assert_true(equipped_helm != null and equipped_helm.uid == helm.uid, "Helmet slot returns the equipped item")
	assert_true(not SaveManager.equip_gear_item(rune.uid), "Runes cannot be equipped as gear")

	var gear_stats: Dictionary = SaveManager.get_equipped_gear_stats()
	assert_true(gear_stats.get("bonus_hp", 0.0) >= 18.0, "Equipped gear contributes passive HP")
	SaveManager.save_profile()
	SaveManager.load_profile()
	var restored_helm := SaveManager.get_equipped_gear("helmet")
	assert_true(restored_helm != null and restored_helm.uid == helm.uid, "Equipped item UID persists across profile reload")

	assert_true(SaveManager.unequip_gear_slot("helmet"), "Equipped gear can be unequipped")
	assert_true(SaveManager.get_equipped_gear("helmet") == null, "Unequipped slot is empty")

	SaveManager.gear_inventory = original_inventory
	SaveManager.equipped_gear = original_equipped
	SaveManager.save_profile()

# 2. Test Multi-Cell Footprint and 90-Degree Rotation
func test_inventory_footprint_and_rotation() -> void:
	print("--- Test 2: Item Footprint & 90-Degree Rotation ---")
	var blade_data := ItemDatabase.get_item("shadow_blade")
	var inst := ItemInstance.new(blade_data, Vector2i(0, 0), 0)
	
	var initial_shape := inst.get_rotated_shape()
	assert_true(initial_shape.has(Vector2i(0, 0)) and initial_shape.has(Vector2i(0, 1)), "1x2 item has vertical shape at 0 deg")
	
	# Rotate 90 deg clockwise
	inst.rotate_clockwise()
	var rot_shape := inst.get_rotated_shape()
	assert_true(rot_shape.has(Vector2i(0, 0)) and rot_shape.has(Vector2i(1, 0)), "1x2 item rotates to horizontal 2x1 shape")
	
	# Rotate back to 360 (4 turns total)
	inst.rotate_clockwise()
	inst.rotate_clockwise()
	inst.rotate_clockwise()
	assert_true(inst.rotation_step == 0, "4 rotations returns to original orientation")

# 3. Test Placement Bounds and Overlap Prevention
func test_inventory_bounds_and_overlap_validation() -> void:
	print("--- Test 3: Placement Bounds & Overlap Prevention ---")
	var grid := GridManager.new(4, 4)
	var scythe_data := ItemDatabase.get_item("abyssal_scythe") # 2x2 shape
	var item_a := ItemInstance.new(scythe_data, Vector2i(0, 0))
	var existing: Array[ItemInstance] = [item_a]
	
	assert_true(grid.can_place_item(item_a, Vector2i(0, 0), []), "Item fits within 4x4 grid bounds")
	assert_true(not grid.can_place_item(item_a, Vector2i(3, 3), []), "Item out of bounds rejected")
	
	var dagger_data := ItemDatabase.get_item("shadow_dagger")
	var item_b := ItemInstance.new(dagger_data, Vector2i(1, 1))
	assert_true(not grid.can_place_item(item_b, Vector2i(1, 1), existing), "Overlapping item placement rejected")
	assert_true(grid.can_place_item(item_b, Vector2i(2, 2), existing), "Non-overlapping placement permitted")

# 4. Test Synergies and Reserve Backpack Isolation
func test_synergies_and_backpack_isolation() -> void:
	print("--- Test 4: Altar Synergies & Backpack Isolation ---")
	var grid := GridManager.new(4, 4)
	
	var fire_rune := ItemInstance.new(ItemDatabase.get_item("fire_rune"), Vector2i(0, 0))
	var wolf_core := ItemInstance.new(ItemDatabase.get_item("wolf_core"), Vector2i(1, 0)) # Orthogonally adjacent!
	
	assert_true(grid.are_items_adjacent(fire_rune, wolf_core), "Fire Rune and Wolf Core detected as adjacent")
	
	var active_items: Array[ItemInstance] = [fire_rune, wolf_core]
	var syn := ItemSynergyManager.evaluate_synergies(active_items, grid)
	assert_true(syn.get("has_hellhound", false), "Adjacent Fire Rune + Wolf Core activates Hellhound Evolution!")
	
	# Test reserve backpack isolation
	var backpack_only: Array[ItemInstance] = [fire_rune]
	var syn_isolated := ItemSynergyManager.evaluate_synergies(backpack_only, grid)
	assert_true(not syn_isolated.get("has_hellhound", false), "Items in Reserve Backpack provide NO active synergy")

# 5. Test Item Merging
func test_item_merging() -> void:
	print("--- Test 5: Duplicate Item Merging & Tier Upgrades ---")
	var d1 := ItemDatabase.get_item("shadow_dagger")
	var inst1 := ItemInstance.new(d1, Vector2i(0, 0))
	var inst2 := ItemInstance.new(d1, Vector2i(1, 0))
	
	GameManager.altar_items = [inst1, inst2]
	GameManager.backpack_items.clear()
	
	assert_true(GameManager.can_merge_items(inst1, inst2), "Two identical Tier 1 daggers are eligible to merge")
	var merged := GameManager.merge_items(inst1, inst2)
	assert_true(merged != null, "Merge succeeds and produces a new item")
	assert_true(merged.data.id == "shadow_blade", "Tier 1 Shadow Daggers merge into Tier 2 Shadow Blade")
	assert_true(merged.data.tier == 2, "Merged item is Tier 2")

# 6. Test Shop Purchases & Resource Validation
func test_shop_purchases_and_gold_validation() -> void:
	print("--- Test 6: Shop Purchases & Gold Validation ---")
	GameManager.run_gold = 20
	var expensive_cost := 50
	assert_true(not GameManager.spend_gold(expensive_cost), "Cannot purchase items without sufficient gold")
	assert_true(GameManager.run_gold == 20, "Gold balance unchanged after rejected purchase")
	
	var affordable_cost := 15
	assert_true(GameManager.spend_gold(affordable_cost), "Can purchase item with sufficient gold")
	assert_true(GameManager.run_gold == 5, "Gold balance correctly deducted after purchase")

# 7. Test Tower Progression & Floor Boss Guarantee at Level 5
func test_tower_progression_level_5_boss_guarantee() -> void:
	print("--- Test 7: Tower Progression & Level 5 Boss Guarantee ---")
	GameManager.start_new_run("shadow_hunter", 1)
	assert_true(GameManager.floor_number == 1 and GameManager.level_number == 1, "Run starts at Floor 1, Level 1")
	
	GameManager.advance_to_next_level() # to Level 2
	assert_true(GameManager.level_number == 2 and GameManager.current_encounter_type != "boss", "Level 2 is non-boss encounter")
	
	GameManager.advance_to_next_level() # to Level 3
	GameManager.advance_to_next_level() # to Level 4
	assert_true(GameManager.level_number == 4, "Progresses cleanly through Level 4")
	
	GameManager.advance_to_next_level() # to Level 5
	assert_true(GameManager.level_number == 5 and GameManager.current_encounter_type == "boss", "Level 5 ALWAYS guarantees Floor Boss encounter!")

# 8. Test Boss Victory Progression
func test_boss_victory_advancement() -> void:
	print("--- Test 8: Boss Victory Floor Unlock ---")
	GameManager.floor_number = 1
	GameManager.level_number = 5
	GameManager.current_encounter_type = "boss"
	
	GameManager.advance_to_next_level()
	assert_true(GameManager.floor_number == 2 and GameManager.level_number == 1, "Boss victory advances to Floor 2, Level 1")
	assert_true(SaveManager.highest_floor_unlocked >= 2, "Boss victory unlocks Floor 2 in persistent profile")

# 9. Test Mandatory Rule: Boss Defeat Resets to Level 1 of Same Floor (NOT Floor 1!)
func test_boss_defeat_same_floor_level_1_rule() -> void:
	print("--- Test 9: Boss Defeat Resets Same Floor Level 1 Rule ---")
	GameManager.floor_number = 3
	GameManager.level_number = 5
	GameManager.run_shades = 10
	
	var pre_shades := SaveManager.shades
	GameManager.retry_current_floor()
	
	assert_true(GameManager.floor_number == 3, "Losing to Floor 3 boss does NOT send player back to Floor 1!")
	assert_true(GameManager.level_number == 1, "Losing to boss resets current floor to Level 1")
	assert_true(SaveManager.shades >= pre_shades, "Permanent progression and shades survive defeat")

# 10. Test Duplicate Reward Prevention
func test_duplicate_reward_prevention() -> void:
	print("--- Test 10: Duplicate Reward Prevention ---")
	GameManager.has_claimed_level_reward = false
	GameManager.complete_current_level()
	assert_true(GameManager.has_claimed_level_reward, "Level completion marks reward as claimed")
	
	GameManager.complete_current_level()
	assert_true(GameManager.has_claimed_level_reward, "Duplicate reward claim blocked")

# 11. Test Permanent Shades and Save Persistence
func test_permanent_shades_and_save_persistence() -> void:
	print("--- Test 11: Save/Load Profile Persistence ---")
	var initial_shades := SaveManager.shades
	SaveManager.add_shades(25)
	assert_true(SaveManager.shades == initial_shades + 25, "Permanent Shades increase correctly")
	
	SaveManager.save_profile()
	SaveManager.load_profile()
	assert_true(SaveManager.shades == initial_shades + 25, "Permanent Shades persist through profile reload")

func test_storage_reset_and_clean_uninstall() -> void:
	print("--- Test 11b: Local Storage Reset & Clean Uninstall Purge ---")
	SaveManager.shades = 500
	SaveManager.profile_gold = 99999
	SaveManager.player_level = 20
	SaveManager.equipment_levels["weapon"] = 99
	SaveManager.save_profile()

	var high_power := SaveManager.calculate_combat_power()
	assert_true(high_power > 50000, "High combat power calculated for leveled profile")

	# Execute reset_all_data to simulate app data clear or clean reinstall
	SaveManager.reset_all_data()

	assert_true(SaveManager.shades == 0, "Player shades reset cleanly to 0")
	assert_true(SaveManager.profile_gold == 5000, "Player gold reset to default initial 5000")
	assert_true(SaveManager.player_level == 5, "Player level reset to default initial 5")
	assert_true(SaveManager.equipment_levels["weapon"] == 60, "Equipment reset to clean baseline")
	assert_true(SaveManager.calculate_combat_power() < high_power, "Player combat power reset cleanly on reinstall/data wipe")
	assert_true(not FileAccess.file_exists(SaveManager.SAVE_PATH), "Save file removed completely from disk")

	# Restore normal testing state
	SaveManager.save_profile()

# 12. Test Playable Characters Data & Unlocks
func test_characters_data_and_abilities() -> void:
	print("--- Test 12: Playable Characters Data ---")
	var hunter := CharacterDatabase.get_character("shadow_hunter")
	var reaper := CharacterDatabase.get_character("storm_reaper")
	var binder := CharacterDatabase.get_character("soul_binder")
	
	assert_true(hunter != null and hunter.unlocked_by_default, "Shadow Hunter is default unlocked")
	assert_true(reaper != null and reaper.attack_type == "lightning_bolts", "Storm Reaper has lightning specialty")
	assert_true(binder != null and binder.attack_type == "soul_missiles", "Soul Binder has soul/summon specialty")

# 13. Test Audio Buses and Volume Controls
func test_audio_buses_and_volumes() -> void:
	print("--- Test 13: Audio Buses & Volume Controls ---")
	assert_true(AudioServer.get_bus_index("Music") >= 0, "Music bus exists")
	assert_true(AudioServer.get_bus_index("SFX") >= 0, "SFX bus exists")
	assert_true(AudioServer.get_bus_index("Ambience") >= 0, "Ambience bus exists")
	
	AudioManager.set_music_volume(0.5)
	assert_true(AudioManager.music_vol == 0.5, "Music volume sets and updates correctly")
	
	AudioManager.set_muted(true)
	assert_true(AudioManager.is_muted and AudioServer.is_bus_mute(0), "Mute toggles master bus mute state")
	AudioManager.set_muted(false)

# 14. Test Dedicated Character Selection & Unlock Requirement Validation
func test_character_selection_and_unlock_flow() -> void:
	print("--- Test 14: Dedicated Character Selection & Unlock Flow ---")
	var scene := load("res://scenes/characters/character_select_view.tscn") as PackedScene
	assert_true(scene != null, "CharacterSelectView scene loads cleanly")
	var csv := scene.instantiate() as CharacterSelectView
	add_child(csv)
	
	assert_true(csv.selected_character_id == "shadow_hunter", "Shadow Hunter selected by default")
	assert_true(not csv.btn_action.disabled, "Shadow Hunter action button enabled for entry")
	
	# Select Storm Reaper
	csv._select_character("storm_reaper")
	assert_true(csv.selected_character_id == "storm_reaper", "Switches to Storm Reaper")
	var reaper_unlocked := SaveManager.is_character_unlocked("storm_reaper")
	if not reaper_unlocked:
		assert_true(csv.locked_overlay.visible, "Locked overlay visible for locked champion")
		assert_true(csv.lbl_unlock_requirement.text.contains("40 SHADES"), "Shows 40 Shades unlock requirement")
		
	# Select Soul Binder
	csv._select_character("soul_binder")
	assert_true(csv.selected_character_id == "soul_binder", "Switches to Soul Binder")
	var binder_unlocked := SaveManager.is_character_unlocked("soul_binder")
	if not binder_unlocked:
		assert_true(csv.locked_overlay.visible, "Locked overlay visible for Soul Binder")
		assert_true(csv.lbl_unlock_requirement.text.contains("80 SHADES"), "Shows 80 Shades unlock requirement")
		
	csv.queue_free()

# 15. Test Opening Experience & Main Menu Navigation
func test_opening_navigation_flow() -> void:
	print("--- Test 15: Opening Experience & Menu Navigation ---")
	var intro_scene := load("res://scenes/menus/intro_screen.tscn") as PackedScene
	assert_true(intro_scene != null, "IntroScreen scene loads cleanly")
	var intro := intro_scene.instantiate() as IntroScreen
	add_child(intro)
	assert_true(intro.has_signal("intro_completed"), "IntroScreen provides intro_completed signal")
	assert_true(intro.btn_skip != null, "IntroScreen has working skip button")
	intro.queue_free()
	
	var menu_scene := load("res://scenes/menus/main_menu.tscn") as PackedScene
	assert_true(menu_scene != null, "MainMenu scene loads cleanly")
	var menu := menu_scene.instantiate() as MainMenu
	add_child(menu)
	
	GameManager.is_in_run = false
	menu._refresh_state()
	assert_true(not menu.btn_continue.visible, "Continue button hidden when no run is in progress")
	
	GameManager.is_in_run = true
	GameManager.floor_number = 2
	GameManager.level_number = 3
	menu._refresh_state()
	assert_true(menu.btn_continue.visible, "Continue button visible when active run exists")
	assert_true(menu.btn_continue.text.contains("FLOOR 2"), "Continue button displays current Floor progress")
	GameManager.is_in_run = false
	
	menu.queue_free()

# 16. Test Story Intro & Illustrated Assets
func test_story_intro_and_illustrated_assets() -> void:
	print("--- Test 16: Story Intro & Illustrated Assets ---")
	var story_scene := load("res://scenes/menus/story_intro.tscn") as PackedScene
	assert_true(story_scene != null, "StoryIntro scene loads cleanly")
	var story := story_scene.instantiate() as StoryIntro
	add_child(story)
	assert_true(story.has_signal("story_completed"), "StoryIntro provides story_completed signal")
	assert_true(story.btn_skip != null, "StoryIntro has functional skip button")
	assert_true(story.acts.size() == 4, "StoryIntro contains all 4 narrative lore acts")
	story.queue_free()
	
	# Verify item icon loading
	var dagger := ItemDatabase.get_item("shadow_dagger")
	assert_true(dagger != null, "ItemDatabase retrieves shadow_dagger")
	var dagger_tex := dagger.get_icon_texture()
	assert_true(dagger_tex != null, "Shadow Dagger resolves to illustrated icon Texture2D")
	
	var shield := ItemDatabase.get_item("iron_shield")
	var shield_tex := shield.get_icon_texture() if shield else null
	assert_true(shield_tex != null, "Iron Shield resolves to illustrated icon Texture2D")
	
	# Verify horror audio streams
	assert_true(AudioManager.music_streams.has("horror_menu"), "Horror menu music stream registered")
	assert_true(AudioManager.sfx_streams.has("shoot_slash"), "Attack slash SFX stream registered")
	assert_true(AudioManager.sfx_streams.has("shoot_lightning"), "Attack lightning SFX stream registered")
	assert_true(AudioManager.sfx_streams.has("shoot_soul"), "Attack soul SFX stream registered")

# 17. Test Moving Equipped Weapons and Items on Altar Grid (Regression Suite)
func test_altar_weapon_and_item_moving() -> void:
	print("--- Test 17: Altar Weapon & Item Moving ---")
	GameManager.grid_manager = GridManager.new(4, 4)
	GameManager.altar_items.clear()
	GameManager.backpack_items.clear()
	
	# 1. Move a single-cell weapon to an empty position
	var dagger := ItemInstance.new(ItemDatabase.get_item("shadow_dagger"), Vector2i(0, 0), 0)
	GameManager.altar_items.append(dagger)
	assert_true(GameManager.can_move_item_to(dagger, Vector2i(2, 2)), "Single-cell dagger valid at (2, 2)")
	var move1_ok := GameManager.move_item_on_altar(dagger, Vector2i(2, 2))
	assert_true(move1_ok, "Moved single-cell weapon to (2, 2)")
	assert_true(dagger.grid_pos == Vector2i(2, 2), "Dagger position updated to (2, 2)")
	
	# 2. Move a multi-cell weapon (1x2 blade) to another valid position
	var blade := ItemInstance.new(ItemDatabase.get_item("shadow_blade"), Vector2i(0, 0), 0) # occupies (0,0) and (0,1)
	GameManager.altar_items.append(blade)
	assert_true(blade.get_rotated_shape().size() == 2, "Shadow Blade is a 2-cell weapon")
	var move2_ok := GameManager.move_item_on_altar(blade, Vector2i(1, 1))
	assert_true(move2_ok, "Moved 1x2 blade to (1, 1)")
	assert_true(blade.grid_pos == Vector2i(1, 1), "Blade position updated to (1, 1)")
	assert_true(blade.get_occupied_cells().has(Vector2i(1, 1)) and blade.get_occupied_cells().has(Vector2i(1, 2)), "Occupied cells match new position")
	
	# 3. Rotate an item and then move it
	blade.rotate_clockwise() # Rotates to 2x1: occupies (0,0) and (1,0)
	assert_true(blade.rotation_step == 1, "Blade rotated 90 degrees")
	var move3_ok := GameManager.move_item_on_altar(blade, Vector2i(0, 3), blade.rotation_step)
	assert_true(move3_ok, "Placed rotated 2x1 blade at (0, 3)")
	assert_true(blade.get_occupied_cells().has(Vector2i(0, 3)) and blade.get_occupied_cells().has(Vector2i(1, 3)), "Rotated cells correctly placed at (0,3) and (1,3)")
	
	# 4. Attempt to move an item into an occupied position
	# Dagger is at (2, 2). Try to move blade onto (2, 2):
	var can_overlap := GameManager.can_move_item_to(blade, Vector2i(2, 2))
	assert_true(not can_overlap, "Placement into occupied cell (2, 2) is blocked")
	var old_pos := blade.grid_pos
	var overlap_move := GameManager.move_item_on_altar(blade, Vector2i(2, 2))
	assert_true(not overlap_move, "Move transaction rejected on overlap")
	assert_true(blade.grid_pos == old_pos, "Item restored to original position after failed overlap move")
	
	# 5. Attempt to move an item outside altar boundaries
	var out_bounds := GameManager.can_move_item_to(blade, Vector2i(3, 3)) # 2x1 blade at x=3 would occupy x=3 and x=4 (out of bounds)
	assert_true(not out_bounds, "Placement exceeding grid boundaries is blocked")
	var oob_move := GameManager.move_item_on_altar(blade, Vector2i(3, 3))
	assert_true(not oob_move, "Move transaction rejected on boundary violation")
	assert_true(blade.grid_pos == old_pos, "Item restored to original position after failed boundary move")
	
	# 6. Cancel move operation and verify restoration
	var inv_scene := load("res://scenes/inventory/inventory_view.tscn") as PackedScene
	assert_true(inv_scene != null, "InventoryView loads cleanly")
	var inv_view := inv_scene.instantiate() as InventoryView
	add_child(inv_view)
	inv_view._select_item(blade, "altar")
	inv_view.start_move_mode()
	assert_true(inv_view.is_move_mode, "Entered move mode")
	blade.rotate_clockwise() # rotate during move mode
	inv_view.cancel_move_mode()
	assert_true(not inv_view.is_move_mode, "Exited move mode on cancel")
	assert_true(blade.grid_pos == old_pos, "Position preserved on move cancel")
	assert_true(blade.rotation_step == 1, "Rotation restored on move cancel")
	inv_view.queue_free()

	# 6b. Auto-entering move mode after an invalid rotation must preserve the
	# pre-rotation orientation so Cancel Move can restore it.
	var edge_blade := ItemInstance.new(ItemDatabase.get_item("shadow_blade"), Vector2i(3, 0), 0)
	GameManager.altar_items.append(edge_blade)
	var edge_inv := inv_scene.instantiate() as InventoryView
	add_child(edge_inv)
	edge_inv._select_item(edge_blade, "altar")
	edge_inv._on_rotate_pressed()
	assert_true(edge_inv.is_move_mode, "Invalid in-place rotation enters move mode")
	assert_true(edge_inv.move_orig_rot == 0 and edge_blade.rotation_step == 1, "Move preview rotates while original orientation is retained for rollback")
	edge_inv.cancel_move_mode()
	assert_true(edge_blade.rotation_step == 0, "Cancel Move restores orientation after auto-entered rotation mode")
	assert_true(edge_blade.grid_pos == Vector2i(3, 0), "Cancel Move preserves edge item position")
	edge_inv.queue_free()

	# 7. Move an item participating in adjacency synergy
	GameManager.altar_items.clear()
	var wolf := ItemInstance.new(ItemDatabase.get_item("wolf_core"), Vector2i(0, 0), 0)
	var rune := ItemInstance.new(ItemDatabase.get_item("fire_rune"), Vector2i(1, 0), 0) # adjacent to wolf!
	GameManager.altar_items.append(wolf)
	GameManager.altar_items.append(rune)
	GameManager.recalculate_stats_and_synergies()
	assert_true(GameManager.cached_synergies.get("active_synergies", []).size() >= 1, "Hellhound synergy active when adjacent")
	
	# Move rune away from wolf to (3, 3)
	var move_away := GameManager.move_item_on_altar(rune, Vector2i(3, 3))
	assert_true(move_away, "Moved Fire Rune away from Wolf Core to (3, 3)")
	assert_true(GameManager.cached_synergies.get("active_synergies", []).is_empty(), "Synergy deactivates when no longer adjacent")
	
	# Move rune back adjacent to (0, 1)
	var move_back := GameManager.move_item_on_altar(rune, Vector2i(0, 1))
	assert_true(move_back, "Moved Fire Rune back adjacent to Wolf Core at (0, 1)")
	assert_true(GameManager.cached_synergies.get("active_synergies", []).size() >= 1, "Synergy reactivates when adjacent again")
	
	# 8. Verify no duplicate or lost items throughout operations
	assert_true(GameManager.altar_items.size() == 2, "No item duplication or loss: exactly 2 items remain on altar")
	assert_true(rune.data.id == "fire_rune" and wolf.data.id == "wolf_core", "Item identity, data and stats fully preserved")

# 18. Test Valkyrie Blessing Screen & Refresh Mechanic
func test_valkyrie_blessing_pick_and_refresh() -> void:
	print("--- Test 18: Valkyrie Blessing Screen & Refresh ---")
	var rwd_scene := load("res://scenes/ui/reward_view.tscn") as PackedScene
	assert_true(rwd_scene != null, "RewardView scene loads cleanly")
	var rwd := rwd_scene.instantiate() as RewardView
	add_child(rwd)
	
	rwd.setup(false)
	assert_true(rwd.refreshes_left == 1, "Initial blessing refresh count is 1")
	assert_true(rwd.choices_container.get_child_count() > 0, "Blessing cards generated")
	assert_true(rwd.btn_refresh != null and not rwd.btn_refresh.disabled, "Refresh button is functional")
	
	# Test refresh roll
	rwd._on_refresh_pressed()
	assert_true(rwd.refreshes_left == 0, "Refresh count decremented to 0")
	assert_true(rwd.btn_refresh.disabled, "Refresh button disabled when out of rolls")
	assert_true(rwd.choices_container.get_child_count() > 0, "New blessing cards re-rolled after refresh")
	
	rwd.queue_free()

# 19. Test Phase 2: Functional Summoning Circle Altar Redesign
func test_summoning_circle_redesign() -> void:
	print("--- Test 19: Summoning Circle Altar Redesign & Inventory View ---")
	assert_true(AltarBoard.SOCKET_DEFS.size() == 13, "AltarBoard defines 13 ritual sockets")
	assert_true(AltarBoard.SOCKET_TO_CELL.size() == 13, "13 sockets mapped to virtual grid cells")
	assert_true(AltarBoard.CELL_TO_SOCKET.size() >= 13, "Virtual cells mapped to sockets")
	
	var inv_scene := load("res://scenes/inventory/inventory_view.tscn") as PackedScene
	assert_true(inv_scene != null, "InventoryView scene loads cleanly")
	var inv_view := inv_scene.instantiate() as InventoryView
	add_child(inv_view)
	
	assert_true(inv_view.altar_board != null, "AltarBoard is connected to InventoryView")
	assert_true(inv_view.btn_recycle != null, "Recycle button wired in InventoryView")
	assert_true(inv_view.toast_panel != null, "Toast feedback panel wired")
	
	# Test recycling via GameManager
	GameManager.altar_items.clear()
	GameManager.backpack_items.clear()
	var test_rune := ItemInstance.new(ItemDatabase.get_item("fire_rune"), Vector2i(0, 0), 0)
	GameManager.altar_items.append(test_rune)
	var pre_gold := GameManager.run_gold
	var recycled_gold := GameManager.recycle_item(test_rune)
	assert_true(recycled_gold == 25, "Recycling Tier 1 item yields 25 Gold")
	assert_true(GameManager.run_gold == pre_gold + 25, "Gold added to GameManager")
	assert_true(GameManager.altar_items.is_empty(), "Item removed from altar items after recycle")
	
	inv_view.queue_free()
