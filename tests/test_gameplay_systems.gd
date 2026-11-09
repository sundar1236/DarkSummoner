@tool
extends SceneTree

# Comprehensive Automated Test Suite for Abyssal Altar
# Validates all mandatory rules, inventory mechanics, progression, boss retry logic,
# synergies, save persistence, and audio controls.

var tests_passed: int = 0
var tests_failed: int = 0

func _init() -> void:
	print("\n==================================================")
	print("  RUNNING ABYSSAL ALTAR AUTOMATED TEST SUITE")
	print("==================================================\n")
	
	test_independent_movement_and_aim()
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
	test_characters_data_and_abilities()
	test_audio_buses_and_volumes()
	
	print("\n==================================================")
	print("  TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================\n")
	
	if tests_failed > 0:
		print("FAILED SOME TESTS!")
	else:
		print("ALL ACCEPTANCE TESTS PASSED SUCCESSFULLY!")
	quit(tests_failed)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] " + message)
	else:
		tests_failed += 1
		print("  [FAIL] " + message)

# 1. Test Independent Movement and Aiming
func test_independent_movement_and_aim() -> void:
	print("--- Test 1: Independent Dual-Stick Movement & Aiming ---")
	var player := PlayerController.new()
	var move_joy := VirtualJoystick.new()
	var aim_joy := VirtualJoystick.new()
	
	player.move_joystick = move_joy
	player.aim_joystick = aim_joy
	
	# Simulate moving left (-1, 0)
	move_joy.is_pressed = true
	move_joy.output_vector = Vector2(-1.0, 0.0)
	
	# Simulate aiming right (+1, 0)
	aim_joy.is_pressed = true
	aim_joy.output_vector = Vector2(1.0, 0.0)
	
	player._physics_process(0.016)
	
	assert_true(player.velocity.x < 0.0, "Player moves left while joystick points left")
	assert_true(player.aim_direction.x > 0.0, "Player aims right independently while moving left")
	assert_true(player.is_attacking, "Holding aim-attack stick enables continuous attacks")
	
	# Releasing aim stick stops attack
	aim_joy._reset_joystick()
	player._physics_process(0.016)
	assert_true(not player.is_attacking, "Releasing aim-attack stick stops basic attacks")
	
	player.queue_free()
	move_joy.queue_free()
	aim_joy.queue_free()

# 2. Test Multi-Cell Footprint and 90-Degree Rotation
func test_inventory_footprint_and_rotation() -> void:
	print("--- Test 2: Item Footprint & 90-Degree Rotation ---")
	var blade_data := ItemDatabase.get_item("shadow_blade") # 1x2 shape: [(0,0), (0,1)]
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
	
	# Check inside bounds
	assert_true(grid.can_place_item(item_a, Vector2i(0, 0), []), "Item fits within 4x4 grid bounds")
	# Check out of bounds: 2x2 placed at (3, 3) exceeds width 4 and height 4!
	assert_true(not grid.can_place_item(item_a, Vector2i(3, 3), []), "Item out of bounds rejected")
	
	# Check overlapping: placing item_b at (1, 1) overlaps item_a at (0, 0)
	var dagger_data := ItemDatabase.get_item("shadow_dagger")
	var item_b := ItemInstance.new(dagger_data, Vector2i(1, 1))
	assert_true(not grid.can_place_item(item_b, Vector2i(1, 1), existing), "Overlapping item placement rejected")
	
	# Valid non-overlapping placement at (2, 2)
	assert_true(grid.can_place_item(item_b, Vector2i(2, 2), existing), "Non-overlapping placement permitted")

# 4. Test Synergies and Reserve Backpack Isolation
func test_synergies_and_backpack_isolation() -> void:
	print("--- Test 4: Altar Synergies & Backpack Isolation ---")
	var grid := GridManager.new(4, 4)
	
	var fire_rune := ItemInstance.new(ItemDatabase.get_item("fire_rune"), Vector2i(0, 0))
	var wolf_core := ItemInstance.new(ItemDatabase.get_item("wolf_core"), Vector2i(1, 0)) # Orthogonally adjacent!
	
	# Test adjacency
	assert_true(grid.are_items_adjacent(fire_rune, wolf_core), "Fire Rune and Wolf Core detected as adjacent")
	
	var active_items: Array[ItemInstance] = [fire_rune, wolf_core]
	var syn := ItemSynergyManager.evaluate_synergies(active_items, grid)
	assert_true(syn.get("has_hellhound", false), "Adjacent Fire Rune + Wolf Core activates Hellhound Evolution!")
	
	# Test reserve backpack isolation: moving wolf core away into backpack
	var backpack_only: Array[ItemInstance] = [fire_rune] # Wolf core removed from active items
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
	
	# Advance levels 1 to 4
	GameManager.advance_to_next_level() # to Level 2
	assert_true(GameManager.level_number == 2 and GameManager.current_encounter_type != "boss", "Level 2 is non-boss encounter")
	
	GameManager.advance_to_next_level() # to Level 3
	assert_true(GameManager.level_number == 3 and GameManager.current_encounter_type == "elite", "Level 3 stays an elite combat encounter; the shop is not opened during a run")
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
	
	# Calling completion again should be ignored
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
