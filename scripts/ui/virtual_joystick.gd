class_name VirtualJoystick
extends Control

# Responsive Archero 2-style Single Movement Virtual Joystick.
# Features full touch-zone floating support, electric-blue outer guide ring
# with 4 directional arrows, large glowing thumb knob, and smooth radial clamping.

signal joystick_updated(output: Vector2)
signal joystick_pressed()
signal joystick_released()

@export var is_aim_and_attack: bool = false
@export var is_floating: bool = true
@export var clamp_radius: float = 85.0

var touch_index: int = -1
var output_vector: Vector2 = Vector2.ZERO
var is_pressed: bool = false

var base_texture: Texture2D
var knob_texture: Texture2D

var base_center: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO
var default_rest_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	base_texture = TextureLoader.get_texture("res://assets/sprites/ui/joystick_base.png")
	knob_texture = TextureLoader.get_texture("res://assets/sprites/ui/joystick_knob.png")
	mouse_filter = MOUSE_FILTER_PASS
	_update_default_pos()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_update_default_pos()

func _update_default_pos() -> void:
	default_rest_pos = Vector2(size.x * 0.5, size.y * 0.76)
	if not is_pressed:
		base_center = default_rest_pos
		knob_offset = Vector2.ZERO

func _draw() -> void:
	var alpha_mult: float = 1.0 if is_pressed else 0.45
	var ring_radius := clamp_radius + 20.0
	
	# 1. Outer Dark Backdrop
	draw_circle(base_center, ring_radius, Color(0.02, 0.05, 0.12, 0.55 * alpha_mult))
	
	# 2. Glowing Electric-Blue Outer Energy Rim
	draw_arc(base_center, ring_radius, 0.0, TAU, 48, Color(0.2, 0.65, 1.0, 0.85 * alpha_mult), 3.0, true)
	draw_arc(base_center, ring_radius + 2.0, 0.0, TAU, 48, Color(0.4, 0.85, 1.0, 0.4 * alpha_mult), 1.5, true)
	
	# 3. Inner Concentric Guide Ring
	draw_arc(base_center, ring_radius * 0.55, 0.0, TAU, 36, Color(0.18, 0.55, 0.95, 0.35 * alpha_mult), 1.5, true)
	
	# 4. 4 Directional Chevron / Arrow Indicators (N, S, E, W)
	for i in range(4):
		var angle := float(i) * (PI * 0.5)
		var dir := Vector2.RIGHT.rotated(angle)
		var tip := base_center + dir * (ring_radius + 4.0)
		var left_pt := base_center + dir * (ring_radius - 12.0) + dir.orthogonal() * 8.0
		var right_pt := base_center + dir * (ring_radius - 12.0) - dir.orthogonal() * 8.0
		
		var chevron := PackedVector2Array([tip, left_pt, right_pt])
		draw_colored_polygon(chevron, Color(0.3, 0.8, 1.0, 0.9 * alpha_mult))
		draw_polyline(chevron, Color(0.7, 0.95, 1.0, 0.95 * alpha_mult), 1.5)
	
	# Base texture overlay if present
	if base_texture:
		var b_size := Vector2(ring_radius * 2.2, ring_radius * 2.2)
		draw_texture_rect(base_texture, Rect2(base_center - b_size * 0.5, b_size), false, Color(0.6, 0.85, 1.0, 0.35 * alpha_mult))

	# 5. Large Glowing Electric-Blue Inner Knob
	var knob_pos := base_center + knob_offset
	var knob_r := 44.0
	
	# Outer shadow & rim
	draw_circle(knob_pos, knob_r + 4.0, Color(0.04, 0.08, 0.16, 0.85 * alpha_mult))
	draw_arc(knob_pos, knob_r + 4.0, 0.0, TAU, 36, Color(0.15, 0.45, 0.85, 0.7 * alpha_mult), 2.0, true)
	
	# Vibrant core gradient
	draw_circle(knob_pos, knob_r, Color(0.1, 0.48, 0.95, 0.95 * alpha_mult))
	draw_circle(knob_pos, knob_r * 0.72, Color(0.25, 0.72, 1.0, 0.95 * alpha_mult))
	draw_circle(knob_pos, knob_r * 0.38, Color(0.7, 0.92, 1.0, 0.98 * alpha_mult))
	
	# Metallic rim highlight
	draw_arc(knob_pos, knob_r, 0.0, TAU, 36, Color(0.85, 0.96, 1.0, 0.95 * alpha_mult), 2.5, true)
	
	# Top specular shine
	draw_circle(knob_pos + Vector2(-knob_r * 0.28, -knob_r * 0.28), knob_r * 0.22, Color(1.0, 1.0, 1.0, 0.85 * alpha_mult))
	
	if knob_texture:
		var k_size := Vector2(knob_r * 2.0, knob_r * 2.0)
		draw_texture_rect(knob_texture, Rect2(knob_pos - k_size * 0.5, k_size), false, Color(1.0, 1.0, 1.0, 0.85 * alpha_mult))

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			touch_index = event.index
			is_pressed = true
			if is_floating:
				base_center = event.position
				knob_offset = Vector2.ZERO
				output_vector = Vector2.ZERO
			else:
				_handle_touch_position(event.position)
			joystick_pressed.emit()
			queue_redraw()
		elif not event.pressed and event.index == touch_index:
			_reset_joystick()
			
	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			_handle_touch_position(event.position)
			
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and touch_index == -1:
				touch_index = 0
				is_pressed = true
				if is_floating:
					base_center = event.position
					knob_offset = Vector2.ZERO
					output_vector = Vector2.ZERO
				else:
					_handle_touch_position(event.position)
				joystick_pressed.emit()
				queue_redraw()
			elif not event.pressed and touch_index == 0:
				_reset_joystick()
				
	elif event is InputEventMouseMotion:
		if touch_index == 0:
			_handle_touch_position(event.position)

func _handle_touch_position(pos: Vector2) -> void:
	var diff := pos - base_center
	var dist := diff.length()
	
	if dist > clamp_radius:
		knob_offset = diff.normalized() * clamp_radius
	else:
		knob_offset = diff
		
	var raw_output := knob_offset / clamp_radius
	if raw_output.length() < 0.08:
		output_vector = Vector2.ZERO
	else:
		output_vector = raw_output
		
	joystick_updated.emit(output_vector)
	queue_redraw()

func _reset_joystick() -> void:
	touch_index = -1
	is_pressed = false
	knob_offset = Vector2.ZERO
	output_vector = Vector2.ZERO
	if is_floating:
		base_center = default_rest_pos
	joystick_updated.emit(Vector2.ZERO)
	joystick_released.emit()
	queue_redraw()

func get_effective_movement() -> Vector2:
	if output_vector.length_squared() > 0.01:
		return output_vector
		
	# Fallback desktop keyboard controls for PC debugging
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP): dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN): dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT): dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1.0
	return dir.normalized()
