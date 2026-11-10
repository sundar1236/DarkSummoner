extends SceneTree

func _init() -> void:
	print("Refining Player Storm Reaper Sprite with neck seal...")
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_storm_reaper_full_1794126915350.jpg"
	var img = Image.new()
	if img.load(path) != OK: quit(1); return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	var is_bg = []
	for y in range(h):
		var row = []
		row.resize(w)
		row.fill(false)
		is_bg.append(row)
		
	# Seal the neck seam so flood fill cannot enter the cowl from below:
	# Neck is at y around 0.235 * h, between x = 0.44 * w and 0.56 * w
	var neck_y = int(0.235 * h)
	var is_blocked = []
	for y in range(h):
		var row = []
		row.resize(w)
		row.fill(false)
		is_blocked.append(row)
		
	for x in range(int(0.44 * w), int(0.56 * w)):
		is_blocked[neck_y][x] = true
		is_blocked[neck_y + 1][x] = true
		
	var queue = []
	for x in range(w):
		queue.append(Vector2i(x, 0))
		queue.append(Vector2i(x, h - 1))
	for y in range(h):
		queue.append(Vector2i(0, y))
		queue.append(Vector2i(w - 1, y))
		
	var head = 0
	while head < queue.size():
		var p: Vector2i = queue[head]
		head += 1
		if is_bg[p.y][p.x]: continue
		if is_blocked[p.y][p.x]: continue
		
		var c = img.get_pixel(p.x, p.y)
		var lum = maxf(c.r, maxf(c.g, c.b))
		if lum <= 0.025:
			is_bg[p.y][p.x] = true
			var neighbors = [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]
			for n in neighbors:
				if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h and not is_bg[n.y][n.x] and not is_blocked[n.y][n.x]:
					var nc = img.get_pixel(n.x, n.y)
					if maxf(nc.r, maxf(nc.g, nc.b)) <= 0.025:
						queue.append(n)
						
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var c = img.get_pixel(x, y)
				var lum = maxf(c.r, maxf(c.g, c.b))
				var is_edge = false
				var neighbors = [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1)]
				for n in neighbors:
					if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h or is_bg[n.y][n.x]:
						is_edge = true
						break
				if is_edge and lum < 0.12:
					var a = clampf(lum / 0.12, 0.1, 1.0)
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
					
	# Find bounds
	var min_x = w
	var min_y = h
	var max_x = 0
	var max_y = 0
	for y in range(h):
		for x in range(w):
			if img.get_pixel(x, y).a > 0.03:
				if x < min_x: min_x = x
				if x > max_x: max_x = x
				if y < min_y: min_y = y
				if y > max_y: max_y = y
				
	var crop_w = max_x - min_x + 1
	var crop_h = max_y - min_y + 1
	var cropped = img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
	
	var target_h = 300
	var target_w = int(float(crop_w) * (float(target_h) / float(crop_h)))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_storm_reaper.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_shadow_hunter.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_base.png")
	print("Sealed Player Storm Reaper: ", target_w, "x", target_h)
	quit(0)
