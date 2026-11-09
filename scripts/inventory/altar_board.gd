class_name AltarBoard
extends Control

# Functional Dark-Fantasy Summoning Circle Altar (Phase 2).
# Replaces the square grid with a centered, circular ritual arrangement:
# - Concentric animated arcane rings, rotating ancient runes, and floor sigil.
# - Chibi Hero rendered in the center with breathing bob and spirit companion.
# - 13 Sockets:
#   * 8 Outer Hex Rune Sockets (4 left arc, 4 right arc)
#   * 2 Inner Spirit Sockets flanking the hero
#   * 3 Diamond Core Sockets along the bottom arc
# - Connected to real inventory data (GameManager.altar_items as single source of truth).
# - Compatible with MoveTransaction, item selection, drag-and-drop, tap-to-move,
#   rotation, rollback, active synergy conduits, and save/load persistence.

signal item_selected(item: ItemInstance, source: String)
signal socket_clicked(socket_id: int)
signal cell_clicked(grid_pos: Vector2i)

@export var inventory_view: InventoryView

# 13 Sockets Configuration
const SOCKET_DEFS: Array[Dictionary] = [
	# Outer Left Arc (0..3)
	{
		"id": 0, "name": "Northwest Rune Socket", "type": "rune",
		"angle_deg": 220.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(0, 0),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [1, 8]
	},
	{
		"id": 1, "name": "West-Northwest Rune Socket", "type": "rune",
		"angle_deg": 195.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(0, 1),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [0, 2, 8]
	},
	{
		"id": 2, "name": "West-Southwest Rune Socket", "type": "rune",
		"angle_deg": 165.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(0, 2),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [1, 3, 8]
	},
	{
		"id": 3, "name": "Southwest Rune Socket", "type": "rune",
		"angle_deg": 140.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(0, 3),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [2, 10]
	},
	# Outer Right Arc (4..7)
	{
		"id": 4, "name": "Northeast Rune Socket", "type": "rune",
		"angle_deg": 320.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(3, 0),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [5, 9]
	},
	{
		"id": 5, "name": "East-Northeast Rune Socket", "type": "rune",
		"angle_deg": 345.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(3, 1),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [4, 6, 9]
	},
	{
		"id": 6, "name": "East-Southeast Rune Socket", "type": "rune",
		"angle_deg": 15.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(3, 2),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [5, 7, 9]
	},
	{
		"id": 7, "name": "Southeast Rune Socket", "type": "rune",
		"angle_deg": 40.0, "radius_ratio": 0.88, "shape": "hex",
		"virtual_cell": Vector2i(3, 3),
		"supported_tags": ["rune", "weapon", "defense", "shadow", "fire", "storm", "soul", "accessory"],
		"unlocked_by_default": true, "connections": [6, 11]
	},
	# Inner Spirit Sockets (8..9) - Flanking Hero
	{
		"id": 8, "name": "Left Spirit Vessel", "type": "spirit",
		"angle_deg": 180.0, "radius_ratio": 0.46, "shape": "circle",
		"virtual_cell": Vector2i(1, 1),
		"supported_tags": ["core", "rune", "spirit", "essence", "accessory", "weapon", "defense"],
		"unlocked_by_default": true, "connections": [0, 1, 2, 9, 12]
	},
	{
		"id": 9, "name": "Right Spirit Vessel", "type": "spirit",
		"angle_deg": 0.0, "radius_ratio": 0.46, "shape": "circle",
		"virtual_cell": Vector2i(2, 1),
		"supported_tags": ["core", "rune", "spirit", "essence", "accessory", "weapon", "defense"],
		"unlocked_by_default": true, "connections": [4, 5, 6, 8, 12]
	},
	# Lower Diamond Core Sockets (10..12)
	{
		"id": 10, "name": "Left Abyssal Core", "type": "core",
		"angle_deg": 115.0, "radius_ratio": 0.80, "shape": "diamond",
		"virtual_cell": Vector2i(1, 3),
		"supported_tags": ["core", "catalyst", "diamond", "rune", "weapon", "defense"],
		"unlocked_by_default": false, # Unlocks with Altar Expand
		"connections": [3, 11, 12]
	},
	{
		"id": 11, "name": "Right Abyssal Core", "type": "core",
		"angle_deg": 65.0, "radius_ratio": 0.80, "shape": "diamond",
		"virtual_cell": Vector2i(2, 3),
		"supported_tags": ["core", "catalyst", "diamond", "rune", "weapon", "defense"],
		"unlocked_by_default": false, # Unlocks with Altar Expand
		"connections": [7, 10, 12]
	},
	{
		"id": 12, "name": "Prime Apex Core", "type": "core",
		"angle_deg": 90.0, "radius_ratio": 0.74, "shape": "diamond",
		"virtual_cell": Vector2i(1, 2),
		"supported_tags": ["core", "catalyst", "diamond", "rune", "weapon", "defense"],
		"unlocked_by_default": true,
		"connections": [8, 9, 10, 11]
	}
]

const SOCKET_TO_CELL: Dictionary = {
	0: Vector2i(0, 0),
	1: Vector2i(0, 1),
	2: Vector2i(0, 2),
	3: Vector2i(0, 3),
	4: Vector2i(3, 0),
	5: Vector2i(3, 1),
	6: Vector2i(3, 2),
	7: Vector2i(3, 3),
	8: Vector2i(1, 1),
	9: Vector2i(2, 1),
	10: Vector2i(1, 3),
	11: Vector2i(2, 3),
	12: Vector2i(1, 2)
}

const CELL_TO_SOCKET: Dictionary = {
	Vector2i(0, 0): 0,
	Vector2i(0, 1): 1,
	Vector2i(0, 2): 2,
	Vector2i(0, 3): 3,
	Vector2i(3, 0): 4,
	Vector2i(3, 1): 5,
	Vector2i(3, 2): 6,
	Vector2i(3, 3): 7,
	Vector2i(1, 1): 8,
	Vector2i(2, 1): 9,
	Vector2i(1, 3): 10,
	Vector2i(2, 3): 11,
	Vector2i(1, 2): 12,
	# Fallback mappings for any non-standard cell
	Vector2i(1, 0): 0,
	Vector2i(2, 0): 4,
	Vector2i(2, 2): 12,
	Vector2i(0, 4): 3,
	Vector2i(4, 0): 4
}

# Drag & Relocation State
var is_dragging: bool = false
var drag_from_socket: int = -1
var hover_socket: int = -1
var drag_origin_cell: Vector2i = Vector2i(-999, -999)
var hover_cell: Vector2i = Vector2i(-999, -999)

# Animation clock
var _anim_time: float = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(380, 380)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

# Geometry helper: returns center and radius of the summoning circle
func _get_circle_center() -> Vector2:
	return size * 0.5

func _get_circle_radius() -> float:
	return minf(size.x, size.y) * 0.5 - 20.0

func get_socket_pos(socket_id: int) -> Vector2:
	if socket_id < 0 or socket_id >= SOCKET_DEFS.size():
		return _get_circle_center()
	var def := SOCKET_DEFS[socket_id]
	var center := _get_circle_center()
	var r := _get_circle_radius() * float(def.get("radius_ratio", 0.85))
	var ang_rad := deg_to_rad(float(def.get("angle_deg", 0.0)))
	return center + Vector2(cos(ang_rad), sin(ang_rad)) * r

func get_socket_at_pos(pos: Vector2) -> int:
	var best_id := -1
	var min_dist := 36.0 # Touch target radius
	for i in range(SOCKET_DEFS.size()):
		var spos := get_socket_pos(i)
		var d := pos.distance_to(spos)
		if d < min_dist:
			min_dist = d
			best_id = i
	return best_id

# Backward compatibility with GridManager cell lookups
func _get_cell_at_pos(pos: Vector2) -> Vector2i:
	var s_id := get_socket_at_pos(pos)
	if s_id != -1:
		return SOCKET_TO_CELL.get(s_id, Vector2i(-999, -999))
	return Vector2i(-999, -999)

func _get_socket_for_cell(cell: Vector2i) -> int:
	return CELL_TO_SOCKET.get(cell, -1)

func _get_item_in_socket(socket_id: int) -> ItemInstance:
	var target_cell: Vector2i = SOCKET_TO_CELL.get(socket_id, Vector2i(-999, -999))
	if target_cell == Vector2i(-999, -999):
		return null
	for item in GameManager.altar_items:
		if item.get_occupied_cells().has(target_cell) or item.grid_pos == target_cell:
			return item
	return null

func is_socket_unlocked(socket_id: int) -> bool:
	if socket_id < 0 or socket_id >= SOCKET_DEFS.size():
		return false
	var def := SOCKET_DEFS[socket_id]
	if def.get("unlocked_by_default", true):
		return true
	# Sockets 10 and 11 unlock via Sanctuary Altar Expansion or Floor 2+
	if SaveManager:
		var expand_lvl: int = SaveManager.permanent_upgrades.get("altar_expand", 0)
		var floor_lvl: int = SaveManager.highest_floor_unlocked
		if expand_lvl >= 1 or floor_lvl >= 2:
			return true
	return false

func is_item_compatible(item: ItemInstance, socket_id: int) -> bool:
	if not is_socket_unlocked(socket_id):
		return false
	if not item or not item.data:
		return false
	var def := SOCKET_DEFS[socket_id]
	var supported: Array = def.get("supported_tags", [])
	for t in item.data.tags:
		if supported.has(t):
			return true
	# Socket compatibility must come from the item's actual tags. Checking whether
	# the socket supports a generic tag such as "rune" or "weapon" would make every
	# item compatible with that socket, even when the item has no matching tag.
	return false

func _draw() -> void:
	var center := _get_circle_center()
	var radius := _get_circle_radius()
	var t := _anim_time
	var pulse := (1.0 + sin(t * 3.5)) * 0.5
	
	# -------------------------------------------------------------
	# 1. Base Ritual Dais & Concentric Arcane Rings
	# -------------------------------------------------------------
	# Outer dark obsidian dais
	draw_circle(center, radius + 12.0, Color(0.04, 0.05, 0.10, 0.94))
	draw_arc(center, radius + 12.0, 0.0, TAU, 64, Color(0.85, 0.72, 0.25, 0.85), 2.5, true) # Gold rim
	draw_arc(center, radius + 8.0, 0.0, TAU, 64, Color(0.2, 0.65, 1.0, 0.35 * pulse), 1.5, true)
	
	# Primary Outer Ritual Ring with Rotating Runes
	draw_arc(center, radius * 0.88, 0.0, TAU, 64, Color(0.18, 0.45, 0.85, 0.65), 2.0, true)
	draw_arc(center, radius * 0.88 + 3.0, 0.0, TAU, 64, Color(0.35, 0.8, 1.0, 0.25 * pulse), 1.0, true)
	
	var rune_rot := t * 0.35
	for i in range(16):
		var ang := rune_rot + float(i) * (TAU / 16.0)
		var rp := center + Vector2(cos(ang), sin(ang)) * (radius * 0.88)
		draw_circle(rp, 2.0, Color(0.4, 0.85, 1.0, 0.7))
		
	# Middle Conduit Arc connecting Outer Sockets
	draw_arc(center, radius * 0.66, 0.0, TAU, 48, Color(0.12, 0.3, 0.6, 0.35), 1.5, true)
	
	# Inner Magic Circle surrounding Hero with Rotating Octagram Star
	var star_radius := radius * 0.44
	draw_arc(center, star_radius, 0.0, TAU, 48, Color(0.25, 0.7, 1.0, 0.75), 1.8, true)
	draw_arc(center, star_radius - 4.0, 0.0, TAU, 48, Color(0.15, 0.4, 0.8, 0.4 * pulse), 1.0, true)
	
	var star_rot := -t * 0.22
	for i in range(8):
		var a1 := star_rot + float(i) * (TAU / 8.0)
		var a2 := star_rot + float((i + 3) % 8) * (TAU / 8.0)
		var p1 := center + Vector2(cos(a1), sin(a1)) * (star_radius - 2.0)
		var p2 := center + Vector2(cos(a2), sin(a2)) * (star_radius - 2.0)
		draw_line(p1, p2, Color(0.2, 0.6, 1.0, 0.28), 1.2)
		draw_circle(p1, 2.0, Color(0.6, 0.9, 1.0, 0.6))
		
	# Ethereal floating soul motes
	for m in range(6):
		var m_ang := float(m) * (TAU / 6.0) + sin(t * 1.5 + float(m)) * 0.3
		var m_rad := star_radius * 0.75 + sin(t * 2.0 + float(m) * 2.0) * 12.0
		var mp := center + Vector2(cos(m_ang), sin(m_ang)) * m_rad
		draw_circle(mp, 1.8, Color(0.5, 0.9, 1.0, 0.5 * pulse))

	# -------------------------------------------------------------
	# 2. Central 2.5D Chibi Hero & Spirit Companion
	# -------------------------------------------------------------
	_draw_central_hero(center, t)

	# -------------------------------------------------------------
	# 3. Active Synergy Conduit Beams
	# -------------------------------------------------------------
	_draw_synergy_conduits(t, pulse)

	# -------------------------------------------------------------
	# 4. Sockets Rendering (13 Sockets)
	# -------------------------------------------------------------
	var sel_item: ItemInstance = inventory_view.selected_item if inventory_view else null
	var candidate_socket := -1
	if is_dragging and hover_socket != -1:
		candidate_socket = hover_socket
	elif inventory_view and inventory_view.is_move_mode and inventory_view.preview_cell != Vector2i(-999, -999):
		candidate_socket = _get_socket_for_cell(inventory_view.preview_cell)

	for i in range(SOCKET_DEFS.size()):
		var def := SOCKET_DEFS[i]
		var spos := get_socket_pos(i)
		var is_unlocked := is_socket_unlocked(i)
		var item_in_sock := _get_item_in_socket(i)
		var is_selected := (sel_item != null and item_in_sock == sel_item)
		var is_candidate := (candidate_socket == i)
		var shape: String = def.get("shape", "hex")
		
		# Determine socket highlight mode
		var is_valid_target := false
		var is_invalid_target := false
		
		if sel_item:
			var can_accept := is_item_compatible(sel_item, i)
			var is_empty_or_self := (item_in_sock == null or item_in_sock == sel_item)
			
			if is_empty_or_self and can_accept:
				is_valid_target = true
			elif not can_accept or (item_in_sock != null and item_in_sock != sel_item and not GameManager.can_merge_items(sel_item, item_in_sock)):
				is_invalid_target = true

		# Draw the socket shape
		_draw_socket_shape(spos, shape, is_unlocked, item_in_sock, is_selected, is_valid_target, is_invalid_target, is_candidate, pulse)
		
		# Draw socket contents
		if not is_unlocked:
			# Padlock icon for locked sockets
			draw_string(ThemeDB.fallback_font, spos + Vector2(-9, 6), "🔒", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.65, 0.65, 0.75, 0.8))
		elif item_in_sock and item_in_sock.data:
			# Draw real item artwork, stars and upgrade badge
			_draw_socket_item(spos, item_in_sock, is_selected, is_candidate)
		else:
			# Empty socket arcane glyph
			_draw_empty_glyph(spos, shape)

	# -------------------------------------------------------------
	# 5. Live Ghost Preview on Candidate Socket
	# -------------------------------------------------------------
	if sel_item and sel_item.data and candidate_socket != -1 and is_socket_unlocked(candidate_socket):
		var cpos := get_socket_pos(candidate_socket)
		var is_valid := is_item_compatible(sel_item, candidate_socket)
		var ghost_col := Color(0.2, 1.0, 0.45, 0.85) if is_valid else Color(1.0, 0.3, 0.35, 0.85)
		
		# Translucent ghost icon
		var tex := sel_item.data.get_icon_texture()
		if tex:
			var g_rect := Rect2(cpos - Vector2(20, 20), Vector2(40, 40))
			draw_texture_rect(tex, g_rect, false, Color(ghost_col.r, ghost_col.g, ghost_col.b, 0.75))
		draw_arc(cpos, 28.0, 0.0, TAU, 32, ghost_col, 2.5, true)

func _draw_socket_shape(pos: Vector2, shape: String, unlocked: bool, item: ItemInstance, selected: bool, valid: bool, invalid: bool, candidate: bool, pulse: float) -> void:
	var r := 26.0
	var fill_color := Color(0.06, 0.08, 0.15, 0.94)
	var border_color := Color(0.25, 0.55, 0.9, 0.75)
	var border_width := 1.8
	
	if not unlocked:
		fill_color = Color(0.04, 0.04, 0.07, 0.9)
		border_color = Color(0.28, 0.26, 0.35, 0.5)
	elif selected:
		fill_color = Color(0.12, 0.16, 0.3, 0.95)
		border_color = Color(1.0, 0.88, 0.35, 0.85 + pulse * 0.15)
		border_width = 3.2
	elif candidate:
		border_color = Color(0.4, 1.0, 0.6, 1.0) if valid else Color(1.0, 0.3, 0.35, 1.0)
		fill_color = Color(0.1, 0.4, 0.2, 0.5) if valid else Color(0.4, 0.1, 0.1, 0.5)
		border_width = 3.0
	elif valid:
		fill_color = Color(0.08, 0.32, 0.18, 0.45)
		border_color = Color(0.28, 0.95, 0.5, 0.85 + pulse * 0.15)
		border_width = 2.4
	elif invalid and (selected or candidate):
		fill_color = Color(0.3, 0.08, 0.12, 0.35)
		border_color = Color(0.9, 0.25, 0.3, 0.7)

	match shape:
		"hex":
			var pts := PackedVector2Array()
			for i in range(6):
				var a := float(i) * (PI / 3.0) - (PI / 6.0)
				pts.append(pos + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(pts, fill_color)
			draw_polyline(pts + PackedVector2Array([pts[0]]), border_color, border_width)
		"diamond":
			var pts := PackedVector2Array([
				pos + Vector2(0, -r * 1.15),
				pos + Vector2(r * 1.0, 0),
				pos + Vector2(0, r * 1.15),
				pos + Vector2(-r * 1.0, 0)
			])
			draw_colored_polygon(pts, fill_color)
			draw_polyline(pts + PackedVector2Array([pts[0]]), border_color, border_width)
		_: # circle / spirit
			draw_circle(pos, r, fill_color)
			draw_arc(pos, r, 0.0, TAU, 36, border_color, border_width, true)
			draw_arc(pos, r * 0.75, 0.0, TAU, 24, Color(border_color.r, border_color.g, border_color.b, 0.3), 1.0, true)

func _draw_socket_item(pos: Vector2, item: ItemInstance, selected: bool, candidate: bool) -> void:
	var d := item.data
	# Rarity border tint
	var rarity_col := Color(0.65, 0.7, 0.8, 1.0)
	match item.rarity:
		"rare": rarity_col = Color(0.2, 0.75, 1.0, 1.0)
		"epic": rarity_col = Color(0.85, 0.35, 1.0, 1.0)
		"legendary": rarity_col = Color(1.0, 0.85, 0.25, 1.0)
		
	# Draw item icon texture
	var icon_tex := d.get_icon_texture()
	var draw_size := 38.0
	var alpha: float = 0.45 if (selected and is_dragging) else 1.0
	
	if icon_tex:
		var rect := Rect2(pos - Vector2(draw_size, draw_size) * 0.5, Vector2(draw_size, draw_size))
		draw_texture_rect(icon_tex, rect, false, Color(1.0, 1.0, 1.0, alpha))
	else:
		# Text icon fallback
		var ico_str := "🗡" if d.tags.has("weapon") else ("🔥" if d.tags.has("fire") else "🐺")
		draw_string(ThemeDB.fallback_font, pos + Vector2(-9, 7), ico_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(1, 1, 1, alpha))

	# Tier Stars badge on top
	var stars_str := ""
	for s in range(d.tier): stars_str += "★"
	draw_string(ThemeDB.fallback_font, pos + Vector2(-16, -14), stars_str, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, Color(1.0, 0.85, 0.25, alpha))

func _draw_empty_glyph(pos: Vector2, shape: String) -> void:
	var glyph_col := Color(0.35, 0.5, 0.75, 0.45)
	draw_line(pos + Vector2(-6, 0), pos + Vector2(6, 0), glyph_col, 1.0)
	draw_line(pos + Vector2(0, -6), pos + Vector2(0, 6), glyph_col, 1.0)
	draw_circle(pos, 2.0, Color(0.4, 0.65, 0.95, 0.5))

func _draw_central_hero(center: Vector2, t: float) -> void:
	var bob := sin(t * 3.0) * 3.5
	var hero_pos := center + Vector2(0, 10.0 + bob)
	
	# Hero base shadow
	draw_circle(center + Vector2(0, 32), 24.0, Color(0.02, 0.04, 0.08, 0.85))
	
	var char_id := GameManager.current_character.id if GameManager and GameManager.current_character else "shadow_hunter"
	var iris_col := Color(0.7, 0.3, 1.0, 1.0)
	if char_id == "storm_reaper": iris_col = Color(0.2, 0.85, 1.0, 1.0)
	elif char_id == "soul_binder": iris_col = Color(0.25, 0.95, 0.6, 1.0)
	
	var tex := TextureLoader.get_texture("res://assets/sprites/characters/player_" + char_id + ".png")
	if tex:
		var spr_size := Vector2(88, 88)
		var spr_rect := Rect2(hero_pos - spr_size * 0.5 + Vector2(0, -6), spr_size)
		draw_texture_rect(tex, spr_rect, false)
	else:
		# Cape
		var cape_pts := PackedVector2Array([
			hero_pos + Vector2(-12, -8),
			hero_pos + Vector2(12, -8),
			hero_pos + Vector2(20, 26),
			hero_pos + Vector2(-20, 26)
		])
		draw_colored_polygon(cape_pts, Color(0.09, 0.08, 0.16, 0.95))
		
		# Torso & Tunic
		var tunic_pts := PackedVector2Array([
			hero_pos + Vector2(-10, -6),
			hero_pos + Vector2(10, -6),
			hero_pos + Vector2(14, 16),
			hero_pos + Vector2(-14, 16)
		])
		draw_colored_polygon(tunic_pts, Color(0.18, 0.22, 0.35, 1.0))
		draw_polyline(tunic_pts, Color(0.85, 0.72, 0.25, 0.85), 1.2)
		
		# Gold belt
		draw_rect(Rect2(hero_pos + Vector2(-9, 7), Vector2(18, 5)), Color(0.9, 0.78, 0.25, 1.0))
		draw_circle(hero_pos + Vector2(0, 9.5), 2.5, Color(0.95, 0.25, 0.25, 1.0))
		
		# Chibi Head
		var head_pos := hero_pos + Vector2(0, -26)
		draw_circle(head_pos, 20.0, Color(0.12, 0.1, 0.18, 1.0)) # Cowl/Hair
		draw_circle(head_pos + Vector2(0, 2), 15.0, Color(0.96, 0.85, 0.78, 1.0)) # Face
		
		draw_circle(head_pos + Vector2(-6, 2), 4.0, Color(0.15, 0.15, 0.22, 1.0))
		draw_circle(head_pos + Vector2(6, 2), 4.0, Color(0.15, 0.15, 0.22, 1.0))
		draw_circle(head_pos + Vector2(-6, 2), 2.5, iris_col)
		draw_circle(head_pos + Vector2(6, 2), 2.5, iris_col)
		draw_circle(head_pos + Vector2(-7, 1), 1.0, Color.WHITE)
		draw_circle(head_pos + Vector2(5, 1), 1.0, Color.WHITE)
		
		# Signature Weapon silhouette (Right hand)
		var weap_pos := hero_pos + Vector2(22, 2)
		draw_line(weap_pos + Vector2(0, 20), weap_pos + Vector2(0, -22), Color(0.4, 0.3, 0.2, 1.0), 2.5)
		var blade_pts := PackedVector2Array([
			weap_pos + Vector2(0, -22),
			weap_pos + Vector2(-16, -34),
			weap_pos + Vector2(-8, -14)
		])
		draw_colored_polygon(blade_pts, Color(0.85, 0.9, 1.0, 1.0))
		draw_polyline(blade_pts, Color(0.85, 0.7, 0.25, 1.0), 1.5)
	
	# Floating Elemental Spirit Companion
	var comp_pos := hero_pos + Vector2(-36, -34 + sin(t * 3.8) * 5.0)
	draw_circle(comp_pos, 10.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.3))
	draw_circle(comp_pos, 6.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.9))
	draw_circle(comp_pos + Vector2(-1.5, -1.5), 2.0, Color.WHITE)

func _draw_synergy_conduits(t: float, pulse: float) -> void:
	if not GameManager: return
	var items := GameManager.altar_items
	
	for i in range(items.size()):
		var item_a := items[i]
		for j in range(i + 1, items.size()):
			var item_b := items[j]
			var is_adjacent: bool = false
			if GameManager.grid_manager:
				is_adjacent = GameManager.grid_manager.are_items_adjacent(item_a, item_b)
				
			if is_adjacent:
				var s_a := _get_socket_for_cell(item_a.grid_pos)
				var s_b := _get_socket_for_cell(item_b.grid_pos)
				if s_a != -1 and s_b != -1:
					var pa := get_socket_pos(s_a)
					var pb := get_socket_pos(s_b)
					
					var beam_col := Color(0.35, 0.75, 1.0, 0.75)
					if (item_a.data.id == "wolf_core" and item_b.data.tags.has("fire")) or (item_b.data.id == "wolf_core" and item_a.data.tags.has("fire")):
						beam_col = Color(1.0, 0.5 + pulse * 0.2, 0.15, 0.9)
					elif item_a.data.tags.has("weapon") or item_b.data.tags.has("weapon"):
						beam_col = Color(1.0, 0.85, 0.3, 0.85)
						
					draw_line(pa, pb, beam_col, 4.0)
					draw_line(pa, pb, Color.WHITE, 1.5)

# -------------------------------------------------------------
# Input Handling & Touch Relocation Integration
# -------------------------------------------------------------
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_touch_down(event.position)
			else:
				_handle_touch_up(event.position)
	elif event is InputEventMouseMotion:
		if is_dragging:
			_handle_touch_motion(event.position)
	elif event is InputEventScreenTouch:
		if event.pressed:
			_handle_touch_down(event.position)
		else:
			_handle_touch_up(event.position)
	elif event is InputEventScreenDrag:
		_handle_touch_motion(event.position)

func _handle_touch_down(pos: Vector2) -> void:
	var s_id := get_socket_at_pos(pos)
	if s_id == -1:
		if inventory_view and inventory_view.is_move_mode:
			inventory_view.cancel_move_mode()
		return
		
	if not is_socket_unlocked(s_id):
		if AudioManager: AudioManager.play_sfx("ui_error")
		if inventory_view and inventory_view.has_method("show_toast"):
			inventory_view.show_toast("🔒 Core Socket: Unlocks via Sanctuary Altar Expansion")
		return
		
	var target_cell: Vector2i = SOCKET_TO_CELL.get(s_id, Vector2i(-999, -999))
	var clicked_item := _get_item_in_socket(s_id)
	socket_clicked.emit(s_id)
	cell_clicked.emit(target_cell)

	# Case 1: In active Move Mode
	if inventory_view and inventory_view.is_move_mode and inventory_view.selected_item:
		var sel := inventory_view.selected_item
		if is_item_compatible(sel, s_id) and GameManager.can_move_item_to(sel, target_cell):
			inventory_view.commit_move(target_cell)
			return
		elif clicked_item and clicked_item != sel and GameManager.can_merge_items(sel, clicked_item):
			var merged := GameManager.merge_items(sel, clicked_item)
			if merged:
				inventory_view.is_move_mode = false
				inventory_view._select_item(merged, "altar")
				inventory_view.refresh_inventory_ui()
				return
		else:
			if clicked_item and clicked_item != sel:
				inventory_view.cancel_move_mode()
				inventory_view._select_item(clicked_item, "altar")
			else:
				if AudioManager: AudioManager.play_sfx("ui_error")
		return

	# Case 2: Not in move mode, but an item was ALREADY selected
	if inventory_view and inventory_view.selected_item:
		var sel := inventory_view.selected_item
		if clicked_item:
			if clicked_item != sel:
				# Tapped another item: check merge
				if GameManager.can_merge_items(sel, clicked_item):
					var merged := GameManager.merge_items(sel, clicked_item)
					if merged:
						inventory_view._select_item(merged, "altar")
						inventory_view.refresh_inventory_ui()
						return
				else:
					# Select the other item and begin drag
					inventory_view._select_item(clicked_item, "altar")
					_initiate_drag(clicked_item, s_id)
					return
			else:
				# Tapped already-selected item: prepare drag
				_initiate_drag(sel, s_id)
				return
		else:
			# Tapped an EMPTY socket while an item is selected: Tap-to-move / Equip!
			if is_item_compatible(sel, s_id) and GameManager.can_move_item_to(sel, target_cell):
				inventory_view.commit_move(target_cell)
				return
			else:
				if AudioManager: AudioManager.play_sfx("ui_error")
			return

	# Case 3: No item was selected yet
	if clicked_item:
		if inventory_view:
			inventory_view._select_item(clicked_item, "altar")
		_initiate_drag(clicked_item, s_id)

func _initiate_drag(item: ItemInstance, sock_id: int) -> void:
	is_dragging = true
	drag_from_socket = sock_id
	hover_socket = sock_id
	drag_origin_cell = item.grid_pos
	hover_cell = item.grid_pos
	queue_redraw()

func _handle_touch_motion(pos: Vector2) -> void:
	if not is_dragging or not inventory_view or not inventory_view.selected_item:
		return
	var s_id := get_socket_at_pos(pos)
	if s_id != hover_socket:
		hover_socket = s_id
		if s_id != -1:
			var target_cell: Vector2i = SOCKET_TO_CELL.get(s_id, Vector2i(-999, -999))
			hover_cell = target_cell
			if inventory_view.is_move_mode:
				inventory_view.preview_cell = target_cell
		else:
			hover_cell = Vector2i(-999, -999)
		queue_redraw()

func _handle_touch_up(pos: Vector2) -> void:
	if not is_dragging:
		return

	# Resolve the destination from the release event itself. The final mouse/touch
	# position is not guaranteed to have produced a preceding motion event.
	var release_socket := get_socket_at_pos(pos)
	hover_socket = release_socket
	is_dragging = false

	if inventory_view and inventory_view.selected_item and release_socket != -1:
		if not _try_drop_on_socket(release_socket):
			if AudioManager: AudioManager.play_sfx("ui_error")

	# Releasing outside a socket cancels the relocation without changing the item.
	hover_socket = -1
	drag_from_socket = -1
	hover_cell = Vector2i(-999, -999)
	queue_redraw()

func _try_drop_on_socket(socket_id: int) -> bool:
	if not inventory_view or not inventory_view.selected_item:
		return false
	if socket_id < 0 or socket_id >= SOCKET_DEFS.size():
		return false
	if socket_id == drag_from_socket:
		return true

	var selected := inventory_view.selected_item
	var target_item := _get_item_in_socket(socket_id)
	if target_item and target_item != selected and GameManager.can_merge_items(selected, target_item):
		var merged := GameManager.merge_items(selected, target_item)
		if not merged:
			return false
		inventory_view.is_move_mode = false
		inventory_view._select_item(merged, "altar")
		inventory_view.refresh_inventory_ui()
		return true

	if not is_item_compatible(selected, socket_id):
		return false
	var target_cell: Vector2i = SOCKET_TO_CELL[socket_id]
	if not GameManager.can_move_item_to(selected, target_cell):
		return false
	return inventory_view.commit_move(target_cell)

func _find_best_placement_for_cell(item: ItemInstance, clicked_cell: Vector2i) -> Vector2i:
	for offset in item.get_rotated_shape():
		var candidate_top_left := clicked_cell - offset
		if GameManager.can_move_item_to(item, candidate_top_left):
			return candidate_top_left
	return Vector2i(-999, -999)
