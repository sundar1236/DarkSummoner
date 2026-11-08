extends SceneTree

func _init() -> void:
	var img = Image.new()
	var err = img.load("C:/Users/sundh/.gemini/antigravity/brain/5b758a00-9f80-43f6-953c-dbc11af02afb/reference_characters_screen.jpg")
	print("Load err: ", err, " Dimensions: ", img.get_size())
	quit(0)
