extends SceneTree

# Validates layered 2.5D floor environment artwork before it is imported into the game.
# Run from the project root:
# godot --headless --script tools/validate_floor_environment_art.gd -- --manifest=res://assets/art/environments/floors/manifest.json

const DEFAULT_MANIFEST := "res://assets/art/environments/floors/manifest.json"
const REQUIRED_ROLES: Array[String] = ["background", "floor", "props", "foreground"]
const EXPECTED_SIZE := Vector2i(720, 1280)

func _initialize() -> void:
	var manifest_path := DEFAULT_MANIFEST
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")

	var errors := _validate_manifest(manifest_path)
	if errors.is_empty():
		print("Floor environment art package is valid: %s" % manifest_path)
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
	if int(data.get("schema_version", 0)) != 1:
		errors.append("schema_version must be 1.")

	var floors: Variant = data.get("floors", null)
	if not floors is Array or floors.is_empty():
		errors.append("floors must be a non-empty array.")
		return errors

	var floor_ids: Dictionary = {}
	for floor_index in range(floors.size()):
		var floor_data: Variant = floors[floor_index]
		if not floor_data is Dictionary:
			errors.append("floors[%d] must be an object." % floor_index)
			continue

		var floor_id := str(floor_data.get("id", "")).strip_edges()
		if floor_id.is_empty():
			errors.append("floors[%d] has no id." % floor_index)
		elif floor_ids.has(floor_id):
			errors.append("Duplicate floor id: %s" % floor_id)
		else:
			floor_ids[floor_id] = true

		var layers: Variant = floor_data.get("layers", null)
		if not layers is Array:
			errors.append("Floor '%s' layers must be an array." % floor_id)
			continue

		var roles: Dictionary = {}
		for layer_index in range(layers.size()):
			var layer: Variant = layers[layer_index]
			if not layer is Dictionary:
				errors.append("Floor '%s' layers[%d] must be an object." % [floor_id, layer_index])
				continue

			var role := str(layer.get("role", "")).strip_edges()
			if role not in REQUIRED_ROLES:
				errors.append("Floor '%s' has unsupported layer role '%s'." % [floor_id, role])
				continue
			if roles.has(role):
				errors.append("Floor '%s' has duplicate '%s' layer." % [floor_id, role])
			roles[role] = true

			var source := str(layer.get("source", "")).strip_edges()
			if source.is_empty():
				errors.append("Floor '%s' layer '%s' has no source path." % [floor_id, role])
				continue
			if not FileAccess.file_exists(source):
				errors.append("Floor '%s' layer '%s' image not found: %s" % [floor_id, role, source])
				continue

			var image := Image.new()
			var image_error := image.load(source)
			if image_error != OK:
				errors.append("Floor '%s' layer '%s' image could not be loaded: %s" % [floor_id, role, source])
				continue
			if Vector2i(image.get_width(), image.get_height()) != EXPECTED_SIZE:
				errors.append("Floor '%s' layer '%s' is %dx%d; expected %dx%d." % [
					floor_id, role, image.get_width(), image.get_height(),
					EXPECTED_SIZE.x, EXPECTED_SIZE.y
				])
			if role != "background" and not image.has_alpha():
				errors.append("Floor '%s' layer '%s' must include an alpha channel." % [floor_id, role])

		for required_role in REQUIRED_ROLES:
			if not roles.has(required_role):
				errors.append("Floor '%s' is missing required '%s' layer." % [floor_id, required_role])

	return errors
