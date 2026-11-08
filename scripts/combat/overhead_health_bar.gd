class_name OverheadHealthBar
extends Node2D

# Overhead floating health bar directly above player / boss / elite character head.
# Archero 2 reference design: high-readability segmented bar with numerical HP readout.
# Color codes dynamically based on health percentage.

var bg_rect: ColorRect
var fill_rect: ColorRect
var hp_label: Label

var bar_width: float = 72.0
var bar_height: float = 8.0
var max_health: float = 120.0
var current_health: float = 120.0

func _init() -> void:
	z_index = 20

func _ready() -> void:
	_setup_nodes()

func _setup_nodes() -> void:
	# 1. Outer Dark Border
	bg_rect = ColorRect.new()
	bg_rect.color = Color(0.08, 0.08, 0.12, 0.88)
	bg_rect.size = Vector2(bar_width + 4.0, bar_height + 4.0)
	bg_rect.position = Vector2(-(bar_width + 4.0) * 0.5, -(bar_height + 4.0) * 0.5)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)
	
	# Subtle inner border line
	var inner_bg := ColorRect.new()
	inner_bg.color = Color(0.18, 0.18, 0.22, 0.9)
	inner_bg.size = Vector2(bar_width, bar_height)
	inner_bg.position = Vector2(2.0, 2.0)
	inner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.add_child(inner_bg)
	
	# 2. Dynamic Fill Rect
	fill_rect = ColorRect.new()
	fill_rect.color = Color(0.25, 0.88, 0.35, 1.0)
	fill_rect.size = Vector2(bar_width, bar_height)
	fill_rect.position = Vector2(2.0, 2.0)
	fill_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg_rect.add_child(fill_rect)
	
	# 3. Numerical HP Label
	hp_label = Label.new()
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 11)
	hp_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.95))
	hp_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	hp_label.add_theme_constant_override("shadow_offset_x", 1)
	hp_label.add_theme_constant_override("shadow_offset_y", 1)
	hp_label.size = Vector2(bar_width + 20.0, 16.0)
	hp_label.position = Vector2(-(bar_width + 20.0) * 0.5, -18.0)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hp_label)
	
	_update_display(false)

func set_health(current: float, max_val: float, animate: bool = true) -> void:
	max_health = maxf(1.0, max_val)
	current_health = clampf(current, 0.0, max_health)
	_update_display(animate)

func _update_display(animate: bool) -> void:
	if not fill_rect or not hp_label:
		return
		
	var ratio := clampf(current_health / max_health, 0.0, 1.0)
	var target_w := bar_width * ratio
	
	# Dynamic color coding: Green (> 50%) -> Amber (25-50%) -> Danger Red (< 25%)
	var target_col: Color
	if ratio > 0.5:
		target_col = Color(0.25, 0.88, 0.35, 1.0)
	elif ratio > 0.25:
		target_col = Color(0.95, 0.75, 0.15, 1.0)
	else:
		target_col = Color(1.0, 0.25, 0.25, 1.0)
		
	hp_label.text = "%d / %d" % [int(ceil(current_health)), int(ceil(max_health))]
	
	if animate:
		var tw := create_tween().set_parallel(true)
		tw.tween_property(fill_rect, "size:x", target_w, 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(fill_rect, "color", target_col, 0.15)
	else:
		fill_rect.size.x = target_w
		fill_rect.color = target_col
