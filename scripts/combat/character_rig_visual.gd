class_name CharacterRigVisual
extends Node2D

# Lightweight authored 2.5D-style character rig. Each hero has a distinct
# silhouette, palette, weapon language and animated pose; gameplay stays outside.
@export_enum("shadow_hunter", "storm_reaper", "soul_binder") var character_id: String = "shadow_hunter"

var animation_player: AnimationPlayer
var weapon_socket: Marker2D
var left_weapon_socket: Marker2D
var right_weapon_socket: Marker2D
var _pulse: float = 0.0
@export_range(-1.0, 1.0, 0.01) var action_pose: float = 0.0

const PALETTES: Dictionary = {
	"shadow_hunter": {
		"main": Color("#29223f"), "light": Color("#8060bb"), "dark": Color("#151321"),
		"glow": Color("#c69aff"), "metal": Color("#b9a7d8"), "skin": Color("#d9c7e9")
	},
	"storm_reaper": {
		"main": Color("#263b50"), "light": Color("#6598bd"), "dark": Color("#111d2b"),
		"glow": Color("#75eaff"), "metal": Color("#b7d8e8"), "skin": Color("#c4dce8")
	},
	"soul_binder": {
		"main": Color("#25483f"), "light": Color("#63a88b"), "dark": Color("#142923"),
		"glow": Color("#8dffd0"), "metal": Color("#c3ead7"), "skin": Color("#e1d9c6")
	}
}

func _ready() -> void:
	_build_attachment_points()
	_build_animation_player()
	queue_redraw()

func _process(delta: float) -> void:
	_pulse += delta
	queue_redraw()

func _build_attachment_points() -> void:
	weapon_socket = Marker2D.new()
	weapon_socket.name = "WeaponSocket"
	weapon_socket.position = Vector2(22, -10)
	add_child(weapon_socket)
	left_weapon_socket = Marker2D.new()
	left_weapon_socket.name = "LeftWeaponSocket"
	left_weapon_socket.position = Vector2(-13, -7)
	add_child(left_weapon_socket)
	right_weapon_socket = Marker2D.new()
	right_weapon_socket.name = "RightWeaponSocket"
	right_weapon_socket.position = Vector2(14, -7)
	add_child(right_weapon_socket)

func _build_animation_player() -> void:
	animation_player = AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	animation_player.root_node = NodePath("..")
	add_child(animation_player)
	var library := AnimationLibrary.new()
	for clip_name in ["idle", "run", "attack_1", "attack_2", "attack_3", "skill", "hurt", "dodge", "defeat", "victory"]:
		library.add_animation(clip_name, _make_clip(clip_name))
	animation_player.add_animation_library("", library)
	animation_player.play("idle")

func _make_clip(clip_name: String) -> Animation:
	var animation := Animation.new()
	animation.length = 0.7
	var looping := clip_name in ["idle", "run"]
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	var position_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(position_track, NodePath(".:position"))
	var scale_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(scale_track, NodePath(".:scale"))
	var pose_track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(pose_track, NodePath(".:action_pose"))
	var base := Vector2(0, -5)
	match clip_name:
		"idle":
			animation.length = 1.0
			animation.track_insert_key(position_track, 0.0, base + Vector2(0, 1))
			animation.track_insert_key(position_track, 0.5, base + Vector2(0, -2))
			animation.track_insert_key(position_track, 1.0, base + Vector2(0, 1))
			animation.track_insert_key(scale_track, 0.0, Vector2(1.0, 1.0))
			animation.track_insert_key(scale_track, 0.5, Vector2(1.02, 0.98))
			animation.track_insert_key(scale_track, 1.0, Vector2(1.0, 1.0))
		"run":
			animation.length = 0.32
			animation.track_insert_key(position_track, 0.0, base + Vector2(0, -3))
			animation.track_insert_key(position_track, 0.16, base + Vector2(0, 2))
			animation.track_insert_key(position_track, 0.32, base + Vector2(0, -3))
			animation.track_insert_key(scale_track, 0.0, Vector2(0.96, 1.05))
			animation.track_insert_key(scale_track, 0.16, Vector2(1.04, 0.95))
			animation.track_insert_key(scale_track, 0.32, Vector2(0.96, 1.05))
		"attack_1", "attack_2", "attack_3":
			animation.length = 0.24
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.10, base + Vector2(5, -3))
			animation.track_insert_key(position_track, 0.24, base)
			animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
			animation.track_insert_key(scale_track, 0.10, Vector2(1.16, 0.88))
			animation.track_insert_key(scale_track, 0.24, Vector2.ONE)
		"skill":
			animation.length = 0.65
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.32, base + Vector2(0, -12))
			animation.track_insert_key(position_track, 0.65, base)
			animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
			animation.track_insert_key(scale_track, 0.32, Vector2(1.18, 1.18))
			animation.track_insert_key(scale_track, 0.65, Vector2.ONE)
		"dodge":
			animation.length = 0.25
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.12, base + Vector2(13, 0))
			animation.track_insert_key(position_track, 0.25, base)
			animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
			animation.track_insert_key(scale_track, 0.12, Vector2(1.24, 0.78))
			animation.track_insert_key(scale_track, 0.25, Vector2.ONE)
		"hurt":
			animation.length = 0.2
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.1, base + Vector2(-4, 1))
			animation.track_insert_key(position_track, 0.2, base)
		"defeat":
			animation.length = 0.8
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.8, base + Vector2(0, 12))
			animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
			animation.track_insert_key(scale_track, 0.8, Vector2(1.15, 0.5))
		"victory":
			animation.length = 0.6
			animation.track_insert_key(position_track, 0.0, base)
			animation.track_insert_key(position_track, 0.3, base + Vector2(0, -14))
			animation.track_insert_key(position_track, 0.6, base)
			animation.track_insert_key(scale_track, 0.0, Vector2.ONE)
			animation.track_insert_key(scale_track, 0.3, Vector2(1.1, 1.12))
			animation.track_insert_key(scale_track, 0.6, Vector2.ONE)
	# Drive visible arm/weapon posing with the same authored clips used by the rig root.
	var pose_peak := 0.0
	match clip_name:
		"run": pose_peak = 0.22
		"attack_1": pose_peak = 1.0
		"attack_2": pose_peak = -1.0
		"attack_3": pose_peak = 0.82
		"skill", "victory": pose_peak = 0.72
		"hurt": pose_peak = -0.58
		"dodge": pose_peak = -0.78
		"defeat": pose_peak = -0.32
		_: pose_peak = 0.0
	animation.track_insert_key(pose_track, 0.0, 0.0)
	if clip_name in ["idle", "run"]:
		animation.track_insert_key(pose_track, animation.length * 0.5, pose_peak)
		animation.track_insert_key(pose_track, animation.length, 0.0)
	else:
		animation.track_insert_key(pose_track, animation.length * 0.42, pose_peak)
		animation.track_insert_key(pose_track, animation.length, 0.0)
	return animation

func _draw() -> void:
	var palette: Dictionary = PALETTES.get(character_id, PALETTES["shadow_hunter"])
	var main: Color = palette.main
	var light: Color = palette.light
	var dark: Color = palette.dark
	var glow: Color = palette.glow
	var metal: Color = palette.metal
	var skin: Color = palette.skin
	var bob := sin(_pulse * 3.0) * 1.2
	var pose := action_pose
	# Cape / mantle creates the readable silhouette behind the body.
	var cape := PackedVector2Array([
		Vector2(-13, -23 + bob), Vector2(13, -23 + bob),
		Vector2(19, 4), Vector2(9, 18), Vector2(-11, 18), Vector2(-19, 3)
	])
	draw_colored_polygon(cape, dark)
	draw_polyline(PackedVector2Array([cape[0], cape[5], cape[4], cape[3], cape[2], cape[1]]), light, 2.0, true)
	# Chibi torso and shoulder plates.
	draw_colored_polygon(PackedVector2Array([
		Vector2(-13, -25 + bob), Vector2(13, -25 + bob), Vector2(16, -8 + bob),
		Vector2(10, 8 + bob), Vector2(-10, 8 + bob), Vector2(-16, -8 + bob)
	]), main)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-14, -20 + bob), Vector2(-5, -24 + bob), Vector2(-7, -12 + bob), Vector2(-15, -10 + bob)
	]), light)
	draw_colored_polygon(PackedVector2Array([
		Vector2(14, -20 + bob), Vector2(5, -24 + bob), Vector2(7, -12 + bob), Vector2(15, -10 + bob)
	]), light)
	draw_line(Vector2(-9, 4 + bob), Vector2(-7, 15), dark, 5.0, true)
	draw_line(Vector2(9, 4 + bob), Vector2(7, 15), dark, 5.0, true)
	draw_line(Vector2(-9, 15), Vector2(-3, 15), metal, 3.0, true)
	draw_line(Vector2(9, 15), Vector2(3, 15), metal, 3.0, true)
	# Oversized hooded head and mask.
	draw_circle(Vector2(0, -31 + bob), 15.0, dark)
	draw_circle(Vector2(0, -32 + bob), 12.5, main)
	draw_arc(Vector2(0, -32 + bob), 12.5, PI, TAU, 24, light, 2.0, true)
	match character_id:
		"shadow_hunter":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -35 + bob), Vector2(0, -47 + bob), Vector2(12, -35 + bob),
				Vector2(8, -29 + bob), Vector2(-8, -29 + bob)
			]), dark)
			draw_line(Vector2(-7, -31 + bob), Vector2(-2, -32 + bob), glow, 2.4, true)
			draw_line(Vector2(2, -32 + bob), Vector2(7, -31 + bob), glow, 2.4, true)
			draw_line(Vector2(-12, -13 + bob), Vector2(-21 - pose * 5.0, -3 - pose * 2.0), light, 4.0, true)
			draw_line(Vector2(12, -13 + bob), Vector2(21 + pose * 8.0, -3 - pose * 5.0), light, 4.0, true)
			draw_line(Vector2(18, -5), Vector2(28, -21), metal, 3.0, true)
			draw_line(Vector2(28, -21), Vector2(31, -26), glow, 1.8, true)
		"storm_reaper":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-13, -37 + bob), Vector2(-18, -48 + bob), Vector2(-5, -43 + bob),
				Vector2(0, -49 + bob), Vector2(5, -43 + bob), Vector2(18, -48 + bob), Vector2(13, -35 + bob)
			]), metal)
			draw_line(Vector2(-7, -32 + bob), Vector2(-2, -30 + bob), glow, 2.8, true)
			draw_line(Vector2(2, -30 + bob), Vector2(7, -32 + bob), glow, 2.8, true)
			draw_line(Vector2(11, -12 + bob), Vector2(22 + pose * 7.0, -1 - pose * 4.0), metal, 4.0, true)
			draw_line(Vector2(22 + pose * 7.0, -1 - pose * 4.0), Vector2(30 + pose * 10.0, -18 - pose * 3.0), glow, 2.2, true)
			draw_arc(Vector2(0, -12), 24.0 + sin(_pulse * 7.0) * 2.0, 3.5, 5.7, 16, glow, 1.5)
		"soul_binder":
			draw_colored_polygon(PackedVector2Array([
				Vector2(-14, -38 + bob), Vector2(-9, -49 + bob), Vector2(0, -44 + bob),
				Vector2(9, -49 + bob), Vector2(14, -38 + bob), Vector2(8, -34 + bob), Vector2(-8, -34 + bob)
			]), light)
			draw_circle(Vector2(-5, -32 + bob), 2.0, glow)
			draw_circle(Vector2(5, -32 + bob), 2.0, glow)
			draw_line(Vector2(-12, -12 + bob), Vector2(-22 - pose * 4.0, -2 + pose * 3.0), metal, 4.0, true)
			draw_line(Vector2(12, -12 + bob), Vector2(22 + pose * 5.0, -2 - pose * 4.0), metal, 4.0, true)
			draw_circle(Vector2(27, -27 + bob + sin(_pulse * 2.4) * 4.0), 5.0, Color(glow, 0.25))
			draw_circle(Vector2(27, -27 + bob + sin(_pulse * 2.4) * 4.0), 2.8, glow)
	# Chest crest and glowing focal gem.
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -20 + bob), Vector2(5, -14 + bob), Vector2(0, -7 + bob), Vector2(-5, -14 + bob)
	]), glow)
	draw_circle(Vector2(0, -14 + bob), 2.0, Color.WHITE)
	draw_arc(Vector2(0, -14 + bob), 8.0, 0.2, PI - 0.2, 16, metal, 1.0)

	# Layered armor finish: engraved chest trim, belt hardware and character insignia.
	draw_line(Vector2(-10, -7 + bob), Vector2(10, -7 + bob), metal, 1.4, true)
	draw_line(Vector2(-8, -22 + bob), Vector2(0, -18 + bob), light, 1.2, true)
	draw_line(Vector2(8, -22 + bob), Vector2(0, -18 + bob), light, 1.2, true)
	draw_line(Vector2(-10, 2 + bob), Vector2(10, 2 + bob), dark, 3.0, true)
	draw_line(Vector2(-10, 2 + bob), Vector2(10, 2 + bob), metal, 1.0, true)
	draw_rect(Rect2(-2.5, -1 + bob, 5.0, 4.0), glow)
	draw_circle(Vector2(-12, -17 + bob), 1.7, metal)
	draw_circle(Vector2(12, -17 + bob), 1.7, metal)
	match character_id:
		"shadow_hunter":
			# Split hood tails and paired wrist blades make the assassin readable at a glance.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-8, -27 + bob), Vector2(-5, -20 + bob), Vector2(-10, -12 + bob),
				Vector2(-13, -24 + bob)
			]), light)
			draw_colored_polygon(PackedVector2Array([
				Vector2(8, -27 + bob), Vector2(5, -20 + bob), Vector2(10, -12 + bob),
				Vector2(13, -24 + bob)
			]), light)
			draw_line(Vector2(-18, -2), Vector2(-25 - pose * 3.0, -12), glow, 2.0, true)
			draw_line(Vector2(21 + pose * 8.0, -3 - pose * 5.0), Vector2(29 + pose * 10.0, -16 - pose * 4.0), glow, 2.0, true)
		"storm_reaper":
			# Segmented storm pauldrons and a charged crescent blade.
			draw_arc(Vector2(0, -14 + bob), 10.0, PI, TAU, 18, glow, 1.4, true)
			draw_line(Vector2(-15, -18 + bob), Vector2(-8, -23 + bob), metal, 2.0, true)
			draw_line(Vector2(15, -18 + bob), Vector2(8, -23 + bob), metal, 2.0, true)
			draw_line(Vector2(22 + pose * 7.0, -1 - pose * 4.0), Vector2(34 + pose * 9.0, -23 - pose * 4.0), glow, 3.0, true)
			draw_circle(Vector2(34 + pose * 9.0, -23 - pose * 4.0), 2.0, Color.WHITE)
		"soul_binder":
			# Rune chains and a floating focus orb frame the support mage silhouette.
			draw_arc(Vector2(0, -14 + bob), 11.0, 0.2, PI - 0.2, 18, glow, 1.2, true)
			draw_line(Vector2(-16, -3), Vector2(-22, -12), glow, 1.5, true)
			draw_line(Vector2(16, -3), Vector2(22, -12), glow, 1.5, true)
			var orb_offset := sin(_pulse * 2.4) * 4.0
			draw_colored_polygon(PackedVector2Array([
				Vector2(27, -31 + bob + orb_offset), Vector2(31, -27 + bob + orb_offset),
				Vector2(27, -23 + bob + orb_offset), Vector2(23, -27 + bob + orb_offset)
			]), glow)
	# A directional action arc makes attacks and skills legible even before VFX spawn.
	if absf(pose) > 0.12:
		var arc_alpha := clampf(absf(pose), 0.0, 0.85)
		var arc_color := Color(glow.r, glow.g, glow.b, arc_alpha)
		draw_arc(Vector2(13, -12 + bob), 23.0 + absf(pose) * 7.0, -1.0 + pose * 0.45, 1.0 + pose * 0.45, 20, arc_color, 1.2 + absf(pose), true)
