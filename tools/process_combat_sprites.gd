extends SceneTree

# Uses edge flood-fill to remove only the exterior black background, preserving interior shadows!
func _init() -> void:
	print("Edge Flood-fill keying...")
	var src_path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_storm_reaper_full_1794126915350.jpg"
	var img = Image.new()
	var err = img.load(src_path)
	if err != OK:
		print("ERROR loading: ", src_path)
		quit(1)
		return
		
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Visited 2D array
	var is_bg = []
	for y in range(h):
		var row = []
		row.resize(w)
		row.fill(false)
		is_bg.append(row)
		
	var queue = []
	
	# Push all borders
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(h):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
		
	# Flood fill outward dark background
	var head = 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		
		if is_bg[p.y][p.x]:
			continue
			
		var c = img.get_pixel(p.x, p.y)
		var lum = maxf(c.r, maxf(c.g, c.b))
		
		# If it's dark background
		if lum <= 0.05:
			is_bg[p.y][p.x] = true
			
			# Check 4 neighbors
			var neighbors = [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]
			for n in neighbors:
				if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h:
					if not is_bg[n.y][n.x]:
						var nc = img.get_pixel(n.x, n.y)
						var nlum = maxf(nc.r, maxf(nc.g, nc.b))
						if nlum <= 0.06:
							queue.append(n)
							
	# Apply transparency to bg and feather 2px boundary
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				# Check if neighbor is bg
				var has_bg_neighbor = false
				var neighbors = [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1)]
				for n in neighbors:
					if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h or is_bg[n.y][n.x]:
						has_bg_neighbor = true
						break
				if has_bg_neighbor:
					var c = img.get_pixel(x, y)
					var lum = maxf(c.r, maxf(c.g, c.b))
					if lum < 0.15:
						var a = clampf(lum / 0.15, 0.2, 1.0)
						img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
						
	# Crop bounding box
	var min_x = w
	var min_y = h
	var max_x = 0
	var max_y = 0
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.05:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y
				
	var crop_w = max_x - min_x + 1
	var crop_h = max_y - min_y + 1
	var cropped = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	
	var target_h = 320
	var target_w = int(float(crop_w) * (float(target_h) / float(crop_h)))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_storm_reaper.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_shadow_hunter.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_base.png")
	print("Flood-fill keying completed successfully! Size: ", target_w, "x", target_h)
	quit(0)
