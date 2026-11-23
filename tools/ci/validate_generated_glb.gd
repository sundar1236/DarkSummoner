extends SceneTree

func _initialize() -> void:
    var packed := load("res://assets/generated/shadow_hunter.glb") as PackedScene
    if packed == null:
        push_error("Generated Shadow Hunter GLB did not import as a PackedScene.")
        quit(1)
        return
    var instance := packed.instantiate()
    var animation_player := instance.find_child("AnimationPlayer", true, false) as AnimationPlayer
    if animation_player == null:
        push_error("Generated Shadow Hunter GLB is missing its AnimationPlayer.")
        instance.free()
        quit(1)
        return
    var required := ["idle", "run", "attack_1", "attack_2", "attack_3", "skill", "hurt", "dodge", "defeat", "victory"]
    var available := animation_player.get_animation_list()
    var missing: Array[String] = []
    for required_name in required:
        var found := false
        for candidate in available:
            var parts := String(candidate).split("/")
            if parts[-1] == required_name:
                found = true
                break
        if not found:
            missing.append(required_name)
    if not missing.is_empty():
        push_error("Generated GLB is missing animation clips: " + ", ".join(missing))
        instance.free()
        quit(1)
        return
    print("GLB VALIDATION PASSED: rig, AnimationPlayer and all 10 gameplay clips found.")
    instance.free()
    quit(0)
