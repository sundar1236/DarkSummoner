class_name MoveTransaction
extends RefCounted

# Atomic transaction for moving and rotating items on the Altar Grid / Summoning Circle.
# Protects against self-collision, boundary overflow, premature rotation mutations,
# and item loss on canceled drags or failed drops.

enum SourceType {
	ALTAR_GRID,
	BACKPACK
}

var item: ItemInstance = null
var source_type: String = "ALTAR_GRID"
var original_origin: Vector2i = Vector2i.ZERO
var original_rotation: int = 0

var preview_origin: Vector2i = Vector2i.ZERO
var preview_rotation: int = 0
var is_active: bool = false

# Item integrity snapshots
var uid_snapshot: String = ""
var rarity_snapshot: String = ""
var upgrade_level_snapshot: int = 0
var custom_stat_modifiers_snapshot: Dictionary = {}

static func begin(p_item: ItemInstance, p_source: String = "ALTAR_GRID") -> MoveTransaction:
	var tx := MoveTransaction.new()
	tx.item = p_item
	tx.source_type = p_source
	tx.original_origin = p_item.grid_pos
	tx.original_rotation = p_item.rotation_step
	tx.preview_origin = p_item.grid_pos
	tx.preview_rotation = p_item.rotation_step
	tx.uid_snapshot = p_item.uid
	tx.rarity_snapshot = p_item.rarity
	tx.upgrade_level_snapshot = p_item.upgrade_level
	tx.custom_stat_modifiers_snapshot = p_item.custom_stat_modifiers.duplicate(true)
	tx.is_active = true
	return tx

func rotate_clockwise() -> void:
	if not is_active:
		return
	preview_rotation = posmod(preview_rotation + 1, 4)

func get_preview_shape() -> Array[Vector2i]:
	if not item or not item.data or item.data.shape.is_empty():
		return [Vector2i.ZERO]
	
	var raw_cells: Array[Vector2i] = []
	for cell in item.data.shape:
		var x: int = cell.x
		var y: int = cell.y
		match preview_rotation:
			0:
				raw_cells.append(Vector2i(x, y))
			1:
				raw_cells.append(Vector2i(-y, x))
			2:
				raw_cells.append(Vector2i(-x, -y))
			3:
				raw_cells.append(Vector2i(y, -x))
				
	var min_x: int = 999999
	var min_y: int = 999999
	for c in raw_cells:
		if c.x < min_x: min_x = c.x
		if c.y < min_y: min_y = c.y
		
	var normalized: Array[Vector2i] = []
	for c in raw_cells:
		normalized.append(Vector2i(c.x - min_x, c.y - min_y))
	return normalized

func get_preview_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in get_preview_shape():
		result.append(preview_origin + offset)
	return result

func validate_destination(dest: Vector2i, grid_mgr: GridManager, existing_items: Array[ItemInstance]) -> bool:
	if not is_active or not item or not grid_mgr:
		return false
	preview_origin = dest
	
	# Check bounds
	for offset in get_preview_shape():
		var c := dest + offset
		if not grid_mgr.is_cell_in_bounds(c):
			return false
			
	# Check overlap against all other items (excluding self)
	var test_cells := get_preview_occupied_cells()
	for other in existing_items:
		if other == item:
			continue
		for oc in other.get_occupied_cells():
			if test_cells.has(oc):
				return false
				
	return true

func can_commit(dest: Vector2i, grid_mgr: GridManager, existing_items: Array[ItemInstance]) -> bool:
	return validate_destination(dest, grid_mgr, existing_items)

func commit(dest: Vector2i, grid_mgr: GridManager, existing_items: Array[ItemInstance]) -> bool:
	if not is_active:
		return false
	if not validate_destination(dest, grid_mgr, existing_items):
		rollback()
		return false
		
	# Apply final coordinates and rotation
	item.grid_pos = dest
	item.rotation_step = preview_rotation
	
	# Ensure snapshots and integrity preserved
	item.uid = uid_snapshot
	item.rarity = rarity_snapshot
	item.upgrade_level = upgrade_level_snapshot
	item.custom_stat_modifiers = custom_stat_modifiers_snapshot.duplicate(true)
	
	is_active = false
	return true

func rollback() -> void:
	if not is_active or not item:
		return
	item.grid_pos = original_origin
	item.rotation_step = original_rotation
	item.uid = uid_snapshot
	item.rarity = rarity_snapshot
	item.upgrade_level = upgrade_level_snapshot
	item.custom_stat_modifiers = custom_stat_modifiers_snapshot.duplicate(true)
	preview_origin = original_origin
	preview_rotation = original_rotation
	is_active = false
