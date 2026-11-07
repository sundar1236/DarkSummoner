class_name TextureLoader
extends RefCounted

# Universal robust texture loader.
# Loads textures using either ResourceLoader or direct Image decoding,
# guaranteeing instant, reliable asset loading with zero external importer dependencies.

static var _cache: Dictionary = {}

static func get_texture(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
		
	# 1. Try standard Godot loader if imported
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			_cache[path] = res
			return res
			
	# 2. Fallback to direct file loading via Image
	var global_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var img := Image.new()
		var err := img.load(global_path)
		if err == OK:
			var tex := ImageTexture.create_from_image(img)
			_cache[path] = tex
			return tex
			
	push_warning("Failed to load texture at path: " + path)
	return null
