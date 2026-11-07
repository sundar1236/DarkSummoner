class_name TestAltarItemMove
extends SceneTree

# Automated regression test suite for Altar / Summoning Circle item moving mechanics.
# Verifies all 10 critical move/rotate/collision/rollback/synergy/save-load assertions.

var passed_count: int = 0
var failed_count: int = 0

func _init() -> void:
	print("\n==================================================")
	print("  RUNNING ALTAR ITEM MOVE REGRESSION SUITE")
	print("==================================================\n")
	
	_run_all_tests()
	
	print("\n==================================================")
	print("  MOVE REGRESSION SUITE: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==================================================\n")
	
	if failed_count > 0:
		print("FAILED: Some move assertions did not pass.")
		quit(1)
	else:
		print("SUCCESS: All 10 move assertions verified successfully!")
		quit(0)

func _assert_true(condition: bool, description: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % description)
	else:
		failed_count += 1
		printerr("  [FAIL] %s" % description)

func _run_all_tests() -> void:
	# Initialize mock dependencies
	var grid_mgr := GridManager.new(4, 4)
	
	var dagger_data := ItemData.new()
	dagger_data.id = "shadow_dagger"
	dagger_data.name = "Shadow Dagger"
	dagger_data.shape = [Vector2i(0, 0)]
	dagger_data.tier = 1
	
	var blade_data := ItemData.new()
	blade_data.id = "shadow_blade"
	blade_data.name = "Shadow Blade"
	blade_data.shape = [Vector2i(0, 0), Vector2i(0, 1)] # 1x2 shape
	blade_data.tier = 2
	
	var fire_rune_data := ItemData.new()
	fire_rune_data.id = "fire_rune"
	fire_rune_data.name = "Fire Rune"
	fire_rune_data.shape = [Vector2i(0, 0)]
	fire_rune_data.tags = ["fire"]
	
	var wolf_core_data := ItemData.new()
	wolf_core_data.id = "wolf_core"
	wolf_core_data.name = "Wolf Core"
	wolf_core_data.shape = [Vector2i(0, 0)]
	wolf_core_data.tags = ["beast"]

	# --- TEST 1: Transaction begin preserves item state and records original coordinates ---
	print("--- Test 1: Transaction Begin & Integrity Snapshot ---")
	var dagger := ItemInstance.new(dagger_data, Vector2i(1, 1), 0)
	dagger.rarity = "rare"
	dagger.upgrade_level = 3
	dagger.custom_stat_modifiers = {"bonus_atk": 12.5}
	var original_uid := dagger.uid
	
	var tx := MoveTransaction.begin(dagger, "ALTAR_GRID")
	_assert_true(tx.is_active, "Transaction is active upon begin()")
	_assert_true(tx.original_origin == Vector2i(1, 1), "Original origin recorded correctly")
	_assert_true(tx.original_rotation == 0, "Original rotation recorded correctly")
	_assert_true(tx.uid_snapshot == original_uid, "UID snapshot preserved")
	_assert_true(tx.upgrade_level_snapshot == 3, "Upgrade level snapshot preserved")
	_assert_true(tx.custom_stat_modifiers_snapshot["bonus_atk"] == 12.5, "Custom stats snapshot preserved")

	# --- TEST 2: Single-cell move to valid empty cell ---
	print("--- Test 2: Single-Cell Move to Valid Destination ---")
	var placed_items: Array[ItemInstance] = [dagger]
	var dest_2 := Vector2i(3, 3)
	var is_valid_dest := tx.validate_destination(dest_2, grid_mgr, placed_items)
	_assert_true(is_valid_dest, "Valid destination (3, 3) accepted")
	var commit_res := tx.commit(dest_2, grid_mgr, placed_items)
	_assert_true(commit_res, "Commit succeeds for valid destination")
	_assert_true(dagger.grid_pos == dest_2, "Dagger grid position updated to (3, 3)")
	_assert_true(dagger.uid == original_uid, "Dagger UID untouched after commit")

	# --- TEST 3: Multi-cell move (1x2 blade) to valid empty cell ---
	print("--- Test 3: Multi-Cell Item Move (1x2 Shape) ---")
	var blade := ItemInstance.new(blade_data, Vector2i(0, 0), 0)
	placed_items.append(blade)
	var blade_tx := MoveTransaction.begin(blade, "ALTAR_GRID")
	var blade_dest := Vector2i(1, 2) # Occupies (1,2) and (1,3)
	var blade_valid := blade_tx.validate_destination(blade_dest, grid_mgr, placed_items)
	_assert_true(blade_valid, "1x2 item fits at (1, 2)")
	var blade_commit := blade_tx.commit(blade_dest, grid_mgr, placed_items)
	_assert_true(blade_commit, "1x2 item move committed successfully")
	_assert_true(blade.grid_pos == blade_dest, "Blade grid position is (1, 2)")
	var occupied := blade.get_occupied_cells()
	_assert_true(occupied.has(Vector2i(1, 2)) and occupied.has(Vector2i(1, 3)), "Occupied cells match rotated 1x2 footprint")

	# --- TEST 4: 90-degree pre-commit rotation step ---
	print("--- Test 4: Pre-Commit 90-Degree Rotation ---")
	var rot_tx := MoveTransaction.begin(blade, "ALTAR_GRID")
	rot_tx.rotate_clockwise()
	_assert_true(rot_tx.preview_rotation == 1, "Preview rotation rotated to 90 degrees (step 1)")
	_assert_true(blade.rotation_step == 0, "Committed item rotation unchanged prior to commit")
	var rot_shape := rot_tx.get_preview_shape()
	_assert_true(rot_shape.has(Vector2i(0, 0)) and rot_shape.has(Vector2i(1, 0)), "Rotated shape normalized to 2x1 horizontal footprint")

	# --- TEST 5: Collision rejection when moving onto an occupied cell ---
	print("--- Test 5: Collision Rejection (Excluding Self, Detecting Others) ---")
	# dagger is at (3, 3). Moving blade to (2, 3) with 2x1 horizontal shape would occupy (2, 3) and (3, 3) -> collision!
	var coll_valid := rot_tx.validate_destination(Vector2i(2, 3), grid_mgr, placed_items)
	_assert_true(not coll_valid, "Moving onto cell (3, 3) occupied by dagger is rejected")
	var coll_commit := rot_tx.commit(Vector2i(2, 3), grid_mgr, placed_items)
	_assert_true(not coll_commit, "Commit fails and aborts on collision")

	# --- TEST 6: Grid boundary violation rejection ---
	print("--- Test 6: Boundary Violation Rejection ---")
	var oob_tx := MoveTransaction.begin(dagger, "ALTAR_GRID")
	var oob_dest := Vector2i(4, 4) # 4x4 grid coordinates are 0..3
	var oob_valid := oob_tx.validate_destination(oob_dest, grid_mgr, placed_items)
	_assert_true(not oob_valid, "Destination outside grid bounds is rejected")
	var oob_commit := oob_tx.commit(oob_dest, grid_mgr, placed_items)
	_assert_true(not oob_commit, "Boundary violation aborts commit cleanly")

	# --- TEST 7: Rollback on cancel restores original origin and rotation ---
	print("--- Test 7: Rollback on Cancel Restores Original State ---")
	var cancel_tx := MoveTransaction.begin(dagger, "ALTAR_GRID")
	cancel_tx.preview_origin = Vector2i(0, 0)
	cancel_tx.rotate_clockwise()
	cancel_tx.rollback()
	_assert_true(not cancel_tx.is_active, "Transaction inactive after rollback")
	_assert_true(dagger.grid_pos == Vector2i(3, 3), "Dagger restored to original position (3, 3)")
	_assert_true(dagger.rotation_step == 0, "Dagger rotation restored to 0")
	_assert_true(dagger.uid == original_uid, "Dagger UID intact")

	# --- TEST 8: Rollback on drag abort (out-of-bounds release) ---
	print("--- Test 8: Drag Abort Rollback ---")
	var drag_tx := MoveTransaction.begin(blade, "ALTAR_GRID")
	drag_tx.rotate_clockwise()
	# Simulate release outside valid UI
	drag_tx.rollback()
	_assert_true(blade.grid_pos == Vector2i(1, 2), "Blade restored to (1, 2) after drag abort")
	_assert_true(blade.rotation_step == 0, "Blade rotation restored to step 0")

	# --- TEST 9: Adjacency synergies recalculate correctly ---
	print("--- Test 9: Adjacency Synergy Recalculation on Move ---")
	var fire_rune := ItemInstance.new(fire_rune_data, Vector2i(0, 0), 0)
	var wolf_core := ItemInstance.new(wolf_core_data, Vector2i(1, 0), 0) # Adjacent horizontally
	var syn_items: Array[ItemInstance] = [fire_rune, wolf_core]
	_assert_true(grid_mgr.are_items_adjacent(fire_rune, wolf_core), "Adjacent items detected when adjacent at (0,0) and (1,0)")
	
	# Move fire rune away to (0, 3)
	var syn_tx := MoveTransaction.begin(fire_rune, "ALTAR_GRID")
	syn_tx.commit(Vector2i(0, 3), grid_mgr, syn_items)
	_assert_true(not grid_mgr.are_items_adjacent(fire_rune, wolf_core), "Synergy deactivates when fire rune moved away to (0, 3)")
	
	# Move fire rune back to (1, 1) (adjacent vertically to wolf core at (1, 0))
	var syn_back_tx := MoveTransaction.begin(fire_rune, "ALTAR_GRID")
	syn_back_tx.commit(Vector2i(1, 1), grid_mgr, syn_items)
	_assert_true(grid_mgr.are_items_adjacent(fire_rune, wolf_core), "Synergy reactivates when moved back adjacent at (1, 1)")

	# --- TEST 10: Save/Load persistence preserves moved item position, rotation, and stats ---
	print("--- Test 10: Profile & Run State Save/Load Persistence ---")
	var save_item := ItemInstance.new(blade_data, Vector2i(2, 1), 1) # 90 deg rotation
	save_item.rarity = "epic"
	save_item.upgrade_level = 5
	save_item.custom_stat_modifiers = {"bonus_crit": 0.15}
	var save_dict := save_item.to_dict()
	
	var loaded_item := ItemInstance.from_dict(save_dict)
	_assert_true(loaded_item != null, "Item successfully restored from serialized dict")
	_assert_true(loaded_item.grid_pos == Vector2i(2, 1), "Restored grid pos is (2, 1)")
	_assert_true(loaded_item.rotation_step == 1, "Restored rotation is 1 (90 deg)")
	_assert_true(loaded_item.rarity == "epic", "Restored rarity is 'epic'")
	_assert_true(loaded_item.upgrade_level == 5, "Restored upgrade level is 5")
	_assert_true(loaded_item.custom_stat_modifiers.get("bonus_crit", 0.0) == 0.15, "Restored custom stat modifiers match")
	_assert_true(loaded_item.uid == save_item.uid, "Restored UID matches original")
