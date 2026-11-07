extends SceneTree

func _init():
	var img = Image.load_from_file("C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/.user_uploaded/media_1793208091786_22057a89.jpg")
	if img:
		print("Dimensions: ", img.get_width(), "x", img.get_height())
		# Scan bottom area for brightest blue pixels
		var max_blue = 0.0
		var best_pos = Vector2i.ZERO
		for y in range(500, img.get_height()):
			for x in range(img.get_width()):
				var c = img.get_pixel(x, y)
				if c.b > 0.5 and c.b > c.r * 1.5:
					if c.b > max_blue:
						max_blue = c.b
						best_pos = Vector2i(x, y)
		print("Peak blue at: ", best_pos, " with val: ", max_blue)
	quit()
