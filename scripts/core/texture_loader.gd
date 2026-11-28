class_name TextureLoader
extends RefCounted

# Universal robust texture loader.
# Loads textures using either ResourceLoader or direct Image decoding,
# guaranteeing instant, reliable asset loading with zero external importer dependencies.

static var _cache: Dictionary = {}

static func get_texture(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
		
	# 1. On desktop/editor, direct OS file loading avoids stale imported cache;
	# on mobile/web (.pck), skip raw OS file load so ResourceLoader handles packed assets cleanly.
	var global_path := ProjectSettings.globalize_path(path)
	if not OS.has_feature("android") and not OS.has_feature("web") and not global_path.begins_with("res://") and FileAccess.file_exists(global_path):
		var img := Image.new()
		var err := img.load(global_path)
		if err == OK:
			var tex := ImageTexture.create_from_image(img)
			_cache[path] = tex
			return tex

	# 2. Fallback to standard Godot ResourceLoader
	if ResourceLoader.exists(path):
		var res := ResourceLoader.load(path)
		if res is Texture2D:
			_cache[path] = res
			return res
			
	push_warning("Failed to load texture at path: " + path)
	return null
