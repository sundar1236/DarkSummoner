class_name ItemInstance
extends RefCounted

# Runtime instance of an item in the Altar or Backpack.
# Handles position, rotation (0, 90, 180, 270), rotated shape calculations,
# and preserves uid, rarity, upgrade level, and custom stat modifiers during moves.

var data: ItemData
var grid_pos: Vector2i = Vector2i.ZERO # Coordinates on altar grid
var rotation_step: int = 0 # 0 = 0 deg, 1 = 90 deg, 2 = 180 deg, 3 = 270 deg
var uid: String = ""
var rarity: String = "common"
var upgrade_level: int = 0
var custom_stat_modifiers: Dictionary = {}

static var _uid_counter: int = 0

func _init(p_data: ItemData, p_grid_pos: Vector2i = Vector2i.ZERO, p_rot: int = 0, p_uid: String = "") -> void:
	data = p_data
	grid_pos = p_grid_pos
	rotation_step = p_rot % 4
	if p_uid.is_empty():
		_uid_counter += 1
		var item_id := p_data.id if p_data else "item"
		uid = "%s_%d_%d" % [item_id, Time.get_ticks_msec(), _uid_counter]
	else:
		uid = p_uid
	
	if p_data:
		match p_data.tier:
			1: rarity = "common"
			2: rarity = "rare"
			3: rarity = "epic"
			4: rarity = "legendary"
			_: rarity = "mythic"

func rotate_clockwise() -> void:
	rotation_step = (rotation_step + 1) % 4

func to_dict() -> Dictionary:
	return {
		"item_id": data.id if data else "",
		"grid_pos_x": grid_pos.x,
		"grid_pos_y": grid_pos.y,
		"rotation_step": rotation_step,
		"uid": uid,
		"rarity": rarity,
		"upgrade_level": upgrade_level,
		"custom_stat_modifiers": custom_stat_modifiers.duplicate(true)
	}

static func from_dict(dict: Dictionary) -> ItemInstance:
	var item_id: String = dict.get("item_id", "")
	var d := ItemDatabase.get_item(item_id)
	if not d:
		return null
	var pos := Vector2i(dict.get("grid_pos_x", 0), dict.get("grid_pos_y", 0))
	var rot: int = dict.get("rotation_step", 0)
	var saved_uid: String = dict.get("uid", "")
	var inst := ItemInstance.new(d, pos, rot, saved_uid)
	inst.rarity = dict.get("rarity", "common")
	inst.upgrade_level = dict.get("upgrade_level", 0)
	inst.custom_stat_modifiers = dict.get("custom_stat_modifiers", {})
	return inst

# Returns the relative cell offsets of the item, rotated and normalized to (0,0) origin
func get_rotated_shape() -> Array[Vector2i]:
	if not data or data.shape.is_empty():
		return [Vector2i.ZERO]
	
	var raw_cells: Array[Vector2i] = []
	for cell in data.shape:
		var x: int = cell.x
		var y: int = cell.y
		
		match rotation_step:
			0:
				raw_cells.append(Vector2i(x, y))
			1: # 90 deg clockwise: (x, y) -> (-y, x)
				raw_cells.append(Vector2i(-y, x))
			2: # 180 deg: (x, y) -> (-x, -y)
				raw_cells.append(Vector2i(-x, -y))
			3: # 270 deg: (x, y) -> (y, -x)
				raw_cells.append(Vector2i(y, -x))
				
	# Normalize so minimum x and y are 0
	var min_x: int = 999999
	var min_y: int = 999999
	for c in raw_cells:
		if c.x < min_x: min_x = c.x
		if c.y < min_y: min_y = c.y
		
	var normalized: Array[Vector2i] = []
	for c in raw_cells:
		normalized.append(Vector2i(c.x - min_x, c.y - min_y))
		
	return normalized

# Returns all absolute grid coordinates occupied by this item on the Altar
func get_occupied_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for offset in get_rotated_shape():
		result.append(grid_pos + offset)
	return result

func get_width_and_height() -> Vector2i:
	var shape: Array[Vector2i] = get_rotated_shape()
	var max_x: int = 0
	var max_y: int = 0
	for c in shape:
		if c.x > max_x: max_x = c.x
		if c.y > max_y: max_y = c.y
	return Vector2i(max_x + 1, max_y + 1)
