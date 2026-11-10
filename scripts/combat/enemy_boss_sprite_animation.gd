class_name EnemyBossSpriteAnimation
extends Node

# Optional runtime sprite-sheet animator. Controllers keep their existing Sprite2D
# as a fallback until approved source sheets are supplied.
@export var manifest_path: String = "res://assets/art/enemies/source/manifest.json"
@export var actor_id: String = ""
@export var sprite_frames_path: String = ""
@export var animation_node_name: String = "AuthoredAnimation"

var animated_sprite: AnimatedSprite2D

func _ready() -> void:
	if not sprite_frames_path.is_empty():
		_load_from_manifest(sprite_frames_path)

func setup_from_manifest(p_manifest_path: String, p_actor_id: String) -> bool:
	manifest_path = p_manifest_path
	actor_id = p_actor_id
	return _load_from_manifest(manifest_path)

func _load_from_manifest(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var parser := JSON.new()
	var parse_result := parser.parse(file.get_as_text())
	file.close()
	if parse_result != OK or not parser.data is Dictionary:
		push_warning("Enemy/boss animation manifest could not be parsed: %s" % path)
		return false
	var actors: Variant = parser.data.get("actors", [])
	if not actors is Array:
		return false
	for actor in actors:
		if actor is Dictionary and str(actor.get("id", "")) == actor_id:
			return _build_animation(actor)
	return false

func _build_animation(actor: Dictionary) -> bool:
	var source_path := str(actor.get("source", ""))
	var frame_size: Variant = actor.get("frame_size", [])
	var columns := int(actor.get("columns", 0))
	var rows := int(actor.get("rows", 0))
	if source_path.is_empty() or not frame_size is Array or frame_size.size() != 2 or columns <= 0 or rows <= 0:
		return false
	var image := Image.new()
	if image.load(source_path) != OK:
		return false
	var width := int(frame_size[0])
	var height := int(frame_size[1])
	if image.get_width() != width * columns or image.get_height() != height * rows:
		push_warning("Spritesheet grid does not match manifest for actor '%s'." % actor_id)
		return false
	var texture := ImageTexture.create_from_image(image)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var clips: Variant = actor.get("clips", [])
	if not clips is Array:
		return false
	for clip in clips:
		if not clip is Dictionary:
			continue
		var clip_name := str(clip.get("name", ""))
		var indices: Variant = clip.get("frames", [])
		if clip_name.is_empty() or not indices is Array or indices.is_empty():
			continue
		frames.add_animation(clip_name)
		frames.set_animation_speed(clip_name, maxf(1.0, float(clip.get("fps", 8.0))))
		frames.set_animation_loop(clip_name, bool(clip.get("loop", false)))
		for index_value in indices:
			var frame_index := int(index_value)
			if frame_index < 0 or frame_index >= columns * rows:
				continue
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(
				(float(frame_index % columns) * width),
				(float(floori(float(frame_index) / columns)) * height),
				width,
				height
			)
			frames.add_frame(clip_name, atlas)
	if frames.get_animation_names().is_empty():
		return false
	animated_sprite = AnimatedSprite2D.new()
	animated_sprite.name = animation_node_name
	animated_sprite.sprite_frames = frames
	animated_sprite.centered = true
	add_child(animated_sprite)
	play("idle")
	return true

func play(clip_name: String, force_restart: bool = false) -> void:
	if not is_instance_valid(animated_sprite) or animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(clip_name):
		return
	if force_restart or animated_sprite.animation != clip_name:
		animated_sprite.play(clip_name)

func is_ready_for_animation() -> bool:
	return is_instance_valid(animated_sprite) and animated_sprite.sprite_frames != null
