extends Node2D

const MODEL_PATH := "res://assets/generated/shadow_hunter.glb"
const CLIPS := ["idle", "run", "attack_1", "attack_2", "attack_3", "skill", "hurt", "dodge", "defeat", "victory"]

var model_animation_player: AnimationPlayer
var viewport: SubViewport

func _ready() -> void:
    if not ResourceLoader.exists(MODEL_PATH):
        push_warning("Generated Shadow Hunter GLB is missing; keep the legacy sprite visual.")
        return

    var container := SubViewportContainer.new()
    container.name = "ModelViewportContainer"
    container.position = Vector2(-76, -82)
    container.size = Vector2(152, 152)
    container.stretch = true
    container.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(container)

    viewport = SubViewport.new()
    viewport.name = "ModelViewport"
    viewport.size = Vector2i(256, 256)
    viewport.transparent_bg = true
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    container.add_child(viewport)

    var world := Node3D.new()
    world.name = "ModelWorld"
    viewport.add_child(world)

    var camera := Camera3D.new()
    camera.name = "ModelCamera"
    camera.position = Vector3(3.0, -6.5, 3.1)
    camera.fov = 34.0
    camera.look_at(Vector3(0.0, 0.0, 1.08), Vector3.UP)
    world.add_child(camera)

    var key_light := DirectionalLight3D.new()
    key_light.rotation_degrees = Vector3(-32.0, -28.0, -18.0)
    key_light.light_energy = 1.35
    world.add_child(key_light)

    var fill_light := OmniLight3D.new()
    fill_light.position = Vector3(-3.0, -3.0, 2.8)
    fill_light.light_color = Color(0.48, 0.30, 0.95)
    fill_light.light_energy = 0.65
    fill_light.omni_range = 8.0
    world.add_child(fill_light)

    var packed_model := load(MODEL_PATH) as PackedScene
    if packed_model == null:
        push_error("Shadow Hunter GLB did not import as a PackedScene.")
        return
    var model := packed_model.instantiate() as Node3D
    if model == null:
        push_error("Shadow Hunter GLB root is not Node3D.")
        return
    model.name = "ShadowHunterModel"
    model.scale = Vector3.ONE * 0.82
    world.add_child(model)

    model_animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if model_animation_player == null:
        push_error("Shadow Hunter GLB has no AnimationPlayer.")
        return

    var wrapper_player := AnimationPlayer.new()
    wrapper_player.name = "AnimationPlayer"
    add_child(wrapper_player)
    var library := AnimationLibrary.new()
    for clip in CLIPS:
        var animation := Animation.new()
        animation.length = 0.65
        if clip == "idle":
            animation.length = 1.0
            animation.loop_mode = Animation.LOOP_LINEAR
        elif clip == "run":
            animation.length = 0.55
            animation.loop_mode = Animation.LOOP_LINEAR
        library.add_animation(clip, animation)
    wrapper_player.add_animation_library("", library)
    wrapper_player.animation_started.connect(_on_wrapper_animation_started)
    model_animation_player.animation_finished.connect(_on_model_animation_finished)
    wrapper_player.play("idle")

func _on_wrapper_animation_started(animation_name: StringName) -> void:
    if not is_instance_valid(model_animation_player):
        return
    var requested := String(animation_name)
    for candidate in model_animation_player.get_animation_list():
        var parts := String(candidate).split("/")
        var plain_name := parts[parts.size() - 1]
        if plain_name == requested:
            model_animation_player.play(candidate)
            return
    push_warning("GLB animation clip is missing: " + requested)

func _on_model_animation_finished(_animation_name: StringName) -> void:
    if not is_instance_valid(model_animation_player):
        return
    var current := String(model_animation_player.current_animation)
    if current == "idle" or current == "run":
        model_animation_player.play(current)
