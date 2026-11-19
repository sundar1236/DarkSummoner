extends Control

signal model_loaded
signal model_failed(reason: String)

const CHARACTER_MODELS: Dictionary = {
	"shadow_hunter": "res://assets/generated/shadow_hunter.glb"
}

@export var character_id: String = "shadow_hunter"
@export_range(0.2, 3.0, 0.05) var model_scale: float = 1.0
@export_range(1.5, 8.0, 0.1) var camera_orthographic_size: float = 3.1

var viewport_container: SubViewportContainer
var model_viewport: SubViewport
var model_world: Node3D
var model_camera: Camera3D
var model_root: Node3D
var model_animation_player: AnimationPlayer
var _loaded_character_id := ""
var _model_ready := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	_build_viewport()
	_load_character_model()

func set_character(next_character_id: String) -> bool:
	if character_id == next_character_id and _model_ready:
		return true
	character_id = next_character_id
	if not is_inside_tree():
		return false
	_load_character_model()
	return _model_ready

func play_animation(animation_name: String) -> bool:
	if not _model_ready or not is_instance_valid(model_animation_player):
		return false
	for candidate in model_animation_player.get_animation_list():
		var parts := String(candidate).split("/")
		if parts[parts.size() - 1] == animation_name:
			model_animation_player.play(candidate)
			return true
	return false

func _build_viewport() -> void:
	viewport_container = SubViewportContainer.new()
	viewport_container.name = "CharacterModelViewportContainer"
	viewport_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	viewport_container.stretch = true
	viewport_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	viewport_container.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(viewport_container)

	model_viewport = SubViewport.new()
	model_viewport.name = "CharacterModelViewport"
	model_viewport.size = Vector2i(512, 512)
	model_viewport.transparent_bg = true
	model_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport_container.add_child(model_viewport)

	model_world = Node3D.new()
	model_world.name = "CharacterModelWorld"
	model_viewport.add_child(model_world)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_CLEAR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.62, 0.58, 0.72, 1.0)
	environment.ambient_light_energy = 0.85
	world_environment.environment = environment
	model_world.add_child(world_environment)

	model_camera = Camera3D.new()
	model_camera.name = "CharacterModelCamera"
	model_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	model_camera.size = camera_orthographic_size
	model_camera.position = Vector3(3.4, 2.7, 5.8)
	model_world.add_child(model_camera)
	# Camera3D.look_at() requires the camera to be inside the scene tree.
	# The previous implementation called it before add_child(), leaving the
	# camera facing away from the model and producing an invisible character.
	model_camera.look_at(Vector3(0.0, 1.12, 0.0), Vector3.UP)
	model_camera.current = true

	var key_light := DirectionalLight3D.new()
	key_light.name = "CharacterKeyLight"
	key_light.rotation_degrees = Vector3(-38.0, -28.0, -12.0)
	key_light.light_color = Color(1.0, 0.88, 0.78, 1.0)
	key_light.light_energy = 1.65
	model_world.add_child(key_light)

	var fill_light := OmniLight3D.new()
	fill_light.name = "CharacterFillLight"
	fill_light.position = Vector3(-2.8, 2.0, 3.0)
	fill_light.light_color = Color(0.48, 0.32, 1.0, 1.0)
	fill_light.light_energy = 1.1
	fill_light.omni_range = 8.0
	model_world.add_child(fill_light)

func _load_character_model() -> void:
	_model_ready = false
	_loaded_character_id = ""
	if is_instance_valid(model_root):
		model_root.queue_free()
		model_root = null
	model_animation_player = null

	var model_path := str(CHARACTER_MODELS.get(character_id, ""))
	if model_path.is_empty() or not ResourceLoader.exists(model_path):
		if is_instance_valid(viewport_container):
			viewport_container.visible = false
		return

	var packed_model := load(model_path) as PackedScene
	if packed_model == null:
		_fail_model("The generated character GLB did not import as a PackedScene: " + model_path)
		return

	model_root = packed_model.instantiate() as Node3D
	if model_root == null:
		_fail_model("The generated character GLB root is not Node3D: " + model_path)
		return

	model_root.name = "GeneratedCharacterModel"
	model_root.scale = Vector3.ONE * model_scale
	model_world.add_child(model_root)

	model_animation_player = model_root.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if model_animation_player == null:
		_fail_model("The generated character GLB is missing its AnimationPlayer.")
		return

	var mesh_count := _count_mesh_instances(model_root)
	if mesh_count <= 0:
		_fail_model("The generated character GLB contains no visible MeshInstance3D nodes.")
		return

	_loaded_character_id = character_id
	_model_ready = true
	viewport_container.visible = true
	play_animation("idle")
	model_loaded.emit()

func _count_mesh_instances(node: Node) -> int:
	var count := 1 if node is MeshInstance3D and (node as MeshInstance3D).mesh != null else 0
	for child in node.get_children():
		count += _count_mesh_instances(child)
	return count

func _fail_model(reason: String) -> void:
	push_error(reason)
	_model_ready = false
	if is_instance_valid(viewport_container):
		viewport_container.visible = false
	model_failed.emit(reason)
