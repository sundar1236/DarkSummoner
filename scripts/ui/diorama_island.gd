class_name DioramaIsland
extends Control

# Composes the Campaign floating abyssal island dynamically from modular
# dark-rock base island + rune ring, pine grove, tents, and flickering campfire.

var _anim_time: float = 0.0
var _base_tex: Texture2D = null
var _trees_tex: Texture2D = null
var _tent_grey_tex: Texture2D = null
var _tent_lit_tex: Texture2D = null
var _fire_tex: Texture2D = null

func _ready() -> void:
	_load_textures()

func _load_textures() -> void:
	if not _base_tex:
		_base_tex = TextureLoader.get_texture("res://assets/art/ui_campaign/diorama_base_island.png")
	if not _trees_tex:
		_trees_tex = TextureLoader.get_texture("res://assets/art/ui_campaign/prop_trees_cluster.png")
	if not _tent_grey_tex:
		_tent_grey_tex = TextureLoader.get_texture("res://assets/art/ui_campaign/prop_tent_grey.png")
	if not _tent_lit_tex:
		_tent_lit_tex = TextureLoader.get_texture("res://assets/art/ui_campaign/prop_tent_lit.png")
	if not _fire_tex:
		_fire_tex = TextureLoader.get_texture("res://assets/art/ui_campaign/prop_campfire_tall.png")

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_anim_time += delta
	queue_redraw()

func _draw_prop(tex: Texture2D, center_pos: Vector2, width_px: float) -> void:
	if not tex:
		return
	var sz := tex.get_size()
	var h_px := width_px * (sz.y / maxf(sz.x, 1.0))
	draw_texture_rect(tex, Rect2(center_pos - Vector2(width_px * 0.5, h_px * 0.5), Vector2(width_px, h_px)), false)

func _draw() -> void:
	_load_textures()
	var center := size * 0.5 + Vector2(0, 4)
	var t := _anim_time
	var pulse := (1.0 + sin(t * 2.4)) * 0.5

	# Outer glowing rune halo
	var ring_r := minf(size.x * 0.43, size.y * 0.45)
	draw_arc(center, ring_r + 10.0, 0.0, TAU, 48, Color(0.55, 0.38, 0.85, 0.14 + 0.08 * pulse), 2.5)
	draw_arc(center, ring_r, 0.0, TAU, 48, Color(0.95, 0.78, 0.34, 0.3 + 0.16 * pulse), 2.0)

	# 1. Clean Unbroken Rune Circle & Bare Floating Rock Island
	var draw_sz := Vector2(ring_r * 2.1, ring_r * 2.1)
	if _base_tex:
		var tex_sz := _base_tex.get_size()
		var target_box := minf(size.x * 0.94, size.y * 0.98)
		var scale_f := target_box / maxf(tex_sz.x, tex_sz.y)
		draw_sz = tex_sz * scale_f
		draw_texture_rect(_base_tex, Rect2(center - draw_sz * 0.5, draw_sz), false)

	# 2. Modular Pine Forest Grove (upper-left ridge of plateau)
	_draw_prop(_trees_tex, center + Vector2(-draw_sz.x * 0.14, -draw_sz.y * 0.19), draw_sz.x * 0.32)

	# 3. Modular Expedition Tents & Campfire (center & right clearing)
	_draw_prop(_tent_grey_tex, center + Vector2(draw_sz.x * 0.015, -draw_sz.y * 0.08), draw_sz.x * 0.17)
	_draw_prop(_tent_lit_tex, center + Vector2(draw_sz.x * 0.165, -draw_sz.y * 0.115), draw_sz.x * 0.17)
	var fire_pos := center + Vector2(draw_sz.x * 0.12, -draw_sz.y * 0.025)
	draw_circle(fire_pos, draw_sz.x * 0.05, Color(1.0, 0.58, 0.15, 0.22 + 0.14 * pulse))
	_draw_prop(_fire_tex, fire_pos, draw_sz.x * 0.10)

	# 4. Animated Rising Fire Embers
	for e in range(5):
		var ep := fmod(t * 0.85 + float(e) * 0.21, 1.0)
		var ex := fire_pos.x + sin(t * 2.4 + float(e) * 1.9) * 10.0
		var ey := fire_pos.y - ep * 32.0
		draw_circle(Vector2(ex, ey), 1.8, Color(1.0, 0.78, 0.32, (1.0 - ep) * 0.82))
