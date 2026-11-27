class_name HeroPedestalView
extends Control

const DirectionalSprite8Class = preload("res://scripts/combat/directional_sprite_8.gd")

const HERO_8DIR_STRIPS: Dictionary = {
	"kael_varyn": "res://assets/art/characters/8dir/kael_varyn_8dir.png",
	"shadow_hunter": "res://assets/art/characters/8dir/shadow_hunter_8dir.png",
	"storm_reaper": "res://assets/art/characters/8dir/storm_reaper_8dir.png",
	"soul_binder": "res://assets/art/characters/8dir/soul_binder_8dir.png",
	"1": "res://assets/art/characters/8dir/soul_binder_8dir.png",
	"summaner": "res://assets/art/characters/8dir/soul_binder_8dir.png"
}

# Renders the Hero on a glowing 2.5D elemental pedestal using the 8-directional
# pre-rendered 3D sprite strip with subtle idle breathing and arcane rings.

@export var character_id: String = "kael_varyn"
@export var enable_diorama_stage: bool = true
@export var diorama_include_pillars: bool = true

var _t: float = 0.0
var _loaded_character_id: String = ""
var _portrait_texture: Texture2D
var _sprite_8dir: DirectionalSprite8Class
var _model_preview_loaded: bool = false
var _preview_character_id: String = ""
var _dir_cycle_index: int = 2 # Start facing South (front)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var s8 := DirectionalSprite8Class.new()
	s8.name = "HeroPedestal8Dir"
	s8.visible = false
	_sprite_8dir = s8
	add_child(s8)
	if is_visible_in_tree():
		_sync_character_visual()
	_update_preview_rect()

func set_character(next_character_id: String) -> bool:
	character_id = next_character_id
	_preview_character_id = ""
	if is_inside_tree():
		_sync_character_visual()
	return _model_preview_loaded

func rotate_preview_step(step: int = 1) -> void:
	_dir_cycle_index = posmod(_dir_cycle_index + step, 8)
	if is_instance_valid(_sprite_8dir) and _model_preview_loaded:
		_sprite_8dir.set_direction_name(DirectionalSprite8Class.DIRECTION_NAMES[_dir_cycle_index])

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_preview_rect()
	elif what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		_sync_character_visual()

func _update_preview_rect() -> void:
	if not is_instance_valid(_sprite_8dir):
		return
	var target_h := clampf(minf(size.x, size.y) * 0.72, 180.0, 320.0)
	_sprite_8dir.position = size * 0.5 + Vector2(0.0, 22.0)
	if _model_preview_loaded:
		var strip_path := str(HERO_8DIR_STRIPS.get(character_id, HERO_8DIR_STRIPS["shadow_hunter"]))
		_sprite_8dir.setup(strip_path, target_h, target_h * 0.36)
		_sprite_8dir.set_direction_name(DirectionalSprite8Class.DIRECTION_NAMES[_dir_cycle_index])

func _sync_character_visual() -> void:
	if not is_visible_in_tree() or not is_instance_valid(_sprite_8dir):
		return
	if _preview_character_id == character_id and _model_preview_loaded:
		return
	_preview_character_id = character_id
	_ensure_character_portrait()
	var strip_path := str(HERO_8DIR_STRIPS.get(character_id, HERO_8DIR_STRIPS["shadow_hunter"]))
	var target_h := clampf(minf(size.x, size.y) * 0.72, 180.0, 320.0)
	_sprite_8dir.position = size * 0.5 + Vector2(0.0, 22.0)
	_model_preview_loaded = _sprite_8dir.setup(strip_path, target_h, target_h * 0.36)
	_sprite_8dir.visible = _model_preview_loaded
	if _model_preview_loaded:
		_sprite_8dir.set_direction_name(DirectionalSprite8Class.DIRECTION_NAMES[_dir_cycle_index])
	queue_redraw()

func _ensure_character_portrait() -> void:
	if _loaded_character_id == character_id:
		return
	_loaded_character_id = character_id
	_portrait_texture = TextureLoader.get_texture("res://assets/art/characters/%s_portrait.png" % character_id)

func _process(delta: float) -> void:
	_t += delta
	if _preview_character_id != character_id:
		_sync_character_visual()
	if _model_preview_loaded and is_instance_valid(_sprite_8dir):
		_sprite_8dir.update_pose("idle", _t, delta)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5 + Vector2(0, 30)
	var t := _t
	var pulse := (1.0 + sin(t * 3.0)) * 0.5
	var bob := sin(t * 2.5) * 4.0
	
	# 1. Glowing Elemental Pedestal (Tiered Octagonal Runic Stone Platform)
	var ped_center := center + Vector2(0, 58)
	draw_arc(ped_center, 96.0, 0.0, TAU, 36, Color(0.95, 0.65, 0.2, 0.16 * pulse), 4.0)
	draw_arc(ped_center, 74.0, 0.0, TAU, 36, Color(0.95, 0.76, 0.3, 0.38), 2.0)

	# Outer beveled octagonal skirt
	var skirt_pts := PackedVector2Array([
		ped_center + Vector2(-92, 4),
		ped_center + Vector2(-62, 30),
		ped_center + Vector2(62, 30),
		ped_center + Vector2(92, 4),
		ped_center + Vector2(92, -6),
		ped_center + Vector2(62, -22),
		ped_center + Vector2(-62, -22),
		ped_center + Vector2(-92, -6)
	])
	draw_colored_polygon(skirt_pts, Color(0.06, 0.07, 0.11, 0.96))

	# Top octagonal stone face
	var ped_pts := PackedVector2Array([
		ped_center + Vector2(-88, -2),
		ped_center + Vector2(-58, 22),
		ped_center + Vector2(58, 22),
		ped_center + Vector2(88, -2),
		ped_center + Vector2(58, -22),
		ped_center + Vector2(-58, -22)
	])
	draw_colored_polygon(ped_pts, Color(0.11, 0.13, 0.19, 0.96))
	draw_polyline(ped_pts, Color(0.86, 0.7, 0.32, 0.92), 2.5)
	draw_line(ped_pts[0], ped_pts[1], Color(0.96, 0.82, 0.42, 0.95), 2.5)
	draw_line(ped_pts[1], ped_pts[2], Color(0.96, 0.82, 0.42, 0.95), 2.5)
	draw_line(ped_pts[2], ped_pts[3], Color(0.96, 0.82, 0.42, 0.95), 2.5)

	# Inner glowing golden rune ellipse + star sigil
	var ring_col := Color(0.98, 0.76, 0.28, 0.52 + 0.24 * pulse)
	for seg in range(24):
		var a0 := float(seg) / 24.0 * TAU
		var a1 := float(seg + 1) / 24.0 * TAU
		var p0 := ped_center + Vector2(cos(a0) * 54.0, sin(a0) * 14.0)
		var p1 := ped_center + Vector2(cos(a1) * 54.0, sin(a1) * 14.0)
		draw_line(p0, p1, ring_col, 1.8)
	for star_i in range(5):
		var sa0 := -PI * 0.5 + float(star_i) * TAU / 5.0
		var sa1 := -PI * 0.5 + float(star_i + 2) * TAU / 5.0
		draw_line(
			ped_center + Vector2(cos(sa0) * 44.0, sin(sa0) * 11.0),
			ped_center + Vector2(cos(sa1) * 44.0, sin(sa1) * 11.0),
			Color(0.98, 0.72, 0.22, 0.36 + 0.18 * pulse),
			1.4
		)

	# Core aura + subtle rising ember flecks
	var aura_col := Color(0.22, 0.88, 1.0, 0.22 * pulse) if character_id == "kael_varyn" else Color(0.92, 0.58, 0.2, 0.22 * pulse)
	draw_circle(ped_center, 36.0, aura_col)
	for ember_i in range(8):
		var phase := fmod(t * 0.55 + float(ember_i) * 0.17, 1.0)
		var ex := sin(float(ember_i) * 2.3 + t * 1.4) * 58.0
		var ey := -phase * 95.0
		var ea := sin(phase * PI) * 0.65
		draw_circle(ped_center + Vector2(ex, ey), 1.8, Color(1.0, 0.65, 0.25, ea))

	# 2. Hero Body — Chibi Proportions (2.2 heads tall)
	var hero_pos := center + Vector2(0, bob)
	
	var iris_col := Color(0.65, 0.3, 0.95, 1.0)
	if character_id == "kael_varyn":
		iris_col = Color(0.22, 0.88, 1.0, 1.0)
	elif character_id == "storm_reaper":
		iris_col = Color(0.2, 0.85, 1.0, 1.0)
	elif character_id == "soul_binder":
		iris_col = Color(0.3, 0.95, 0.65, 1.0)
		
	_ensure_character_portrait()
	if _model_preview_loaded:
		pass # The 8-directional hero sprite renders above the pedestal.
	elif _portrait_texture:
		var source_size := _portrait_texture.get_size()
		var target_size := Vector2(150, 174)
		var fit_scale := minf(target_size.x / maxf(source_size.x, 1.0), target_size.y / maxf(source_size.y, 1.0))
		var render_size := source_size * fit_scale
		var portrait_rect := Rect2(hero_pos - render_size * 0.5 + Vector2(0, -8), render_size)
		draw_texture_rect(_portrait_texture, portrait_rect, false)
	else:
		# Cape / Shadows behind
		var cape_pts := PackedVector2Array([
			hero_pos + Vector2(-15, -10),
			hero_pos + Vector2(15, -10),
			hero_pos + Vector2(25, 35),
			hero_pos + Vector2(-25, 35)
		])
		draw_colored_polygon(cape_pts, Color(0.08, 0.06, 0.14, 0.95))
		
		# Torso & Tunic
		var tunic_pts := PackedVector2Array([
			hero_pos + Vector2(-14, -8),
			hero_pos + Vector2(14, -8),
			hero_pos + Vector2(18, 22),
			hero_pos + Vector2(-18, 22)
		])
		draw_colored_polygon(tunic_pts, Color(0.18, 0.22, 0.34, 1.0))
		draw_polyline(tunic_pts, Color(0.85, 0.7, 0.25, 0.9), 1.5)
		
		# Gold belt with gem
		draw_rect(Rect2(hero_pos + Vector2(-12, 10), Vector2(24, 6)), Color(0.9, 0.75, 0.25, 1.0), true)
		draw_circle(hero_pos + Vector2(0, 13), 3.0, Color(0.95, 0.25, 0.25, 1.0))

		# Chibi Head (Large expressive head)
		var head_center := hero_pos + Vector2(0, -32)
		draw_circle(head_center, 26.0, Color(0.12, 0.1, 0.18, 1.0))
		draw_circle(head_center + Vector2(0, 2), 20.0, Color(0.96, 0.85, 0.78, 1.0))
		
		# Expressive Large Eyes
		var eye_l := head_center + Vector2(-8, 2)
		var eye_r := head_center + Vector2(8, 2)
		draw_circle(eye_l, 5.0, Color(0.15, 0.15, 0.22, 1.0))
		draw_circle(eye_r, 5.0, Color(0.15, 0.15, 0.22, 1.0))
		draw_circle(eye_l, 3.2, iris_col)
		draw_circle(eye_r, 3.2, iris_col)
		draw_circle(eye_l + Vector2(-1.2, -1.2), 1.5, Color.WHITE)
		draw_circle(eye_r + Vector2(-1.2, -1.2), 1.5, Color.WHITE)
		
		# Cute smile
		draw_arc(head_center + Vector2(0, 11), 4.0, 0.2, PI - 0.2, 8, Color(0.4, 0.2, 0.2, 0.8), 1.5)

		# 3. Oversized Signature Weapon (Right hand)
		var weap_pos := hero_pos + Vector2(28, 4)
		draw_line(weap_pos + Vector2(0, 25), weap_pos + Vector2(0, -30), Color(0.45, 0.35, 0.25, 1.0), 3.0)
		var blade_pts := PackedVector2Array([
			weap_pos + Vector2(0, -30),
			weap_pos + Vector2(-22, -45),
			weap_pos + Vector2(-10, -20)
		])
		draw_colored_polygon(blade_pts, Color(0.85, 0.9, 1.0, 1.0))
		draw_polyline(blade_pts, Color(0.85, 0.7, 0.25, 1.0), 2.0)

	# 4. Floating Elemental Spirit Companion (Flits to the upper left)
	var comp_bob := sin(t * 3.5) * 6.0
	var comp_pos := hero_pos + Vector2(-48, -45 + comp_bob)
	# Outer aura
	draw_circle(comp_pos, 14.0 + pulse * 3.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.3))
	# Inner wisp
	draw_circle(comp_pos, 8.0, Color(iris_col.r, iris_col.g, iris_col.b, 0.9))
	draw_circle(comp_pos + Vector2(-2, -2), 3.0, Color.WHITE)
	# Tiny wisp trail
	for tr in range(3):
		var tra := comp_pos + Vector2(float(tr) * 4.0, 10.0 + float(tr) * 5.0)
		draw_circle(tra, (3.0 - float(tr)) * 0.8, Color(iris_col.r, iris_col.g, iris_col.b, 0.5 - float(tr) * 0.15))
