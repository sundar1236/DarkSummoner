extends SceneTree

# Validates a layered Shadow Hunter source-art package before it is imported into Godot.
# Run from the project root:
# godot --headless --script tools/validate_character_art_source.gd -- --manifest=res://assets/art/characters/shadow_hunter/source/manifest.json

const REQUIRED_LAYERS: Array[String] = [
	"back_cape",
	"rear_leg_upper",
	"rear_leg_lower",
	"rear_boot",
	"front_leg_upper",
	"front_leg_lower",
	"front_boot",
	"pelvis_torso",
	"rear_arm_upper",
	"rear_arm_lower",
	"rear_hand",
	"front_arm_upper",
	"front_arm_lower",
	"front_hand",
	"head_face",
	"hood_back",
	"hood_front",
	"hair_back",
	"hair_front",
	"left_dagger",
	"right_dagger"
]

func _initialize() -> void:
	var manifest_path := "res://assets/art/characters/shadow_hunter/source/manifest.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--manifest="):
			manifest_path = argument.trim_prefix("--manifest=")

	var errors := _validate_manifest(manifest_path)
	if errors.is_empty():
		print("Shadow Hunter source-art package is valid: %s" % manifest_path)
		quit(0)
		return

	for issue in errors:
		push_error(issue)
	quit(1)

func _validate_manifest(manifest_path: String) -> Array[String]:
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
		errors.append("Manifest JSON parse error at line %d: %s" % [parser.get_error_line(), parser.get_error_message()])
		return errors

	var data: Variant = parser.data
	if not data is Dictionary:
		errors.append("Manifest root must be a JSON object.")
		return errors

	var canvas_size: Variant = data.get("canvas_size", null)
	if not canvas_size is Array or canvas_size.size() != 2:
		errors.append("canvas_size must be [width, height].")
		return errors
	if int(canvas_size[0]) <= 0 or int(canvas_size[1]) <= 0:
		errors.append("canvas_size dimensions must be positive integers.")
		return errors

	var layers: Variant = data.get("layers", null)
	if not layers is Array:
		errors.append("layers must be an array.")
		return errors

	var found_names: Dictionary = {}
	var expected_size := Vector2i(int(canvas_size[0]), int(canvas_size[1]))
	for index in range(layers.size()):
		var layer: Variant = layers[index]
		if not layer is Dictionary:
			errors.append("layers[%d] must be an object." % index)
			continue

		var layer_name := str(layer.get("name", "")).strip_edges()
		var relative_path := str(layer.get("file", "")).strip_edges()
		var pivot: Variant = layer.get("pivot", null)
		if layer_name.is_empty():
			errors.append("layers[%d] has no name." % index)
			continue
		if found_names.has(layer_name):
			errors.append("Duplicate layer name: %s" % layer_name)
		found_names[layer_name] = true

		if relative_path.is_empty():
			errors.append("Layer '%s' has no file path." % layer_name)
			continue
		if not pivot is Array or pivot.size() != 2:
			errors.append("Layer '%s' pivot must be [x, y]." % layer_name)
			continue

		var image := Image.new()
		var image_error := image.load(relative_path)
		if image_error != OK:
			errors.append("Layer '%s' image could not be loaded: %s" % [layer_name, relative_path])
			continue
		if Vector2i(image.get_width(), image.get_height()) != expected_size:
			errors.append("Layer '%s' is %dx%d; expected %dx%d." % [
				layer_name, image.get_width(), image.get_height(), expected_size.x, expected_size.y
			])
		if not image.has_alpha():
			errors.append("Layer '%s' must use an alpha channel." % layer_name)
		if float(pivot[0]) < 0.0 or float(pivot[1]) < 0.0 or float(pivot[0]) > expected_size.x or float(pivot[1]) > expected_size.y:
			errors.append("Layer '%s' pivot is outside the shared canvas." % layer_name)

	for required_name in REQUIRED_LAYERS:
		if not found_names.has(required_name):
			errors.append("Required layer is missing: %s" % required_name)

	return errors
