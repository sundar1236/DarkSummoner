extends SceneTree

func _init() -> void:
	print("Slicing item icons and story scenes...")
	_slice_items()
	_slice_story_scenes()
	print("Asset slicing complete!")
	quit(0)

func _slice_items() -> void:
	var path := "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/item_icons_sheet_clean_1793126475886.jpg"
	var img := Image.load_from_file(path)
	if not img:
		print("Failed to load item sheet from ", path)
		return
	img.convert(Image.FORMAT_RGBA8)
	
	var item_names := [
		"shadow_dagger", "shadow_blade", "abyssal_scythe", "fire_rune",
		"inferno_rune", "wolf_core", "demon_core", "iron_shield",
		"void_shield", "lightning_orb", "soul_urn", "blood_chalice"
	]
	
	var cell_w := int(img.get_width() / 4.0)
	var cell_h := int(img.get_height() / 3.0)
	
	for idx in range(item_names.size()):
		var col := idx % 4
		var row := int(idx / 4)
		var x := col * cell_w
		var y := row * cell_h
		
		# Crop cell
		var cell_img := img.get_region(Rect2i(x + 10, y + 10, cell_w - 20, cell_h - 20))
		cell_img.resize(128, 128, Image.INTERPOLATE_LANCZOS)
		
		# Alpha key black background
		for cy in range(128):
			for cx in range(128):
				var px := cell_img.get_pixel(cx, cy)
				var v: float = maxf(px.r, maxf(px.g, px.b))
				if v <= 0.08:
					cell_img.set_pixel(cx, cy, Color(0, 0, 0, 0))
				elif v < 0.25:
					var a: float = (v - 0.08) / (0.25 - 0.08)
					cell_img.set_pixel(cx, cy, Color(px.r, px.g, px.b, a))
					
		var out_path := "res://assets/art/items/item_%s.png" % item_names[idx]
		cell_img.save_png(ProjectSettings.globalize_path(out_path))
		print("Saved: ", out_path)

func _slice_story_scenes() -> void:
	var path := "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/intro_story_scenes_1793126447211.jpg"
	var img := Image.load_from_file(path)
	if not img:
		print("Failed to load story sheet from ", path)
		return
	img.convert(Image.FORMAT_RGBA8)
	
	var scene_names := [
		"story_scene_1_tower", "story_scene_2_altar",
		"story_scene_3_malakar", "story_scene_4_hunter"
	]
	
	var half_w := int(img.get_width() / 2.0)
	var half_h := int(img.get_height() / 2.0)
	
	for idx in range(scene_names.size()):
		var col := idx % 2
		var row := int(idx / 2)
		var x := col * half_w
		var y := row * half_h
		
		var scene_img := img.get_region(Rect2i(x, y, half_w, half_h))
		var out_path := "res://assets/art/story/%s.png" % scene_names[idx]
		scene_img.save_png(ProjectSettings.globalize_path(out_path))
		print("Saved story scene: ", out_path)
