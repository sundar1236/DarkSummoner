extends SceneTree

# Validates animation-ready enemy and boss sprite-sheet source packages.
# Run from the project root:
# godot --headless --script tools/validate_enemy_boss_art_source.gd -- --manifest=res://assets/art/enemies/source/manifest.json

const DEFAULT_MANIFEST := "res://assets/art/enemies/source/manifest.json"
const REQUIRED_CLIPS: Array[String] = ["idle", "move", "attack", "hurt", "defeat"]

func _initialize() -> void:
	var manifest_path := DEFAULT_MANIFEST
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")

	var errors := _validate_manifest(manifest_path)
	if errors.is_empty():
		print("Enemy/boss source-art package is valid: %s" % manifest_path)
		quit(0)
		return

	for issue in errors:
		push_error(issue)
	quit(1)

static func _validate_manifest(manifest_path: String) -> Array[String]:
	var errors: Array[String] = []
	if not FileAccess.file_exists(manifest_path):
		errors.append("Manifest not found: %s" % manifest_path)
		return errors

	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		errors.append("Could not open manifest: %s" % manifest_path)
		return errors

	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		errors.append("Manifest JSON parse error at line %d: %s" % [
			parser.get_error_line(), parser.get_error_message()
		])
		return errors

	var data: Variant = parser.data
	if not data is Dictionary:
		errors.append("Manifest root must be a JSON object.")
		return errors

	var actors: Variant = data.get("actors", null)
	if not actors is Array or actors.is_empty():
		errors.append("actors must be a non-empty array.")
		return errors

	var actor_ids: Dictionary = {}
	for actor_index in range(actors.size()):
		var actor: Variant = actors[actor_index]
		if not actor is Dictionary:
			errors.append("actors[%d] must be an object." % actor_index)
			continue

		var actor_id := str(actor.get("id", "")).strip_edges()
		if actor_id.is_empty():
			errors.append("actors[%d] has no id." % actor_index)
		elif actor_ids.has(actor_id):
			errors.append("Duplicate actor id: %s" % actor_id)
		else:
			actor_ids[actor_id] = true

		var role := str(actor.get("role", "")).strip_edges()
		if role not in ["enemy", "boss"]:
			errors.append("Actor '%s' role must be 'enemy' or 'boss'." % actor_id)

		var source_path := str(actor.get("source", "")).strip_edges()
		var frame_size: Variant = actor.get("frame_size", null)
		var columns := int(actor.get("columns", 0))
		var rows := int(actor.get("rows", 0))
		if source_path.is_empty():
			errors.append("Actor '%s' has no source spritesheet path." % actor_id)
		if not frame_size is Array or frame_size.size() != 2:
			errors.append("Actor '%s' frame_size must be [width, height]." % actor_id)
			continue
		var frame_width := int(frame_size[0])
		var frame_height := int(frame_size[1])
		if frame_width <= 0 or frame_height <= 0 or columns <= 0 or rows <= 0:
			errors.append("Actor '%s' frame dimensions, columns, and rows must be positive." % actor_id)
			continue

		if not source_path.is_empty():
			var image := Image.new()
			var image_error := image.load(source_path)
			if image_error != OK:
				errors.append("Actor '%s' spritesheet could not be loaded: %s" % [actor_id, source_path])
			else:
				var expected_width := frame_width * columns
				var expected_height := frame_height * rows
				if image.get_width() != expected_width or image.get_height() != expected_height:
					errors.append("Actor '%s' spritesheet is %dx%d; expected %dx%d from frame_size and grid." % [
						actor_id, image.get_width(), image.get_height(), expected_width, expected_height
					])
				if not image.has_alpha():
					errors.append("Actor '%s' spritesheet must use an alpha channel." % actor_id)

		var clips: Variant = actor.get("clips", null)
		if not clips is Array:
			errors.append("Actor '%s' clips must be an array." % actor_id)
			continue

		var clip_names: Dictionary = {}
		for clip_index in range(clips.size()):
			var clip: Variant = clips[clip_index]
			if not clip is Dictionary:
				errors.append("Actor '%s' clips[%d] must be an object." % [actor_id, clip_index])
				continue
			var clip_name := str(clip.get("name", "")).strip_edges()
			if clip_name.is_empty():
				errors.append("Actor '%s' clips[%d] has no name." % [actor_id, clip_index])
				continue
			if clip_names.has(clip_name):
				errors.append("Actor '%s' has duplicate clip '%s'." % [actor_id, clip_name])
			clip_names[clip_name] = true

			var fps := float(clip.get("fps", 0.0))
			if fps <= 0.0:
				errors.append("Actor '%s' clip '%s' fps must be greater than zero." % [actor_id, clip_name])
			var frames: Variant = clip.get("frames", null)
			if not frames is Array or frames.is_empty():
				errors.append("Actor '%s' clip '%s' frames must be a non-empty array." % [actor_id, clip_name])
				continue
			for frame_value in frames:
				var frame_index := int(frame_value)
				if frame_index < 0 or frame_index >= columns * rows:
					errors.append("Actor '%s' clip '%s' references out-of-range frame %d." % [
						actor_id, clip_name, frame_index
					])
			if not clip.has("loop"):
				errors.append("Actor '%s' clip '%s' must declare loop true or false." % [actor_id, clip_name])

		for required_clip in REQUIRED_CLIPS:
			if not clip_names.has(required_clip):
				errors.append("Actor '%s' is missing required clip '%s'." % [actor_id, required_clip])

	return errors
