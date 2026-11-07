extends SceneTree

func _init() -> void:
	print("Capture script initialized")
	var root_node = root
	# Wait for a frame
	await process_frame
	await process_frame
	print("Taking screenshot...")
	var img = root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("res://screenshot_test.png")
		print("Screenshot saved to screenshot_test.png, size: ", img.get_size())
	quit()
