class_name SummoningCircleView
extends Control

# Arcane Summoning Circle Altar (Sub-Tab 3 - Ref Image 4).
# Renders central hero in glowing blue arcane summoning circle,
# 8 Star-Hex Rune Sockets (4 left arc, 4 right arc),
# 2 Inner Spirit Sockets flanking hero,
# 3 Diamond Core Sockets along bottom arc,
# fully connected to MoveTransaction with live ghost preview and synergy lines.

signal socket_clicked(socket_id: int)
signal rune_moved(from_socket: int, to_socket: int)

const SOCKET_RADIUS_OUTER: float = 155.0
const SOCKET_RADIUS_INNER: float = 80.0
const SOCKET_RADIUS_BOTTOM: float = 145.0

var _anim_time: float = 0.0
var selected_socket: int = -1
var hover_socket: int = -1
var is_dragging_socket: bool = false
var drag_from_socket: int = -1

# Socket definitions:
# 0..3: Left Arc Hex Sockets
# 4..7: Right Arc Hex Sockets
# 8..9: Inner Spirit Sockets
# 10..12: Bottom Diamond Sockets
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
	Vector2i(1, 2): 12
}

var socket_positions: Array[Vector2] = []
var socket_items: Dictionary = {} # socket_id -> ItemInstance

func _ready() -> void:
	custom_minimum_size = Vector2(340, 340)
	_calculate_socket_positions()
	_populate_default_runes()

func _calculate_socket_positions() -> void:
	var center := size * 0.5
	if center == Vector2.ZERO:
		center = Vector2(170, 170)
		
	socket_positions.clear()
	# 0..3: Left arc (approx angles: 140°, 165°, 195°, 220° in radians)
	var left_angles := [2.44, 2.88, 3.40, 3.84]
	for a in left_angles:
		socket_positions.append(center + Vector2(cos(a), sin(a)) * SOCKET_RADIUS_OUTER)
		
	# 4..7: Right arc (approx angles: 40°, 15°, 345°, 320° in radians)
	var right_angles := [0.70, 0.26, 6.02, 5.58]
	for a in right_angles:
		socket_positions.append(center + Vector2(cos(a), sin(a)) * SOCKET_RADIUS_OUTER)
		
	# 8..9: Inner spirit sockets (left and right of hero)
	socket_positions.append(center + Vector2(-SOCKET_RADIUS_INNER, 0))
	socket_positions.append(center + Vector2(SOCKET_RADIUS_INNER, 0))
	
	# 10..12: Bottom diamond core sockets (approx 70°, 90°, 110°)
	var bot_angles := [1.22, 1.57, 1.92]
	for a in bot_angles:
		socket_positions.append(center + Vector2(cos(a), sin(a)) * SOCKET_RADIUS_BOTTOM)

func _populate_default_runes() -> void:
	socket_items.clear()
	if GameManager and not GameManager.altar_items.is_empty():
		for item in GameManager.altar_items:
			var s_id: int = CELL_TO_SOCKET.get(item.grid_pos, -1)
			if s_id != -1:
				socket_items[s_id] = item
	else:
		var f_rune := ItemDatabase.get_item("fire_rune")
		if f_rune:
			socket_items[0] = ItemInstance.new(f_rune, Vector2i(0, 0), 0)
		var w_core := ItemDatabase.get_item("wolf_core")
		if w_core:
			socket_items[1] = ItemInstance.new(w_core, Vector2i(0, 1), 0)
		var blade := ItemDatabase.get_item("shadow_blade")
		if blade:
			socket_items[4] = ItemInstance.new(blade, Vector2i(3, 0), 0)

func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	_calculate_socket_positions()
	var t := _anim_time
	var pulse := (1.0 + sin(t * 3.5)) * 0.5

	# 1. Outer Arcane Summoning Ring (Cyan / Deep Blue Glow)
	draw_circle(center, 155.0, Color(0.04, 0.08, 0.16, 0.75))
	draw_arc(center, 150.0, 0.0, TAU, 64, Color(0.18, 0.45, 0.85, 0.6), 2.5)
	draw_arc(center, 142.0, 0.0, TAU, 64, Color(0.25, 0.65, 1.0, 0.35 * pulse), 1.5)
	
	# Rotating Runes Ring
	var ring_rot := t * 0.4
	for i in range(12):
		var ang := ring_rot + float(i) * (TAU / 12.0)
		var p := center + Vector2(cos(ang), sin(ang)) * 146.0
		draw_circle(p, 2.5, Color(0.4, 0.85, 1.0, 0.75))

	# 2. Inner Magic Circle
	draw_arc(center, 80.0, 0.0, TAU, 48, Color(0.2, 0.6, 0.95, 0.7), 2.0)
	# Rotating Mystic Octagram Star inside
	var star_rot := -t * 0.2
	for i in range(8):
		var a1 := star_rot + float(i) * (TAU / 8.0)
		var a2 := star_rot + float((i + 3) % 8) * (TAU / 8.0)
		var p1 := center + Vector2(cos(a1), sin(a1)) * 76.0
		var p2 := center + Vector2(cos(a2), sin(a2)) * 76.0
		draw_line(p1, p2, Color(0.25, 0.65, 1.0, 0.3), 1.2)

	# 3. Active Synergy Conduits between adjacent sockets
	for s_a in socket_items.keys():
		for s_b in socket_items.keys():
			if s_a < s_b:
				var it_a: ItemInstance = socket_items[s_a]
				var it_b: ItemInstance = socket_items[s_b]
				if GameManager and GameManager.grid_manager and GameManager.grid_manager.are_items_adjacent(it_a, it_b):
					var p0: Vector2 = socket_positions[s_a]
					var p1: Vector2 = socket_positions[s_b]
					draw_line(p0, p1, Color(1.0, 0.5, 0.1, 0.85), 3.5)
					draw_line(p0, p1, Color(1.0, 0.9, 0.5, 0.95), 1.5)

	# 4. Draw Sockets
	for i in range(socket_positions.size()):
		var pos: Vector2 = socket_positions[i]
		var is_selected := (i == selected_socket)
		var is_hover := (i == hover_socket)
		var has_item := socket_items.has(i)
		
		if i < 8:
			# 8 Hex / Octagon Star Sockets (Outer Arcs)
			_draw_hex_socket(pos, is_selected, is_hover, has_item)
		elif i < 10:
			# 2 Inner Spirit Sockets
			_draw_spirit_socket(pos, is_selected, is_hover, has_item)
		else:
			# 3 Bottom Diamond Sockets
			_draw_diamond_socket(pos, is_selected, is_hover, has_item, i == 12)
			
		# Draw socket item if present
		if has_item:
			var it: ItemInstance = socket_items[i]
			var is_dragged := (is_dragging_socket and i == drag_from_socket)
			_draw_socket_item(pos, it, is_dragged)

	# 5. Central Chibi Hero Silhouette / Emblem
	draw_circle(center, 34.0, Color(0.08, 0.12, 0.22, 0.9))
	draw_arc(center, 34.0, 0.0, TAU, 32, Color(0.85, 0.72, 0.25, 0.95), 2.0)
	# Hero glyph
	draw_string(ThemeDB.fallback_font, center + Vector2(-10, 8), "⚔", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color(1, 0.85, 0.35, 1))

func _draw_hex_socket(pos: Vector2, is_sel: bool, is_hov: bool, has_it: bool) -> void:
	var pts := PackedVector2Array()
	var r := 30.0
	for j in range(6):
		var ang := float(j) * (TAU / 6.0)
		pts.append(pos + Vector2(cos(ang), sin(ang)) * r)
		
	var fill_col := Color(0.08, 0.12, 0.2, 0.92)
	if is_hov:
		fill_col = Color(0.15, 0.35, 0.55, 0.92)
	elif is_sel:
		fill_col = Color(0.2, 0.4, 0.25, 0.92)
		
	var border_col := Color(0.3, 0.6, 0.9, 0.7)
	if is_sel:
		border_col = Color(0.25, 0.95, 0.45, 1.0)
	elif is_hov:
		border_col = Color(1.0, 0.85, 0.3, 1.0)
		
	draw_colored_polygon(pts, fill_col)
	draw_polyline(pts, border_col, 2.8 if (is_sel or is_hov) else 2.0)
	
	if not has_it:
		# Large star rune icon inside empty socket
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 7), "✦", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(0.35, 0.65, 0.95, 0.45))

func _draw_spirit_socket(pos: Vector2, is_sel: bool, is_hov: bool, has_it: bool) -> void:
	var fill_col := Color(0.06, 0.1, 0.18, 0.9)
	var border_col := Color(0.3, 0.85, 0.7, 0.7)
	if is_sel: border_col = Color(0.25, 0.95, 0.45, 1.0)
	draw_circle(pos, 26.0, fill_col)
	draw_arc(pos, 26.0, 0.0, TAU, 28, border_col, 2.2)
	if not has_it:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 7), "◈", HORIZONTAL_ALIGNMENT_CENTER, -1, 20, Color(0.3, 0.85, 0.7, 0.45))

func _draw_diamond_socket(pos: Vector2, is_sel: bool, is_hov: bool, has_it: bool, is_padlocked: bool) -> void:
	var pts := PackedVector2Array([
		pos + Vector2(0, -28),
		pos + Vector2(26, 0),
		pos + Vector2(0, 28),
		pos + Vector2(-26, 0)
	])
	var fill_col := Color(0.08, 0.1, 0.16, 0.95)
	var border_col := Color(0.85, 0.68, 0.25, 0.75) if not is_padlocked else Color(0.4, 0.4, 0.45, 0.6)
	draw_colored_polygon(pts, fill_col)
	draw_polyline(pts, border_col, 2.2)
	
	if is_padlocked:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 6), "🔒", HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color(0.7, 0.7, 0.7, 0.7))
	elif not has_it:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-8, 7), "◆", HORIZONTAL_ALIGNMENT_CENTER, -1, 18, Color(0.85, 0.68, 0.25, 0.45))

func _draw_socket_item(pos: Vector2, it: ItemInstance, is_dragged: bool) -> void:
	var a := 0.4 if is_dragged else 1.0
	var tex := it.data.get_icon_texture() if it.data else null
	if tex:
		var rect := Rect2(pos - Vector2(22, 22), Vector2(44, 44))
		draw_texture_rect(tex, rect, false, Color(1, 1, 1, a))
	else:
		draw_circle(pos, 18.0, Color(it.data.color.r, it.data.color.g, it.data.color.b, a))
		
	# Tier number badge
	draw_string(ThemeDB.fallback_font, pos + Vector2(-24, -14), "T%d" % it.data.tier, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1.0, 0.88, 0.35, a))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_press(event.position)
			else:
				_handle_release(event.position)
	elif event is InputEventMouseMotion:
		_handle_motion(event.position)

func _get_socket_at_pos(pos: Vector2) -> int:
	for i in range(socket_positions.size()):
		if pos.distance_to(socket_positions[i]) <= 32.0:
			return i
	return -1

func _handle_press(pos: Vector2) -> void:
	var sock := _get_socket_at_pos(pos)
	if sock != -1:
		if selected_socket != -1 and selected_socket != sock:
			# Move/Swap transaction between selected_socket and sock!
			_swap_sockets(selected_socket, sock)
			selected_socket = -1
		else:
			selected_socket = sock
			drag_from_socket = sock
			is_dragging_socket = true
		socket_clicked.emit(sock)
		queue_redraw()

func _handle_motion(pos: Vector2) -> void:
	var sock := _get_socket_at_pos(pos)
	if sock != hover_socket:
		hover_socket = sock
		queue_redraw()

func _handle_release(pos: Vector2) -> void:
	if is_dragging_socket:
		var dest_sock := _get_socket_at_pos(pos)
		if dest_sock != -1 and dest_sock != drag_from_socket:
			_swap_sockets(drag_from_socket, dest_sock)
	is_dragging_socket = false
	drag_from_socket = -1
	queue_redraw()

func _swap_sockets(s1: int, s2: int) -> void:
	var it1: ItemInstance = socket_items.get(s1, null)
	var it2: ItemInstance = socket_items.get(s2, null)
	
	if it1:
		socket_items[s2] = it1
		it1.grid_pos = SOCKET_TO_CELL.get(s2, it1.grid_pos)
	else:
		socket_items.erase(s2)
		
	if it2:
		socket_items[s1] = it2
		it2.grid_pos = SOCKET_TO_CELL.get(s1, it2.grid_pos)
	else:
		socket_items.erase(s1)
		
	if GameManager:
		GameManager.recalculate_stats_and_synergies()
		
	var ml = Engine.get_main_loop()
	var audio = ml.root.get_node_or_null("AudioManager") if ml and ml.root else null
	if audio:
		audio.play_sfx("item_place")
	rune_moved.emit(s1, s2)
	queue_redraw()
