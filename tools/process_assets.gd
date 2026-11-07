extends SceneTree

# Image Processor & Alpha Feathering for Abyssal Altar assets

func _init() -> void:
	print("Processing assets...")
	_make_logo_transparent("res://assets/art/ui/abyssal_altar_logo.png")
	_feather_character_portrait("res://assets/art/characters/shadow_hunter_portrait.png")
	_feather_character_portrait("res://assets/art/characters/storm_reaper_portrait.png")
	_feather_character_portrait("res://assets/art/characters/soul_binder_portrait.png")
	_generate_gothic_frame("res://assets/art/ui/card_gothic_frame.png")
	print("Asset processing completed successfully!")
	quit(0)

func _make_logo_transparent(path: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if not img:
		print("Failed to load: ", path)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	
	for y in range(h):
		for x in range(w):
			var col := img.get_pixel(x, y)
			var max_c: float = maxf(col.r, maxf(col.g, col.b))
			if max_c <= 0.07:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif max_c < 0.28:
				var alpha: float = (max_c - 0.07) / (0.28 - 0.07)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
				
	img.save_png(ProjectSettings.globalize_path(path))
	print("Saved transparent logo: ", path)

func _feather_character_portrait(path: String) -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if not img:
		print("Failed to load: ", path)
		return
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var margin_x := int(w * 0.08)
	var margin_y := int(h * 0.08)
	
	for y in range(h):
		for x in range(w):
			var col := img.get_pixel(x, y)
			# Calculate distance from border
			var dist_x: float = minf(float(x), float(w - 1 - x)) / float(margin_x)
			var dist_y: float = minf(float(y), float(h - 1 - y)) / float(margin_y)
			var edge_factor: float = clampf(minf(dist_x, dist_y), 0.0, 1.0)
			# Quadratic smooth fade
			var alpha: float = col.a * (edge_factor * edge_factor)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))
			
	img.save_png(ProjectSettings.globalize_path(path))
	print("Saved feathered portrait: ", path)

func _generate_gothic_frame(path: String) -> void:
	# 9-patch style gothic frame (128x128 with 16px borders)
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var col_slate := Color(0.1, 0.08, 0.14, 0.92)
	var col_gold := Color(0.85, 0.68, 0.28, 1.0)
	var col_gold_dim := Color(0.5, 0.38, 0.18, 0.9)
	var col_inner := Color(0.18, 0.14, 0.24, 0.7)
	
	for y in range(size):
		for x in range(size):
			var dist_border: int = mini(mini(x, size - 1 - x), mini(y, size - 1 - y))
			if dist_border < 2:
				img.set_pixel(x, y, col_gold) # Outer gold edge
			elif dist_border < 4:
				img.set_pixel(x, y, col_gold_dim) # Bevel
			elif dist_border < 8:
				img.set_pixel(x, y, col_inner) # Inner frame rim
			else:
				img.set_pixel(x, y, col_slate) # Slate interior
				
	# Ornamental corner notches
	for i in range(12):
		for j in range(12):
			if (i + j) <= 10:
				var corners := [Vector2i(i, j), Vector2i(size - 1 - i, j), Vector2i(i, size - 1 - j), Vector2i(size - 1 - i, size - 1 - j)]
				for pt in corners:
					img.set_pixel(pt.x, pt.y, col_gold)
					
	img.save_png(ProjectSettings.globalize_path(path))
	print("Saved gothic frame: ", path)
