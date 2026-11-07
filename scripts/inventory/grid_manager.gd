class_name GridManager
extends RefCounted

# Manages cell occupancy, placement validation, and adjacency detection for the Altar Grid.

var width: int = 4
var height: int = 4

func _init(w: int = 4, h: int = 4) -> void:
	width = w
	height = h

func is_cell_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < width and cell.y >= 0 and cell.y < height

# Checks if the item fits completely within the altar grid boundaries
func is_item_in_bounds(item: ItemInstance, pos: Vector2i) -> bool:
	for offset in item.get_rotated_shape():
		var c := pos + offset
		if not is_cell_in_bounds(c):
			return false
	return true

# Checks if placing the item at pos would overlap any other item in existing_items
func can_place_item(item: ItemInstance, pos: Vector2i, existing_items: Array[ItemInstance]) -> bool:
	return can_place_item_ignoring(item, pos, existing_items, item)

# Checks if placing the item at pos is valid, ignoring a specific item (e.g. self during move/relocate)
func can_place_item_ignoring(item: ItemInstance, pos: Vector2i, existing_items: Array[ItemInstance], ignore_item: ItemInstance = null) -> bool:
	if not is_item_in_bounds(item, pos):
		return false
	
	var test_cells: Array[Vector2i] = []
	for offset in item.get_rotated_shape():
		test_cells.append(pos + offset)
		
	for other in existing_items:
		if other == item or other == ignore_item:
			continue
		for other_cell in other.get_occupied_cells():
			if test_cells.has(other_cell):
				return false # Overlap detected!
				
	return true

# Returns all valid grid positions on the altar where item can be placed
func get_valid_placements(item: ItemInstance, existing_items: Array[ItemInstance], ignore_item: ItemInstance = null) -> Array[Vector2i]:
	var valid_list: Array[Vector2i] = []
	if not item:
		return valid_list
	for y in range(height):
		for x in range(width):
			var test_pos := Vector2i(x, y)
			if can_place_item_ignoring(item, test_pos, existing_items, ignore_item):
				valid_list.append(test_pos)
	return valid_list

# Finds which item occupies a given grid cell
func get_item_at_cell(cell: Vector2i, items: Array[ItemInstance]) -> ItemInstance:
	for item in items:
		if item.get_occupied_cells().has(cell):
			return item
	return null

# Checks orthogonal adjacency between two items
func are_items_adjacent(item_a: ItemInstance, item_b: ItemInstance) -> bool:
	if item_a == item_b:
		return false
	var cells_a := item_a.get_occupied_cells()
	var cells_b := item_b.get_occupied_cells()
	
	for ca in cells_a:
		for cb in cells_b:
			var dx: int = abs(ca.x - cb.x)
			var dy: int = abs(ca.y - cb.y)
			if (dx == 1 and dy == 0) or (dx == 0 and dy == 1):
				return true
	return false

# Returns all items orthogonally adjacent to target_item
func get_adjacent_items(target_item: ItemInstance, all_items: Array[ItemInstance]) -> Array[ItemInstance]:
	var adj: Array[ItemInstance] = []
	for other in all_items:
		if other != target_item and are_items_adjacent(target_item, other):
			adj.append(other)
	return adj

# Transactional Move API
func begin_move_transaction(item: ItemInstance, source: String = "ALTAR_GRID") -> MoveTransaction:
	return MoveTransaction.begin(item, source)

func preview_move_transaction(tx: MoveTransaction, dest: Vector2i, existing_items: Array[ItemInstance]) -> bool:
	if not tx:
		return false
	return tx.validate_destination(dest, self, existing_items)

func rotate_active_transaction(tx: MoveTransaction) -> void:
	if tx:
		tx.rotate_clockwise()

func commit_move_transaction(tx: MoveTransaction, dest: Vector2i, existing_items: Array[ItemInstance]) -> bool:
	if not tx:
		return false
	return tx.commit(dest, self, existing_items)

func rollback_move_transaction(tx: MoveTransaction) -> void:
	if tx:
		tx.rollback()
