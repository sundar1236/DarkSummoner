extends SceneTree

# Builds the Shadow Hunter cutout rig from the validated layered PNG manifest.
# Run:
# godot --headless --script tools/build_shadow_hunter_rig.gd -- --manifest=res://assets/art/characters/shadow_hunter/source/manifest.json --output=res://scenes/characters/shadow_hunter_visual.tscn

const DEFAULT_MANIFEST := "res://assets/art/characters/shadow_hunter/source/manifest.json"
const DEFAULT_OUTPUT := "res://scenes/characters/shadow_hunter_visual.tscn"
const VALIDATOR := preload("res://tools/validate_character_art_source.gd")

const LAYER_TO_BONE := {
	"back_cape": "BackCape",
	"rear_leg_upper": "RearLegUpper",
	"rear_leg_lower": "RearLegLower",
	"rear_boot": "RearBoot",
	"front_leg_upper": "FrontLegUpper",
	"front_leg_lower": "FrontLegLower",
	"front_boot": "FrontBoot",
	"pelvis_torso": "Body",
	"rear_arm_upper": "RearArmUpper",
	"rear_arm_lower": "RearArmLower",
	"rear_hand": "RearHand",
	"front_arm_upper": "FrontArmUpper",
	"front_arm_lower": "FrontArmLower",
	"front_hand": "FrontHand",
	"head_face": "Head",
	"hood_back": "HoodBack",
	"hood_front": "HoodFront",
	"hair_back": "HairBack",
	"hair_front": "HairFront",
	"left_dagger": "LeftDagger",
	"right_dagger": "RightDagger"
}

const PARENT_BONE := {
	"back_cape": "Root",
	"pelvis_torso": "Root",
	"rear_leg_upper": "Body",
	"rear_leg_lower": "RearLegUpper",
	"rear_boot": "RearLegLower",
	"front_leg_upper": "Body",
	"front_leg_lower": "FrontLegUpper",
	"front_boot": "FrontLegLower",
	"rear_arm_upper": "Body",
	"rear_arm_lower": "RearArmUpper",
	"rear_hand": "RearArmLower",
	"front_arm_upper": "Body",
	"front_arm_lower": "FrontArmUpper",
	"front_hand": "FrontArmLower",
	"head_face": "Body",
	"hood_back": "Head",
	"hood_front": "Head",
	"hair_back": "Head",
	"hair_front": "Head",
	"left_dagger": "RearHand",
	"right_dagger": "FrontHand"
}

const LAYER_ORDER: Array[String] = [
	"back_cape", "rear_leg_upper", "rear_leg_lower", "rear_boot",
	"front_leg_upper", "front_leg_lower", "front_boot", "pelvis_torso",
	"rear_arm_upper", "rear_arm_lower", "rear_hand",
	"front_arm_upper", "front_arm_lower", "front_hand",
	"head_face", "hood_back", "hair_back", "hood_front", "hair_front",
	"left_dagger", "right_dagger"
]

const LAYER_Z := {
	"back_cape": -8,
	"rear_leg_upper": -6, "rear_leg_lower": -6, "rear_boot": -6,
	"front_leg_upper": -4, "front_leg_lower": -4, "front_boot": -4,
	"pelvis_torso": 0,
	"rear_arm_upper": -1, "rear_arm_lower": -1, "rear_hand": -1,
	"front_arm_upper": 2, "front_arm_lower": 2, "front_hand": 2,
	"head_face": 4, "hood_back": 3, "hair_back": 5,
	"hood_front": 7, "hair_front": 8,
	"left_dagger": 9, "right_dagger": 10
}

func _initialize() -> void:
	var manifest_path := DEFAULT_MANIFEST
	var output_path := DEFAULT_OUTPUT
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")
		elif argument.begins_with("--output="):
			output_path = argument.trim_prefix("--output=")

	var validation_errors: Array[String] = VALIDATOR._validate_manifest(manifest_path)
	if not validation_errors.is_empty():
		for issue in validation_errors:
			push_error(issue)
		push_error("Rig generation stopped. Fix the source-art manifest and PNG package first.")
		quit(1)
		return

	var manifest_file := FileAccess.open(manifest_path, FileAccess.READ)
	var manifest: Dictionary = JSON.parse_string(manifest_file.get_as_text())
	manifest_file.close()

	var rig := _build_rig(manifest)
	var packed := PackedScene.new()
	var pack_error := packed.pack(rig)
	if pack_error != OK:
		push_error("Could not pack Shadow Hunter rig scene. Error: %s" % pack_error)
		rig.free()
		quit(1)
		return

	var save_error := ResourceSaver.save(packed, output_path)
	rig.free()
	if save_error != OK:
		push_error("Could not save rig scene to %s. Error: %s" % [output_path, save_error])
		quit(1)
		return

	print("Shadow Hunter rig generated: %s" % output_path)
	quit(0)

func _build_rig(manifest: Dictionary) -> Node2D:
	var canvas_size := Vector2(manifest["canvas_size"][0], manifest["canvas_size"][1])
	var ground_anchor := Vector2(manifest["ground_anchor"][0], manifest["ground_anchor"][1])
	var layer_data: Dictionary = {}
	for layer in manifest["layers"]:
		layer_data[str(layer["name"])] = layer

	var rig := Node2D.new()
	rig.name = "ShadowHunterVisual"
	rig.set_meta("character_id", "shadow_hunter")
	rig.set_meta("source_canvas_size", canvas_size)

	var skeleton := Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	rig.add_child(skeleton)
	skeleton.owner = rig

	var root_bone := Bone2D.new()
	root_bone.name = "Root"
	root_bone.position = Vector2.ZERO
	skeleton.add_child(root_bone)
	root_bone.owner = rig

	var bones: Dictionary = {"Root": root_bone}
	var pivots: Dictionary = {"Root": ground_anchor}

	for layer_name in LAYER_ORDER:
		if not layer_data.has(layer_name):
			continue
		var layer: Dictionary = layer_data[layer_name]
		var parent_name := str(PARENT_BONE[layer_name])
		var parent_bone: Bone2D = bones[parent_name]
		var pivot := Vector2(layer["pivot"][0], layer["pivot"][1])
		var bone := Bone2D.new()
		bone.name = str(LAYER_TO_BONE[layer_name])
		bone.position = pivot - Vector2(pivots[parent_name])
		parent_bone.add_child(bone)
		bone.owner = rig
		bones[bone.name] = bone
		pivots[bone.name] = pivot

		var texture := load(str(layer["file"])) as Texture2D
		var part := Sprite2D.new()
		part.name = "Part_%s" % layer_name
		part.texture = texture
		part.centered = false
		part.offset = -pivot
		part.position = Vector2.ZERO
		part.z_index = int(LAYER_Z.get(layer_name, 0))
		bone.add_child(part)
		part.owner = rig

	_add_weapon_socket(bones["RearHand"], "LeftWeaponSocket", rig)
	_add_weapon_socket(bones["FrontHand"], "RightWeaponSocket", rig)
	var primary_socket := Node2D.new()
	primary_socket.name = "WeaponSocket"
	primary_socket.position = Vector2(18.0, -8.0)
	bones["Body"].add_child(primary_socket)
	primary_socket.owner = rig

	var animation_player := AnimationPlayer.new()
	animation_player.name = "AnimationPlayer"
	rig.add_child(animation_player)
	animation_player.owner = rig
	animation_player.root_node = NodePath("..")
	_add_animations(animation_player)
	animation_player.autoplay = "idle"

	return rig

func _add_weapon_socket(parent: Node2D, socket_name: String, owner_root: Node) -> void:
	var socket := Node2D.new()
	socket.name = socket_name
	parent.add_child(socket)
	socket.owner = owner_root

func _add_animations(player: AnimationPlayer) -> void:
	var library := AnimationLibrary.new()
	library.add_animation("idle", _make_animation(1.2, true, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.6, 0.015], [1.2, 0.0]],
		"Skeleton2D/Body/Head": [[0.0, 0.0], [0.6, -0.025], [1.2, 0.0]],
		"Skeleton2D/Root/BackCape": [[0.0, 0.0], [0.6, 0.025], [1.2, 0.0]]
	}))
	library.add_animation("run", _make_animation(0.48, true, {
		"Skeleton2D/Root/Body": [[0.0, -0.035], [0.12, 0.035], [0.24, -0.035], [0.36, 0.035], [0.48, -0.035]],
		"Skeleton2D/Root/Body/RearLegUpper": [[0.0, -0.45], [0.24, 0.45], [0.48, -0.45]],
		"Skeleton2D/Root/Body/FrontLegUpper": [[0.0, 0.45], [0.24, -0.45], [0.48, 0.45]],
		"Skeleton2D/Root/Body/RearArmUpper": [[0.0, 0.35], [0.24, -0.35], [0.48, 0.35]],
		"Skeleton2D/Root/Body/FrontArmUpper": [[0.0, -0.35], [0.24, 0.35], [0.48, -0.35]]
	}))
	library.add_animation("attack_1", _make_animation(0.28, false, {
		"Skeleton2D/Root/Body/FrontArmUpper": [[0.0, -0.15], [0.08, -1.0], [0.18, 0.25], [0.28, 0.0]],
		"Skeleton2D/Root/Body/FrontArmUpper/FrontArmLower": [[0.0, 0.0], [0.08, -0.55], [0.18, 0.45], [0.28, 0.0]],
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.08, -0.08], [0.18, 0.1], [0.28, 0.0]]
	}))
	library.add_animation("attack_2", _make_animation(0.3, false, {
		"Skeleton2D/Root/Body/RearArmUpper": [[0.0, 0.0], [0.08, 0.95], [0.2, -0.2], [0.3, 0.0]],
		"Skeleton2D/Root/Body/RearArmUpper/RearArmLower": [[0.0, 0.0], [0.08, 0.55], [0.2, -0.4], [0.3, 0.0]],
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.08, 0.1], [0.2, -0.08], [0.3, 0.0]]
	}))
	library.add_animation("attack_3", _make_animation(0.42, false, {
		"Skeleton2D/Root/Body/FrontArmUpper": [[0.0, 0.0], [0.1, -1.2], [0.25, 0.65], [0.42, 0.0]],
		"Skeleton2D/Root/Body/RearArmUpper": [[0.0, 0.0], [0.1, 0.8], [0.25, -0.55], [0.42, 0.0]],
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.1, -0.14], [0.25, 0.16], [0.42, 0.0]]
	}))
	library.add_animation("skill", _make_animation(0.75, false, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.2, -0.18], [0.5, 0.08], [0.75, 0.0]],
		"Skeleton2D/Root/Body/FrontArmUpper": [[0.0, 0.0], [0.2, -1.25], [0.5, -1.55], [0.75, 0.0]],
		"Skeleton2D/Root/Body/RearArmUpper": [[0.0, 0.0], [0.2, 1.25], [0.5, 1.55], [0.75, 0.0]]
	}))
	library.add_animation("hurt", _make_animation(0.22, false, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.06, -0.18], [0.22, 0.0]]
	}))
	library.add_animation("dodge", _make_animation(0.24, false, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.08, -0.3], [0.16, 0.25], [0.24, 0.0]],
		"Skeleton2D/Root/BackCape": [[0.0, 0.0], [0.12, -0.35], [0.24, 0.0]]
	}))
	library.add_animation("defeat", _make_animation(0.8, false, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.45, 1.0], [0.8, 1.25]],
		"Skeleton2D/Root/Body/Head": [[0.0, 0.0], [0.45, 0.35], [0.8, 0.55]]
	}))
	library.add_animation("victory", _make_animation(0.9, false, {
		"Skeleton2D/Root/Body": [[0.0, 0.0], [0.25, -0.12], [0.55, 0.08], [0.9, 0.0]],
		"Skeleton2D/Root/Body/FrontArmUpper": [[0.0, 0.0], [0.25, -1.0], [0.55, -0.9], [0.9, 0.0]]
	}))
	player.add_animation_library("", library)

func _make_animation(duration: float, looping: bool, tracks: Dictionary) -> Animation:
	var animation := Animation.new()
	animation.length = duration
	animation.loop_mode = Animation.LOOP_LINEAR if looping else Animation.LOOP_NONE
	for node_path in tracks:
		var track_index := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index, NodePath("%s:rotation" % node_path))
		animation.value_track_set_update_mode(track_index, Animation.UPDATE_CONTINUOUS)
		for key_data in tracks[node_path]:
			animation.track_insert_key(track_index, float(key_data[0]), float(key_data[1]))
	return animation
