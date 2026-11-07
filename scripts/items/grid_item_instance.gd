class_name GridItemInstance
extends ItemInstance

# Compatibility alias subclassing ItemInstance
func _init(p_data: ItemData, p_grid_pos: Vector2i = Vector2i.ZERO, p_rot: int = 0, p_uid: String = "") -> void:
	super._init(p_data, p_grid_pos, p_rot, p_uid)
