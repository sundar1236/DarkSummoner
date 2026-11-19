extends CharacterRigVisual

const GLBCharacterPreviewClass = preload("res://scripts/combat/glb_character_preview.gd")

var model_view: Control
var _model_ready := false

func _ready() -> void:
	super._ready()
	animation_player.animation_started.connect(_on_wrapper_animation_started)

	var preview := GLBCharacterPreviewClass.new()
	preview.name = "GeneratedShadowHunterViewport"
	preview.position = Vector2(-82.0, -82.0)
	preview.size = Vector2(164.0, 164.0)
	preview.model_scale = 0.82
	preview.camera_orthographic_size = 3.1
	preview.visible = false
	preview.model_loaded.connect(_on_model_loaded)
	preview.model_failed.connect(_on_model_failed)
	model_view = preview
	add_child(preview)

func _draw() -> void:
	if _model_ready:
		return
	super._draw()

func _on_model_loaded() -> void:
	_model_ready = true
	if is_instance_valid(model_view):
		model_view.visible = true
	_play_model_animation(String(animation_player.current_animation))

func _on_model_failed(reason: String) -> void:
	_model_ready = false
	push_warning("Shadow Hunter 3D model unavailable; retaining the visible 2D fallback. " + reason)

func _on_wrapper_animation_started(animation_name: StringName) -> void:
	_play_model_animation(String(animation_name))

func _play_model_animation(requested: String) -> void:
	if not _model_ready or not is_instance_valid(model_view) or requested.is_empty():
		return
	if not model_view.play_animation(requested):
		push_warning("Generated Shadow Hunter GLB has no animation clip: " + requested)
