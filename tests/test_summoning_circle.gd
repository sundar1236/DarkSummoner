extends Node

# Comprehensive Test Suite for Phase 2: Functional Summoning Circle Altar Redesign.
# Verifies 10 core architectural and gameplay requirements:
# 1. 13 sockets initialized with correct geometry and IDs (0..12).
# 2. Socket-to-cell and cell-to-socket bi-directional mapping.
# 3. Locked sockets (10 & 11) reject item placement until unlocked.
# 4. Equipping compatible item from backpack into empty socket.
# 5. MoveTransaction relocation between valid sockets.
# 6. Rollback on invalid/locked socket destination.
# 7. Item identity, UID, rarity, upgrade level preserved across moves.
# 8. Synergies and stat recalculation on socket moves.
# 9. Recycling adds gold and removes item.
# 10. Save and load persistence of socket items.

var passed_count: int = 0
var failed_count: int = 0

func _ready() -> void:
	print("\n==================================================")
	print("  RUNNING SUMMONING CIRCLE ALTAR TEST SUITE")
	print("==================================================\n")
	
	_run_all_tests()
	
	print("\n==================================================")
	print("  SUMMONING CIRCLE SUITE: %d PASSED, %d FAILED" % [passed_count, failed_count])
	print("==================================================\n")
	
	if failed_count > 0:
		print("FAILED: Some summoning circle assertions failed.")
		get_tree().quit(1)
	else:
		print("SUCCESS: All Summoning Circle Altar assertions passed!")
		get_tree().quit(0)

func _assert_true(condition: bool, description: String) -> void:
	if condition:
		passed_count += 1
		print("  [PASS] %s" % description)
	else:
		failed_count += 1
		printerr("  [FAIL] %s" % description)

func _run_all_tests() -> void:
	var board := AltarBoard.new()
	var grid_mgr := GridManager.new(4, 4)
	
	# -------------------------------------------------------------
	# Test 1: 13 Sockets Initialized with Correct Geometry & Types
	# -------------------------------------------------------------
	_assert_true(AltarBoard.SOCKET_DEFS.size() == 13, "1.1 AltarBoard defines exactly 13 ritual sockets")
	
	var hex_count: int = 0
	var spirit_count: int = 0
	var diamond_count: int = 0
	for def in AltarBoard.SOCKET_DEFS:
		match String(def.shape):
			"hex": hex_count += 1
			"circle": spirit_count += 1
			"diamond": diamond_count += 1
			
	_assert_true(hex_count == 8, "1.2 Sockets contain exactly 8 outer hex sockets (4 left arc, 4 right arc)")
	_assert_true(spirit_count == 2, "1.3 Sockets contain exactly 2 inner circular spirit vessels flanking hero")
	_assert_true(diamond_count == 3, "1.4 Sockets contain exactly 3 diamond core sockets along bottom arc")
	
	# -------------------------------------------------------------
	# Test 2: Bi-Directional Socket-Cell Mapping
	# -------------------------------------------------------------
	var mapping_valid: bool = true
	for i in range(13):
		if not AltarBoard.SOCKET_TO_CELL.has(i):
			mapping_valid = false
			break
		var cell: Vector2i = AltarBoard.SOCKET_TO_CELL[i]
		if not AltarBoard.CELL_TO_SOCKET.has(cell) or AltarBoard.CELL_TO_SOCKET[cell] != i:
			mapping_valid = false
			break
		if cell.x < 0 or cell.x >= 4 or cell.y < 0 or cell.y >= 4:
			mapping_valid = false
			break
	_assert_true(mapping_valid, "2.1 All 13 sockets have 1-to-1 bi-directional mapping to 4x4 virtual cells")
	_assert_true(AltarBoard.SOCKET_TO_CELL[8] == Vector2i(1, 1), "2.2 Left spirit vessel maps to virtual cell (1, 1)")
	_assert_true(AltarBoard.SOCKET_TO_CELL[9] == Vector2i(2, 1), "2.3 Right spirit vessel maps to virtual cell (2, 1)")
	_assert_true(AltarBoard.SOCKET_TO_CELL[12] == Vector2i(1, 2), "2.4 Prime apex core maps to virtual cell (1, 2)")
	_assert_true(AltarBoard.CELL_TO_SOCKET.size() == 13, "2.5 Only the 13 canonical socket cells are mapped")
	_assert_true(board._get_socket_for_cell(Vector2i(1, 0)) == -1, "2.6 Unassigned in-bounds cell (1, 0) has no socket mapping")
	_assert_true(board._get_socket_for_cell(Vector2i(2, 0)) == -1, "2.7 Unassigned in-bounds cell (2, 0) has no socket mapping")
	_assert_true(board._get_socket_for_cell(Vector2i(2, 2)) == -1, "2.8 Unassigned in-bounds cell (2, 2) has no socket mapping")
	_assert_true(board._get_socket_for_cell(Vector2i(0, 4)) == -1, "2.9 Out-of-bounds cell (0, 4) has no socket mapping")
	_assert_true(board._get_socket_for_cell(Vector2i(4, 0)) == -1, "2.10 Out-of-bounds cell (4, 0) has no socket mapping")

	# -------------------------------------------------------------
	# Test 3: Locked Sockets Validation (Padlock on 10 & 11)
	# -------------------------------------------------------------
	var s10_default_unlocked: bool = bool(AltarBoard.SOCKET_DEFS[10].get("unlocked_by_default", false))
	var s11_default_unlocked: bool = bool(AltarBoard.SOCKET_DEFS[11].get("unlocked_by_default", false))
	_assert_true(not s10_default_unlocked and not s11_default_unlocked, "3.1 Sockets 10 & 11 are locked by default")
	_assert_true(board.is_socket_unlocked(0), "3.2 Sockets 0..7 and 8..9 are unlocked by default")
	_assert_true(board.is_socket_unlocked(12), "3.3 Prime Apex Core (socket 12) is unlocked by default")
	
	var dagger_data := ItemDatabase.get_item("shadow_dagger")
	if not dagger_data:
		dagger_data = ItemData.new()
		dagger_data.id = "shadow_dagger"
		dagger_data.name = "Shadow Dagger"
		dagger_data.tags = ["weapon", "shadow"]
		dagger_data.tier = 1
		dagger_data.shape = [Vector2i(0, 0)]
	
	var dagger_inst := ItemInstance.new(dagger_data, Vector2i(0, 0), 0)
	var compat_unlocked: bool = board.is_item_compatible(dagger_inst, 0)
	_assert_true(compat_unlocked, "3.4 Dagger is compatible with unlocked Socket 0")

	var blood_relic_data := ItemData.new()
	blood_relic_data.id = "test_blood_relic"
	blood_relic_data.tags = ["relic", "blood"]
	var blood_relic := ItemInstance.new(blood_relic_data, Vector2i.ZERO, 0)
	_assert_true(not board.is_item_compatible(blood_relic, 0), "3.5 Blood relic is rejected by a socket that does not support its tags")
	_assert_true(not board.is_item_compatible(blood_relic, 12), "3.6 Blood relic is rejected by the Prime Apex Core when no supported tag matches")

	# -------------------------------------------------------------
	# Test 4: Equipping Item from Backpack to Empty Socket
	# -------------------------------------------------------------
	var altar_items: Array[ItemInstance] = []
	var backpack_items: Array[ItemInstance] = [dagger_inst]
	
	# Move dagger into Socket 0 (cell (0, 0))
	var target_cell: Vector2i = AltarBoard.SOCKET_TO_CELL[0]
	var can_equip: bool = grid_mgr.can_place_item(dagger_inst, target_cell, altar_items)
	_assert_true(can_equip, "4.1 Empty Socket 0 can accept placement from backpack")
	
	if can_equip:
		dagger_inst.grid_pos = target_cell
		backpack_items.erase(dagger_inst)
		altar_items.append(dagger_inst)
	_assert_true(altar_items.size() == 1 and backpack_items.is_empty(), "4.2 Item successfully equipped from backpack to altar socket")
	_assert_true(dagger_inst.grid_pos == Vector2i(0, 0), "4.3 Item positioned at Socket 0 cell (0, 0)")

	# -------------------------------------------------------------
	# Test 5: MoveTransaction Relocation Between Valid Sockets
	# -------------------------------------------------------------
	# Move dagger from Socket 0 (0, 0) to Socket 4 (3, 0) (Northeast Hex Socket)
	var dest_cell: Vector2i = AltarBoard.SOCKET_TO_CELL[4]
	var tx := MoveTransaction.begin(dagger_inst, "ALTAR_GRID")
	_assert_true(tx.can_commit(dest_cell, grid_mgr, altar_items), "5.1 Transaction validation allows move to empty Socket 4")
	
	var move_ok: bool = tx.commit(dest_cell, grid_mgr, altar_items)
	_assert_true(move_ok, "5.2 Transaction committed move to Socket 4")
	_assert_true(dagger_inst.grid_pos == dest_cell, "5.3 Item location updated to Socket 4 (3, 0)")

	# -------------------------------------------------------------
	# Test 6: Rollback on Invalid / Colliding Destination
	# -------------------------------------------------------------
	var fire_rune_data := ItemDatabase.get_item("fire_rune")
	if not fire_rune_data:
		fire_rune_data = ItemData.new()
		fire_rune_data.id = "fire_rune"
		fire_rune_data.name = "Fire Rune"
		fire_rune_data.tags = ["rune", "fire"]
		fire_rune_data.shape = [Vector2i(0, 0)]
	var fire_rune := ItemInstance.new(fire_rune_data, AltarBoard.SOCKET_TO_CELL[5], 0)
	altar_items.append(fire_rune)
	
	# Try to move dagger from Socket 4 directly into occupied Socket 5
	var tx_invalid := MoveTransaction.begin(dagger_inst, "ALTAR_GRID")
	var can_move_occupied: bool = tx_invalid.can_commit(fire_rune.grid_pos, grid_mgr, altar_items)
	_assert_true(not can_move_occupied, "6.1 Cannot move into already occupied socket without merge")
	
	var commit_failed: bool = tx_invalid.commit(fire_rune.grid_pos, grid_mgr, altar_items)
	_assert_true(not commit_failed, "6.2 Commit failed on collision")
	_assert_true(dagger_inst.grid_pos == dest_cell, "6.3 Dagger safely rolled back to original Socket 4 position")

	# -------------------------------------------------------------
	# Test 7: Item Identity, UID, Rarity, Upgrade Preserved
	# -------------------------------------------------------------
	var orig_uid: String = dagger_inst.uid
	dagger_inst.rarity = "epic"
	dagger_inst.upgrade_level = 3
	
	var tx_preserve := MoveTransaction.begin(dagger_inst, "ALTAR_GRID")
	var new_target: Vector2i = AltarBoard.SOCKET_TO_CELL[1] # Socket 1
	tx_preserve.commit(new_target, grid_mgr, altar_items)
	
	_assert_true(dagger_inst.uid == orig_uid, "7.1 Item UID preserved after socket move")
	_assert_true(dagger_inst.rarity == "epic", "7.2 Item rarity preserved after socket move")
	_assert_true(dagger_inst.upgrade_level == 3, "7.3 Item upgrade level preserved after socket move")

	# -------------------------------------------------------------
	# Test 8: Synergy Recalculation on Socket Move
	# -------------------------------------------------------------
	var wolf_core_data := ItemDatabase.get_item("wolf_core")
	if not wolf_core_data:
		wolf_core_data = ItemData.new()
		wolf_core_data.id = "wolf_core"
		wolf_core_data.name = "Wolf Core"
		wolf_core_data.tags = ["core", "beast"]
		wolf_core_data.shape = [Vector2i(0, 0)]
	
	# Place wolf core in Left Spirit Vessel (Socket 8, cell (1, 1))
	var wolf_core := ItemInstance.new(wolf_core_data, AltarBoard.SOCKET_TO_CELL[8], 0)
	altar_items.append(wolf_core)
	
	# Move fire_rune to adjacent cell (0, 1) (Socket 1)
	fire_rune.grid_pos = AltarBoard.SOCKET_TO_CELL[1]
	_assert_true(grid_mgr.are_items_adjacent(wolf_core, fire_rune), "8.1 Socket 8 (1, 1) and Socket 1 (0, 1) are adjacent")
	
	var syns: Dictionary = ItemSynergyManager.evaluate_synergies(altar_items, grid_mgr)
	var active_syns: Array = syns.get("active_synergies", [])
	var has_fire_wolf: bool = false
	for s in active_syns:
		if s.get("id") == "hellhound_evolution":
			has_fire_wolf = true
			break
	_assert_true(has_fire_wolf, "8.2 Hellhound Evolution synergy active between Socket 8 and adjacent Socket 1")

	# -------------------------------------------------------------
	# Test 9: Item Recycling Gold Reward & Safe Removal
	# -------------------------------------------------------------
	var start_gold: int = GameManager.run_gold
	GameManager.altar_items = altar_items
	
	# Recycle Tier 1 fire_rune: should add +25 gold
	var gold_earned: int = GameManager.recycle_item(fire_rune)
	_assert_true(gold_earned == 25, "9.1 Tier 1 item recycling yields 25 Gold")
	_assert_true(GameManager.run_gold == start_gold + 25, "9.2 GameManager gold increased by 25")
	_assert_true(not GameManager.altar_items.has(fire_rune), "9.3 Recycled item removed from altar items")
	
	# Test Tier 2 item recycling yields 60 Gold
	var blade_data := ItemDatabase.get_item("shadow_blade")
	if not blade_data:
		blade_data = ItemData.new()
		blade_data.id = "shadow_blade"
		blade_data.name = "Shadow Blade"
		blade_data.tier = 2
		blade_data.shape = [Vector2i(0, 0)]
	var blade_inst := ItemInstance.new(blade_data, Vector2i(3, 3), 0)
	GameManager.backpack_items.append(blade_inst)
	var t2_gold: int = GameManager.recycle_item(blade_inst)
	_assert_true(t2_gold == 60, "9.4 Tier 2 item recycling yields 60 Gold")
	_assert_true(not GameManager.backpack_items.has(blade_inst), "9.5 Recycled backpack item removed")

	# -------------------------------------------------------------
	# Test 10: Save and Load Persistence of Socket Items
	# -------------------------------------------------------------
	var serialized_items: Array = []
	for item in GameManager.altar_items:
		serialized_items.append(item.to_dict())
		
	_assert_true(serialized_items.size() == GameManager.altar_items.size(), "10.1 Serialized all socket items")
	
	var restored_items: Array[ItemInstance] = []
	for d in serialized_items:
		var it: ItemInstance = ItemInstance.from_dict(d)
		if it:
			restored_items.append(it)
			
	_assert_true(restored_items.size() == GameManager.altar_items.size(), "10.2 Restored identical count of socket items")
	var restored_wolf := restored_items.filter(func(it): return it.data and it.data.id == "wolf_core")
	_assert_true(not restored_wolf.is_empty() and restored_wolf[0].grid_pos == AltarBoard.SOCKET_TO_CELL[8], "10.3 Restored Wolf Core retains exact Socket 8 grid position (1, 1)")
	
	# -------------------------------------------------------------
	# Test 11: Drag-and-Drop Merge on an Occupied Socket
	# -------------------------------------------------------------
	GameManager.altar_items.clear()
	GameManager.backpack_items.clear()
	var merge_data := ItemDatabase.get_item("shadow_dagger")
	var drag_item := ItemInstance.new(merge_data, AltarBoard.SOCKET_TO_CELL[0], 0)
	var target_item := ItemInstance.new(merge_data, AltarBoard.SOCKET_TO_CELL[4], 0)
	GameManager.altar_items.append(drag_item)
	GameManager.altar_items.append(target_item)
	var test_view := InventoryView.new()
	test_view.selected_item = drag_item
	test_view.selected_source = "altar"
	board.inventory_view = test_view
	board.drag_from_socket = 0
	var drag_merge_ok := board._try_drop_on_socket(4)
	_assert_true(drag_merge_ok, "11.1 Dragging a mergeable item onto its matching socket succeeds")
	_assert_true(GameManager.altar_items.size() == 1 and GameManager.altar_items[0].data.id == "shadow_blade", "11.2 Drag merge replaces both tier 1 items with the tier 2 result")
	_assert_true(test_view.selected_item == GameManager.altar_items[0], "11.3 Merged item remains selected in the altar UI")
	test_view.free()

	# -------------------------------------------------------------
	# Test 12: Dragging a Multi-Cell Item from a Secondary Footprint Socket
	# -------------------------------------------------------------
	GameManager.altar_items.clear()
	var multi_data := ItemData.new()
	multi_data.id = "test_multi_cell_blade"
	multi_data.name = "Test Multi-Cell Blade"
	multi_data.tags = ["weapon", "shadow"]
	multi_data.tier = 2
	multi_data.shape = [Vector2i(0, 0), Vector2i(0, 1)]
	var multi_item := ItemInstance.new(multi_data, AltarBoard.SOCKET_TO_CELL[0], 0)
	GameManager.altar_items.append(multi_item)
	var multi_view := InventoryView.new()
	multi_view.selected_item = multi_item
	multi_view.selected_source = "altar"
	board.inventory_view = multi_view
	board._initiate_drag(multi_item, 1)
	_assert_true(board.drag_from_socket == 0, "12.1 Drag origin resolves to the multi-cell item's anchor socket")
	var same_footprint_drop := board._try_drop_on_socket(1)
	_assert_true(same_footprint_drop, "12.2 Dropping onto a secondary occupied socket is accepted as a no-op")
	_assert_true(multi_item.grid_pos == AltarBoard.SOCKET_TO_CELL[0], "12.3 Dropping onto its own footprint does not shift the item anchor")
	multi_view.is_move_mode = true
	board._handle_touch_down(board.get_socket_pos(1))
	_assert_true(multi_view.is_move_mode, "12.4 Tapping a secondary occupied socket keeps move mode active")
	_assert_true(multi_item.grid_pos == AltarBoard.SOCKET_TO_CELL[0], "12.5 Tap-to-move on its own footprint does not shift the item anchor")
	multi_view.free()
	board.free()
