extends SceneTree

func _init() -> void:
	var img = Image.new()
	var err = img.load("C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/reference_characters_screen.jpg")
	if err != OK:
		quit(1)
		return
	
	# Full Footer with full labels
	var r_footer = Rect2i(0, 860, 687, 130)
	var sub_footer = img.get_region(r_footer)
	sub_footer.save_png("d:/work drive/AbyssalAltar/assets/art/ui_reference/footer_dock_full.png")
	
	# Also let's extract the full screen background (everything behind the hero and UI)
	# or the stone floor texture:
	var r_floor = Rect2i(0, 520, 687, 345)
	var sub_floor = img.get_region(r_floor)
	sub_floor.save_png("d:/work drive/AbyssalAltar/assets/art/ui_reference/stone_dungeon_floor.png")
	
	# Avatar circle graphic:
	var r_avatar = Rect2i(23, 45, 68, 68)
	var sub_avatar = img.get_region(r_avatar)
	sub_avatar.save_png("d:/work drive/AbyssalAltar/assets/art/ui_reference/avatar_circle_frame.png")
	
	print("Updated slices!")
	quit(0)
