extends SceneTree

func _init() -> void:
	print("Starting Batch Combat Sprite Conversion...")
	
	# 1. Process Storm Reaper (Player)
	_process_player()
	
	# 2. Process Abyssal Swarmer (Spider)
	_process_swarmer()
	
	# 3. Process Cultist Wraith
	_process_cultist()
	
	# 4. Process Demonic Elite Brute (White BG)
	_process_elite()
	
	# 5. Process Slash VFX (Black BG, Additive Alpha)
	_process_slash()
	
	print("ALL COMBAT SPRITES CONVERTED SUCCESSFULLY!")
	quit(0)

func _process_player() -> void:
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_storm_reaper_full_1794126915350.jpg"
	var img = Image.new()
	if img.load(path) != OK: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Flood fill only outer black background
	var is_bg = _flood_fill_outer(img, 0.02)
	
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				# Soft edge
				var c = img.get_pixel(x, y)
				var lum = maxf(c.r, maxf(c.g, c.b))
				var is_edge = _is_neighbor_bg(is_bg, x, y, w, h)
				if is_edge and lum < 0.12:
					var a = clampf(lum / 0.12, 0.1, 1.0)
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
					
	var cropped = _crop_alpha(img)
	var target_h = 300
	var target_w = int(float(cropped.get_width()) * (float(target_h) / float(cropped.get_height())))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_storm_reaper.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_shadow_hunter.png")
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/characters/player_base.png")
	print("  -> Player Storm Reaper: ", target_w, "x", target_h)

func _process_swarmer() -> void:
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_swarmer_hd_1794126928797.jpg"
	var img = Image.new()
	if img.load(path) != OK: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	var is_bg = _flood_fill_outer(img, 0.025)
	
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var c = img.get_pixel(x, y)
				var lum = maxf(c.r, maxf(c.g, c.b))
				if _is_neighbor_bg(is_bg, x, y, w, h) and lum < 0.12:
					var a = clampf(lum / 0.12, 0.1, 1.0)
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
					
	var cropped = _crop_alpha(img)
	var target_w = 200
	var target_h = int(float(cropped.get_height()) * (float(target_w) / float(cropped.get_width())))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/enemies/enemy_swarmer.png")
	print("  -> Enemy Swarmer: ", target_w, "x", target_h)

func _process_cultist() -> void:
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_cultist_hd_1794126949880.jpg"
	var img = Image.new()
	if img.load(path) != OK: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	var is_bg = _flood_fill_outer(img, 0.025)
	
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var c = img.get_pixel(x, y)
				var lum = maxf(c.r, maxf(c.g, c.b))
				if _is_neighbor_bg(is_bg, x, y, w, h) and lum < 0.12:
					var a = clampf(lum / 0.12, 0.1, 1.0)
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
					
	var cropped = _crop_alpha(img)
	var target_h = 240
	var target_w = int(float(cropped.get_width()) * (float(target_h) / float(cropped.get_height())))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/enemies/enemy_cultist.png")
	print("  -> Enemy Cultist: ", target_w, "x", target_h)

func _process_elite() -> void:
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_elite_hd_v2_1794127004530.jpg"
	var img = Image.new()
	if img.load(path) != OK: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Key out WHITE background (lum > 0.94)
	var is_bg = []
	for y in range(h):
		var row = []
		row.resize(w)
		row.fill(false)
		is_bg.append(row)
		
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
		var c = img.get_pixel(p.x, p.y)
		var min_c = minf(c.r, minf(c.g, c.b))
		if min_c >= 0.94:
			is_bg[p.y][p.x] = true
			var neighbors = [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]
			for n in neighbors:
				if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h and not is_bg[n.y][n.x]:
					var nc = img.get_pixel(n.x, n.y)
					if minf(nc.r, minf(nc.g, nc.b)) >= 0.94:
						queue.append(n)
						
	for y in range(h):
		for x in range(w):
			if is_bg[y][x]:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var c = img.get_pixel(x, y)
				var min_c = minf(c.r, minf(c.g, c.b))
				if _is_neighbor_bg(is_bg, x, y, w, h) and min_c > 0.82:
					var a = clampf((1.0 - min_c) / 0.18, 0.1, 1.0)
					img.set_pixel(x, y, Color(c.r, c.g, c.b, a))
					
	var cropped = _crop_alpha(img)
	var target_h = 280
	var target_w = int(float(cropped.get_width()) * (float(target_h) / float(cropped.get_height())))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/enemies/enemy_elite.png")
	print("  -> Enemy Elite Brute: ", target_w, "x", target_h)

func _process_slash() -> void:
	var path = "C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/art_slash_hd_1794127031604.jpg"
	var img = Image.new()
	if img.load(path) != OK: return
	img.convert(Image.FORMAT_RGBA8)
	var w = img.get_width()
	var h = img.get_height()
	
	# Additive alpha for glowing energy slash
	for y in range(h):
		for x in range(w):
			var c = img.get_pixel(x, y)
			var lum = maxf(c.r, maxf(c.g, c.b))
			if lum < 0.04:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
			else:
				var a = clampf((lum - 0.04) * 2.2, 0.0, 1.0)
				# Retain bright vibrant purple / white core
				var mult = 1.0 / maxf(a, 0.1)
				var r = clampf(c.r * mult, 0.0, 1.0)
				var g = clampf(c.g * mult, 0.0, 1.0)
				var b = clampf(c.b * mult, 0.0, 1.0)
				img.set_pixel(x, y, Color(r, g, b, a))
				
	var cropped = _crop_alpha(img)
	var target_w = 200
	var target_h = int(float(cropped.get_height()) * (float(target_w) / float(cropped.get_width())))
	cropped.resize(target_w, target_h, Image.INTERPOLATE_LANCZOS)
	cropped.save_png("d:/work drive/AbyssalAltar/assets/sprites/projectiles/proj_slash.png")
	print("  -> Slash VFX: ", target_w, "x", target_h)

func _flood_fill_outer(img: Image, max_lum: float) -> Array:
	var w = img.get_width()
	var h = img.get_height()
	var is_bg = []
	for y in range(h):
		var row = []
		row.resize(w)
		row.fill(false)
		is_bg.append(row)
		
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
		var c = img.get_pixel(p.x, p.y)
		var lum = maxf(c.r, maxf(c.g, c.b))
		if lum <= max_lum:
			is_bg[p.y][p.x] = true
			var neighbors = [Vector2i(p.x + 1, p.y), Vector2i(p.x - 1, p.y), Vector2i(p.x, p.y + 1), Vector2i(p.x, p.y - 1)]
			for n in neighbors:
				if n.x >= 0 and n.x < w and n.y >= 0 and n.y < h and not is_bg[n.y][n.x]:
					var nc = img.get_pixel(n.x, n.y)
					if maxf(nc.r, maxf(nc.g, nc.b)) <= max_lum:
						queue.append(n)
	return is_bg

func _is_neighbor_bg(is_bg: Array, x: int, y: int, w: int, h: int) -> bool:
	var neighbors = [Vector2i(x + 1, y), Vector2i(x - 1, y), Vector2i(x, y + 1), Vector2i(x, y - 1)]
	for n in neighbors:
		if n.x < 0 or n.x >= w or n.y < 0 or n.y >= h or is_bg[n.y][n.x]:
			return true
	return false

func _crop_alpha(img: Image) -> Image:
	var w = img.get_width()
	var h = img.get_height()
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
	if min_x > max_x: return img
	var crop_w = max_x - min_x + 1
	var crop_h = max_y - min_y + 1
	return img.get_region(Rect2i(min_x, min_y, crop_w, crop_h))
