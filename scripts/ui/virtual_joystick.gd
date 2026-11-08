class_name VirtualJoystick
extends Control

# Responsive Mobile Virtual Joystick for Abyssal Altar.
# Supports both:
# 1. Left Movement Stick: Electric-blue guide ring with directional chevrons.
# 2. Right Aim & Attack Stick: Crimson/amber targeting reticle ring with sword aim markers.
# Features full floating-touch support, smooth radial clamping, touch index isolation,
# and edge-release cancellation to prevent stuck states.

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
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_PAUSED:
		_reset_joystick()

func _update_default_pos() -> void:
	if is_aim_and_attack:
		default_rest_pos = Vector2(size.x * 0.5, size.y * 0.72)
	else:
		default_rest_pos = Vector2(size.x * 0.5, size.y * 0.76)
		
	if not is_pressed:
		base_center = default_rest_pos
		knob_offset = Vector2.ZERO

func _draw() -> void:
	var alpha_mult: float = 1.0 if is_pressed else 0.42
	var ring_radius := clamp_radius + 20.0
	
	# Determine color theme: Fiery Crimson/Gold for Aim & Attack, Electric Blue for Movement
	var rim_color := Color(1.0, 0.42, 0.15, 0.85 * alpha_mult) if is_aim_and_attack else Color(0.2, 0.65, 1.0, 0.85 * alpha_mult)
	var glow_color := Color(1.0, 0.75, 0.25, 0.45 * alpha_mult) if is_aim_and_attack else Color(0.4, 0.85, 1.0, 0.4 * alpha_mult)
	var inner_rim := Color(0.95, 0.35, 0.2, 0.35 * alpha_mult) if is_aim_and_attack else Color(0.18, 0.55, 0.95, 0.35 * alpha_mult)
	var knob_core := Color(0.95, 0.3, 0.15, 0.95 * alpha_mult) if is_aim_and_attack else Color(0.1, 0.48, 0.95, 0.95 * alpha_mult)
	var knob_mid := Color(1.0, 0.6, 0.2, 0.95 * alpha_mult) if is_aim_and_attack else Color(0.25, 0.72, 1.0, 0.95 * alpha_mult)
	var knob_hi := Color(1.0, 0.9, 0.45, 0.98 * alpha_mult) if is_aim_and_attack else Color(0.7, 0.92, 1.0, 0.98 * alpha_mult)
	
	# 1. Outer Dark Backdrop
	draw_circle(base_center, ring_radius, Color(0.04, 0.03, 0.08, 0.55 * alpha_mult))
	
	# 2. Glowing Outer Energy Rim
	draw_arc(base_center, ring_radius, 0.0, TAU, 48, rim_color, 3.0, true)
	draw_arc(base_center, ring_radius + 2.0, 0.0, TAU, 48, glow_color, 1.5, true)
	
	# 3. Inner Concentric Guide Ring
	draw_arc(base_center, ring_radius * 0.55, 0.0, TAU, 36, inner_rim, 1.5, true)
	
	# 4. 4 Directional Chevron / Reticle Indicators (N, S, E, W)
	for i in range(4):
		var angle := float(i) * (PI * 0.5)
		var dir := Vector2.RIGHT.rotated(angle)
		var tip := base_center + dir * (ring_radius + 4.0)
		var left_pt := base_center + dir * (ring_radius - 12.0) + dir.orthogonal() * 8.0
		var right_pt := base_center + dir * (ring_radius - 12.0) - dir.orthogonal() * 8.0
		
		var chevron := PackedVector2Array([tip, left_pt, right_pt])
		draw_colored_polygon(chevron, rim_color)
		draw_polyline(chevron, glow_color, 1.5)
		
	# Draw crosshair marks for aim & attack stick
	if is_aim_and_attack:
		draw_line(base_center + Vector2(-16, 0), base_center + Vector2(-6, 0), rim_color, 2.0)
		draw_line(base_center + Vector2(6, 0), base_center + Vector2(16, 0), rim_color, 2.0)
		draw_line(base_center + Vector2(0, -16), base_center + Vector2(0, -6), rim_color, 2.0)
		draw_line(base_center + Vector2(0, 6), base_center + Vector2(0, 16), rim_color, 2.0)
	
	# Base texture overlay if present
	if base_texture:
		var b_size := Vector2(ring_radius * 2.2, ring_radius * 2.2)
		draw_texture_rect(base_texture, Rect2(base_center - b_size * 0.5, b_size), false, Color(1.0, 1.0, 1.0, 0.30 * alpha_mult))

	# 5. Glowing Inner Knob
	var knob_pos := base_center + knob_offset
	var knob_r := 44.0
	
	# Outer shadow & rim
	draw_circle(knob_pos, knob_r + 4.0, Color(0.04, 0.05, 0.12, 0.85 * alpha_mult))
	draw_arc(knob_pos, knob_r + 4.0, 0.0, TAU, 36, inner_rim, 2.0, true)
	
	# Core gradient
	draw_circle(knob_pos, knob_r, knob_core)
	draw_circle(knob_pos, knob_r * 0.72, knob_mid)
	draw_circle(knob_pos, knob_r * 0.38, knob_hi)
	
	# Metallic rim highlight
	draw_arc(knob_pos, knob_r, 0.0, TAU, 36, Color(1.0, 1.0, 1.0, 0.90 * alpha_mult), 2.5, true)
	
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

func _unhandled_input(event: InputEvent) -> void:
	# Catch touch releases that end outside control boundary to prevent stuck joysticks
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_index:
		_reset_joystick()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT and touch_index == 0:
		_reset_joystick()

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
