class_name ArenaBackground
extends Node2D

# Layered authored floor art is optional; procedural drawing remains the safe fallback.
const FLOOR_ART_MANIFEST := "res://assets/art/environments/floors/manifest.json"
const FLOOR_ART_ROLES: Array[String] = ["background", "floor", "props", "foreground"]
const FLOOR_ART_Z: Dictionary = {
	"background": -4,
	"floor": -3,
	"props": -2,
	"foreground": -1
}

var flicker_timer: float = 0.0
var reduced_motion_enabled: bool = false
var floor_theme_name: String = "Abyssal Ruins"
var floor_background_color: Color = Color(0.05, 0.03, 0.07, 1.0)
var tile_base_color: Color = Color(0.09, 0.06, 0.13, 0.95)
var tile_highlight_color: Color = Color(0.18, 0.13, 0.25, 0.6)
var border_color: Color = Color(0.25, 0.14, 0.38, 0.9)
var rune_color: Color = Color(0.7, 0.25, 0.95, 0.85)
var brazier_glow_color: Color = Color(0.9, 0.3, 0.1, 0.15)
var brazier_flame_color: Color = Color(0.95, 0.25, 0.15, 0.9)
var using_authored_floor_art: bool = false

func _ready() -> void:
	add_to_group("arena_backgrounds")
	set_floor_theme(GameManager.floor_number)
	set_reduced_motion(bool(SaveManager.settings_data.get("reduced_motion", false)) if SaveManager else false)

func set_reduced_motion(enabled: bool) -> void:
	reduced_motion_enabled = enabled
	set_process(not enabled and not using_authored_floor_art)
	if enabled:
		flicker_timer = 0.0
	queue_redraw()

func set_floor_theme(floor_num: int) -> String:
	var theme_index := posmod(maxi(floor_num, 1) - 1, 5)
	match theme_index:
		0:
			floor_theme_name = "Abyssal Ruins"
			floor_background_color = Color(0.05, 0.03, 0.07, 1.0)
			tile_base_color = Color(0.09, 0.06, 0.13, 0.95)
			tile_highlight_color = Color(0.18, 0.13, 0.25, 0.6)
			border_color = Color(0.25, 0.14, 0.38, 0.9)
			rune_color = Color(0.7, 0.25, 0.95, 0.85)
			brazier_glow_color = Color(0.9, 0.3, 0.1, 0.15)
			brazier_flame_color = Color(0.95, 0.25, 0.15, 0.9)
		1:
			floor_theme_name = "Ember Catacombs"
			floor_background_color = Color(0.09, 0.035, 0.025, 1.0)
			tile_base_color = Color(0.16, 0.075, 0.045, 0.95)
			tile_highlight_color = Color(0.3, 0.16, 0.09, 0.65)
			border_color = Color(0.48, 0.19, 0.07, 0.9)
			rune_color = Color(1.0, 0.42, 0.12, 0.9)
			brazier_glow_color = Color(1.0, 0.28, 0.04, 0.2)
			brazier_flame_color = Color(1.0, 0.48, 0.12, 0.95)
		2:
			floor_theme_name = "Frostbound Crypt"
			floor_background_color = Color(0.025, 0.055, 0.09, 1.0)
			tile_base_color = Color(0.055, 0.11, 0.17, 0.95)
			tile_highlight_color = Color(0.13, 0.24, 0.34, 0.65)
			border_color = Color(0.12, 0.32, 0.48, 0.9)
			rune_color = Color(0.25, 0.78, 1.0, 0.9)
			brazier_glow_color = Color(0.12, 0.55, 1.0, 0.18)
			brazier_flame_color = Color(0.3, 0.8, 1.0, 0.95)
		3:
			floor_theme_name = "Blighted Sanctum"
			floor_background_color = Color(0.025, 0.065, 0.045, 1.0)
			tile_base_color = Color(0.055, 0.12, 0.075, 0.95)
			tile_highlight_color = Color(0.14, 0.25, 0.16, 0.65)
			border_color = Color(0.18, 0.38, 0.2, 0.9)
			rune_color = Color(0.42, 0.95, 0.38, 0.9)
			brazier_glow_color = Color(0.25, 0.9, 0.2, 0.18)
			brazier_flame_color = Color(0.55, 1.0, 0.3, 0.95)
		4:
			floor_theme_name = "Crimson Throne"
			floor_background_color = Color(0.075, 0.025, 0.045, 1.0)
			tile_base_color = Color(0.14, 0.055, 0.075, 0.95)
			tile_highlight_color = Color(0.28, 0.12, 0.16, 0.65)
			border_color = Color(0.42, 0.12, 0.18, 0.9)
			rune_color = Color(1.0, 0.3, 0.38, 0.9)
			brazier_glow_color = Color(1.0, 0.12, 0.2, 0.2)
			brazier_flame_color = Color(1.0, 0.42, 0.25, 0.95)

	using_authored_floor_art = _install_authored_floor_art(maxi(floor_num, 1))
	set_process(not reduced_motion_enabled and not using_authored_floor_art)
	queue_redraw()
	return floor_theme_name

func _install_authored_floor_art(floor_num: int) -> bool:
	var old_art := get_node_or_null("AuthoredFloorArt")
	if old_art != null:
		old_art.queue_free()
	if not FileAccess.file_exists(FLOOR_ART_MANIFEST):
		return false

	var file := FileAccess.open(FLOOR_ART_MANIFEST, FileAccess.READ)
	if file == null:
		push_warning("Could not open floor art manifest; using procedural arena.")
		return false

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		push_warning("Floor art manifest is invalid; using procedural arena.")
		return false

	var floors: Variant = parser.data.get("floors", null)
	if not floors is Array:
		return false

	var selected_floor: Dictionary = {}
	for entry in floors:
		if entry is Dictionary and int(entry.get("floor_number", -1)) == floor_num:
			selected_floor = entry
			break
	if selected_floor.is_empty():
		return false

	var layers: Variant = selected_floor.get("layers", null)
	if not layers is Array:
		return false

	var textures: Dictionary = {}
	for layer in layers:
		if not layer is Dictionary:
			return false
		var role := str(layer.get("role", ""))
		var source := str(layer.get("source", ""))
		if role not in FLOOR_ART_ROLES or textures.has(role) or source.is_empty():
			return false
		var texture := load(source) as Texture2D
		if texture == null or texture.get_width() != 720 or texture.get_height() != 1280:
			push_warning("Floor %d art layer '%s' is missing or not 720x1280; using procedural arena." % [floor_num, role])
			return false
		textures[role] = texture

	for role in FLOOR_ART_ROLES:
		if not textures.has(role):
			push_warning("Floor %d art is missing '%s'; using procedural arena." % [floor_num, role])
			return false

	var art_root := Node2D.new()
	art_root.name = "AuthoredFloorArt"
	add_child(art_root)
	for role in FLOOR_ART_ROLES:
		var layer_sprite := Sprite2D.new()
		layer_sprite.name = role.capitalize()
		layer_sprite.texture = textures[role]
		layer_sprite.position = Vector2(360.0, 640.0)
		layer_sprite.z_index = int(FLOOR_ART_Z[role])
		art_root.add_child(layer_sprite)

	return true

func _shade_color(base: Color, amount: float) -> Color:
	return Color(
		clampf(base.r + amount, 0.0, 1.0),
		clampf(base.g + amount, 0.0, 1.0),
		clampf(base.b + amount, 0.0, 1.0),
		base.a
	)

func _process(delta: float) -> void:
	flicker_timer += delta
	if flicker_timer >= 0.08:
		flicker_timer = 0.0
		queue_redraw()

func _draw() -> void:
	if using_authored_floor_art:
		return

	# Deep dark void floor
	draw_rect(Rect2(0, 0, 720, 1280), floor_background_color, true)

	# Beveled 2.5D stone tile grid
	var tile_size := 75.0
	for x in range(25, 695, int(tile_size)):
		for y in range(65, 1155, int(tile_size)):
			var tile_rect := Rect2(x + 2, y + 2, tile_size - 4, tile_size - 4)
			var shade_offset := sin(float(x * 13 + y * 7)) * 0.015
			var stone_col := _shade_color(tile_base_color, shade_offset)
			draw_rect(tile_rect, stone_col, true)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.position.y), tile_highlight_color, 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.position.y), Vector2(tile_rect.position.x, tile_rect.end.y), tile_highlight_color, 1.0)
			draw_line(Vector2(tile_rect.position.x, tile_rect.end.y), Vector2(tile_rect.end.x, tile_rect.end.y), tile_base_color.darkened(0.7), 1.5)
			draw_line(Vector2(tile_rect.end.x, tile_rect.position.y), Vector2(tile_rect.end.x, tile_rect.end.y), tile_base_color.darkened(0.7), 1.5)

	# Outer border boundary stone walls with depth shadow
	draw_rect(Rect2(20, 60, 680, 1100), border_color, false, 5.0)
	draw_rect(Rect2(25, 65, 670, 1090), border_color.darkened(0.35), false, 2.0)

	# Central summoning ring
	var center := Vector2(360, 640)
	var t: float = Time.get_ticks_msec() / 1000.0
	var pulse: float = 0.5 if reduced_motion_enabled else (1.0 + sin(t * 2.0)) * 0.5
	draw_circle(center, 220.0, Color(floor_background_color.r, floor_background_color.g, floor_background_color.b, 0.45))
	draw_arc(center, 220.0, 0, TAU, 64, _shade_color(rune_color, pulse * 0.12), 3.0)
	draw_arc(center, 180.0, 0, TAU, 48, Color(rune_color.r, rune_color.g, rune_color.b, 0.45), 2.0)
	draw_arc(center, 120.0, 0, TAU, 32, Color(rune_color.r, rune_color.g, rune_color.b, 0.62), 2.0)

	for i in range(8):
		var angle := (TAU / 8.0) * float(i)
		var p1 := center + Vector2.RIGHT.rotated(angle) * 180.0
		var p2 := center + Vector2.RIGHT.rotated(angle + PI * 0.75) * 180.0
		draw_line(p1, p2, Color(rune_color.r, rune_color.g, rune_color.b, 0.45), 1.8)
		draw_circle(p1, 6.0, rune_color.lightened(0.15))
		draw_circle(p1, 2.5, Color(1.0, 1.0, 1.0, 0.95))

	var corners := [Vector2(75, 115), Vector2(645, 115), Vector2(75, 1105), Vector2(645, 1105)]
	var flk: float = 0.0 if reduced_motion_enabled else sin(t * 8.0) * 3.0 + cos(t * 13.0) * 2.0
	for corner in corners:
		draw_circle(corner, 48.0 + flk, brazier_glow_color)
		draw_circle(corner, 28.0 + flk * 0.5, Color(brazier_flame_color.r, brazier_flame_color.g, brazier_flame_color.b, 0.25))
		draw_circle(corner, 16.0, tile_highlight_color.darkened(0.45))
		draw_circle(corner, 11.0, brazier_flame_color)
		draw_circle(corner, 5.0, Color(1.0, 0.9, 0.4, 1.0))
