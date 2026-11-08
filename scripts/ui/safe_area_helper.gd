class_name SafeAreaHelper
extends RefCounted

# Provides responsive Safe Area Insets for modern mobile displays (notches, hole-punches, home indicator pill).
# Uses DisplayServer.get_display_safe_area() when running on mobile, and enforces standard ergonomic margins on desktop.

static func get_safe_margins() -> Dictionary:
	var win_size := DisplayServer.window_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	
	var top := 0.0
	var bottom := 0.0
	var left := 0.0
	var right := 0.0
	
	# If running on device with actual hardware insets / cutouts
	if safe_area.size.x > 0 and safe_area.size.y > 0 and (safe_area.position.y > 0 or safe_area.size.y < win_size.y or safe_area.position.x > 0 or safe_area.size.x < win_size.x):
		var scale_y := 1280.0 / float(max(1, win_size.y))
		var scale_x := 720.0 / float(max(1, win_size.x))
		top = float(safe_area.position.y) * scale_y
		bottom = float(win_size.y - (safe_area.position.y + safe_area.size.y)) * scale_y
		left = float(safe_area.position.x) * scale_x
		right = float(win_size.x - (safe_area.position.x + safe_area.size.x)) * scale_x
		
	# Minimum ergonomic safe padding:
	# Top: 46px (ensures status bar / punch hole camera never overlaps top bar)
	# Bottom: 28px (ensures Android home pill gesture indicator never blocks bottom tabs)
	# Left & Right: 14px (ensures rounded phone screen corners don't clip side buttons)
	top = maxf(top, 46.0)
	bottom = maxf(bottom, 28.0)
	left = maxf(left, 14.0)
	right = maxf(right, 14.0)
	
	return {
		"top": top,
		"bottom": bottom,
		"left": left,
		"right": right
	}
