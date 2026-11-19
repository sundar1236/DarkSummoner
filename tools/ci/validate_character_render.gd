extends SceneTree

func _initialize() -> void:
	call_deferred("_run_validation")

func _run_validation() -> void:
	var scene := load("res://scenes/characters/shadow_hunter_visual.tscn") as PackedScene
	if scene == null:
		_fail("Shadow Hunter visual scene could not be loaded.")
		return

	var rig := scene.instantiate() as Node2D
	if rig == null:
		_fail("Shadow Hunter visual scene did not instantiate as Node2D.")
		return
	root.add_child(rig)
	await process_frame
	await process_frame

	var preview := rig.get_node_or_null("GeneratedShadowHunterViewport") as Control
	if preview == null:
		_fail("The combat character scene did not create its generated 3D viewport.")
		return
	if not bool(preview.get("_model_ready")):
		_fail("The combat character scene did not activate the generated 3D model.")
		return

	var model_root := preview.get("model_root") as Node3D
	var model_camera := preview.get("model_camera") as Camera3D
	var model_viewport := preview.get("model_viewport") as SubViewport
	var animation_player := preview.get("model_animation_player") as AnimationPlayer
	if model_root == null or model_camera == null or model_viewport == null or animation_player == null:
		_fail("The generated 3D viewport is missing its model, camera, viewport, or AnimationPlayer.")
		return

	var meshes := model_root.find_children("*", "MeshInstance3D", true, false)
	var visible_mesh_count := 0
	for mesh_node in meshes:
		var mesh_instance := mesh_node as MeshInstance3D
		if mesh_instance and mesh_instance.visible and mesh_instance.mesh != null:
			visible_mesh_count += 1
	if visible_mesh_count == 0:
		_fail("The generated model contains no visible mesh geometry.")
		return

	if not model_camera.is_inside_tree() or not model_camera.current:
		_fail("The generated model camera is not active inside the viewport scene tree.")
		return
	var target_direction := (Vector3(0.0, 1.12, 0.0) - model_camera.global_position).normalized()
	var camera_forward := -model_camera.global_transform.basis.z.normalized()
	if camera_forward.dot(target_direction) < 0.98:
		_fail("The generated model camera is not aimed at the character. Dot=%s" % camera_forward.dot(target_direction))
		return
	if model_viewport.render_target_update_mode != SubViewport.UPDATE_ALWAYS:
		_fail("The generated model viewport is not updating continuously.")
		return

	for _frame in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	var rendered_image := model_viewport.get_texture().get_image()
	if rendered_image == null or rendered_image.is_empty():
		_fail("The generated character viewport did not produce a readable render texture.")
		return
	var rendered_pixel_count := 0
	for y in range(0, rendered_image.get_height(), 2):
		for x in range(0, rendered_image.get_width(), 2):
			var pixel := rendered_image.get_pixel(x, y)
			if pixel.a > 0.05 and pixel.r + pixel.g + pixel.b > 0.05:
				rendered_pixel_count += 1
	if rendered_pixel_count < 100:
		_fail("The generated character viewport rendered too few visible pixels: %d" % rendered_pixel_count)
		return

	for clip_name in ["idle", "run", "attack_1", "attack_2", "attack_3", "skill", "hurt", "dodge", "defeat", "victory"]:
		var found := false
		for candidate in animation_player.get_animation_list():
			var parts := String(candidate).split("/")
			if parts[parts.size() - 1] == clip_name:
				found = true
				break
		if not found:
			_fail("The runtime model is missing animation: " + clip_name)
			return

	if not bool(preview.call("play_animation", "run")):
		_fail("The runtime model could not start its run animation.")
		return
	if not bool(preview.call("play_animation", "idle")):
		_fail("The runtime model could not return to its idle animation.")
		return

	# The same generated model must be reused by the main-menu/loadout pedestal.
	var pedestal_script = load("res://scripts/ui/hero_pedestal_view.gd")
	var pedestal := pedestal_script.new() as Control
	pedestal.size = Vector2(320.0, 340.0)
	pedestal.set("character_id", "shadow_hunter")
	root.add_child(pedestal)
	await process_frame
	await process_frame
	if not bool(pedestal.get("_model_preview_loaded")):
		_fail("The main-menu/loadout hero pedestal is still using only the old portrait.")
		return

	# The character-selection showcase must use the same live 3D model for Shadow Hunter.
	var selection_scene := load("res://scenes/characters/character_select_view.tscn") as PackedScene
	if selection_scene == null:
		_fail("Character selection scene could not be loaded.")
		return
	var selection := selection_scene.instantiate() as Control
	selection.set("is_initial_selection", true)
	root.add_child(selection)
	await process_frame
	await process_frame
	var selection_preview := selection.get("_model_preview") as Control
	if selection_preview == null or not selection_preview.visible:
		_fail("Character selection showcase did not display the generated Shadow Hunter model.")
		return

	print("CHARACTER RENDER INTEGRATION PASSED: visible mesh geometry, correctly aimed live camera, %d rendered pixels, all 10 runtime clips, combat scene, hero pedestal, and character-selection preview." % rendered_pixel_count")
	quit(0)

func _fail(message: String) -> void:
	push_error("CHARACTER RENDER INTEGRATION FAILED: " + message)
	quit(1)
