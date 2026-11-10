extends SceneTree

func _init() -> void:
	print("Converting Ritual Sword Icon to transparent PNG...")
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/icon_ritual_sword_1794144349333.jpg"
	var img = Image.new()
	if img.load(path) != OK:
		print("Failed to load: ", path)
		quit(1)
		return
		
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Key out black background, keeping glowing embers and sword intact
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			var lum = maxf(c.r, maxf(c.g, c.b))
			if lum < 0.03:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			elif lum < 0.15:
				var a = clampf((lum - 0.03) / 0.12, 0.0, 1.0)
				var mult = 1.0 / maxf(a, 0.1)
				img.set_pixel(x, y, Color(clampf(c.r * mult, 0.0, 1.0), clampf(c.g * mult, 0.0, 1.0), clampf(c.b * mult, 0.0, 1.0), a))
				
	# Crop bounding box with 10px margin
	var min_x = w; var min_y = h; var max_x = 0; var max_y = 0
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.05:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y
				
	var crop_x = maxi(0, min_x - 12)
	var crop_y = maxi(0, min_y - 12)
	var crop_w = mini(w - crop_x, (max_x - min_x + 1) + 24)
	var crop_h = mini(h - crop_y, (max_y - min_y + 1) + 24)
	
	var cropped = img.get_region(Rect2i(crop_x, crop_y, crop_w, crop_h))
	
	# Resize to clean square / rectangular icon resolution (e.g. 160x160 or proportional)
	var target_h = 160
	var target_w = int(float(crop_w) * (float(target_h) / float(crop_h)))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	
	var out_path = "d:/work drive/AbyssalAltar/assets/art/items/icon_ritual_sword.png"
	cropped.save_png(out_path)
	print("Saved transparent ritual sword icon to: ", out_path, " (", target_w, "x", target_h, ")")
	quit(0)
