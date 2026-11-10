class_name CharacterVisualContract
extends RefCounted

# Shared validation rules for replaceable player visual scenes.
# Gameplay nodes, collision shapes, and combat logic must never live in this scene.

const REQUIRED_CLIPS: Array[String] = ["idle", "run", "attack_1"]
const OPTIONAL_CLIPS: Array[String] = [
	"attack_2", "attack_3", "skill", "hurt", "dodge", "defeat", "victory"
]
const OPTIONAL_SOCKETS: Array[String] = [
	"WeaponSocket", "LeftWeaponSocket", "RightWeaponSocket"
]

static func validate(
	rig_root: Node,
	animation_player: AnimationPlayer,
	clip_names: Dictionary = {}
) -> Array[String]:
	var issues: Array[String] = []
	if not rig_root is Node2D:
		issues.append("Rig root must inherit Node2D.")
	if animation_player == null or not is_instance_valid(animation_player):
		issues.append("Rig must contain an AnimationPlayer.")
		return issues

	for clip_key in REQUIRED_CLIPS:
		var clip_name := str(clip_names.get(clip_key, clip_key))
		if not animation_player.has_animation(clip_name):
			issues.append("Missing required animation clip: %s" % clip_name)

	for clip_key in OPTIONAL_CLIPS:
		var clip_name := str(clip_names.get(clip_key, clip_key))
		if not animation_player.has_animation(clip_name):
			push_warning("Character visual has no optional '%s' clip; legacy fallback will be used." % clip_name)

	for socket_name in OPTIONAL_SOCKETS:
		var socket := rig_root.find_child(socket_name, true, false)
		if socket != null and not socket is Node2D:
			issues.append("%s must inherit Node2D to be used as an attachment." % socket_name)

	return issues

static func find_socket(rig_root: Node, socket_name: String) -> Node2D:
	if not is_instance_valid(rig_root) or socket_name.is_empty():
		return null
	var socket := rig_root.find_child(socket_name, true, false)
	return socket as Node2D if socket is Node2D else null
