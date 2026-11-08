extends SceneTree

func _init() -> void:
	print("Creating Dark Fantasy Theme with Enhanced Typography & Mobile Touch Scales...")
	var theme := Theme.new()
	
	# Global default font size (was 16 by default, now 20 for high readability)
	theme.default_font_size = 20
	theme.set_font_size("font_size", "Button", 22)
	theme.set_font_size("font_size", "Label", 20)
	theme.set_font_size("font_size", "LineEdit", 20)
	theme.set_font_size("font_size", "OptionButton", 20)
	theme.set_font_size("font_size", "ProgressBar", 18)
	
	# --- Button StyleBoxes with generous touch padding ---
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.12, 0.09, 0.17, 0.94)
	btn_normal.set_border_width_all(2)
	btn_normal.border_color = Color(0.82, 0.65, 0.28, 0.9)
	btn_normal.set_corner_radius_all(10)
	btn_normal.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	btn_normal.shadow_size = 5
	btn_normal.shadow_offset = Vector2(0, 3)
	btn_normal.content_margin_left = 20
	btn_normal.content_margin_right = 20
	btn_normal.content_margin_top = 12
	btn_normal.content_margin_bottom = 12
	
	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.20, 0.15, 0.28, 0.98)
	btn_hover.set_border_width_all(2)
	btn_hover.border_color = Color(1.0, 0.88, 0.45, 1.0)
	btn_hover.set_corner_radius_all(10)
	btn_hover.shadow_color = Color(0.7, 0.35, 1.0, 0.5) # Arcane violet glow
	btn_hover.shadow_size = 8
	btn_hover.shadow_offset = Vector2(0, 3)
	btn_hover.content_margin_left = 20
	btn_hover.content_margin_right = 20
	btn_hover.content_margin_top = 12
	btn_hover.content_margin_bottom = 12
	
	var btn_pressed := StyleBoxFlat.new()
	btn_pressed.bg_color = Color(0.28, 0.20, 0.38, 1.0)
	btn_pressed.set_border_width_all(2)
	btn_pressed.border_color = Color(1.0, 0.92, 0.6, 1.0)
	btn_pressed.set_corner_radius_all(10)
	btn_pressed.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	btn_pressed.shadow_size = 2
	btn_pressed.shadow_offset = Vector2(0, 1)
	btn_pressed.content_margin_left = 20
	btn_pressed.content_margin_right = 20
	btn_pressed.content_margin_top = 12
	btn_pressed.content_margin_bottom = 12
	
	var btn_disabled := StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.08, 0.07, 0.10, 0.68)
	btn_disabled.set_border_width_all(1)
	btn_disabled.border_color = Color(0.38, 0.35, 0.44, 0.45)
	btn_disabled.set_corner_radius_all(10)
	btn_disabled.content_margin_left = 20
	btn_disabled.content_margin_right = 20
	btn_disabled.content_margin_top = 12
	btn_disabled.content_margin_bottom = 12

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", btn_hover)
	
	theme.set_color("font_color", "Button", Color(0.96, 0.92, 1.0))
	theme.set_color("font_hover_color", "Button", Color(1.0, 0.95, 0.75))
	theme.set_color("font_pressed_color", "Button", Color(1.0, 0.88, 0.35))
	theme.set_color("font_disabled_color", "Button", Color(0.5, 0.48, 0.55))

	# --- PanelContainer StyleBox ---
	var panel_box := StyleBoxFlat.new()
	panel_box.bg_color = Color(0.08, 0.06, 0.12, 0.94)
	panel_box.set_border_width_all(2)
	panel_box.border_color = Color(0.72, 0.54, 0.22, 0.85) # Antique gold rim
	panel_box.set_corner_radius_all(12)
	panel_box.shadow_color = Color(0.0, 0.0, 0.0, 0.75)
	panel_box.shadow_size = 8
	panel_box.shadow_offset = Vector2(0, 4)
	panel_box.content_margin_left = 18
	panel_box.content_margin_right = 18
	panel_box.content_margin_top = 16
	panel_box.content_margin_bottom = 16
	theme.set_stylebox("panel", "PanelContainer", panel_box)
	theme.set_stylebox("panel", "Panel", panel_box)

	# --- ProgressBar StyleBoxes ---
	var pb_bg := StyleBoxFlat.new()
	pb_bg.bg_color = Color(0.06, 0.04, 0.08, 0.92)
	pb_bg.set_border_width_all(2)
	pb_bg.border_color = Color(0.68, 0.52, 0.22, 0.88)
	pb_bg.set_corner_radius_all(8)
	
	var pb_fill := StyleBoxFlat.new()
	pb_fill.bg_color = Color(0.85, 0.16, 0.26, 1.0)
	pb_fill.set_corner_radius_all(6)
	
	theme.set_stylebox("background", "ProgressBar", pb_bg)
	theme.set_stylebox("fill", "ProgressBar", pb_fill)

	# Save resource
	DirAccess.make_dir_absolute("res://assets/themes")
	ResourceSaver.save(theme, "res://assets/themes/dark_fantasy_theme.tres")
	print("Saved theme to res://assets/themes/dark_fantasy_theme.tres")
	quit(0)
