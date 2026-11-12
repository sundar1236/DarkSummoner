class_name XpPickup
extends Area2D

# Celestial soul crystal pickup that pops out of defeated monsters,
# hovers momentarily, and magnetizes into the Lone Hunter to grant run XP.

var value: float = 25.0
var is_magnetized: bool = false
var magnetize_delay: float = 0.28
var is_collected: bool = false
var velocity: Vector2 = Vector2.ZERO
var target_player: Node2D
var lifetime: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0
	col.shape = shape
	add_child(col)
	
	body_entered.connect(_on_body_entered)

func setup(p_val: float, start_pos: Vector2) -> void:
	value = p_val
	global_position = start_pos
	
	# Initial burst impulse
	var angle := randf() * TAU
	var pop_force := randf_range(70.0, 160.0)
	velocity = Vector2.RIGHT.rotated(angle) * pop_force
	magnetize_delay = 0.28

func _draw() -> void:
	# Draw glowing celestial soul crystal (diamond shape)
	var glow_col := Color(0.35, 0.85, 1.0, 0.85)
	var core_col := Color(0.9, 0.98, 1.0, 1.0)
	var inner_col := Color(0.2, 0.55, 1.0, 0.95)
	
	var pts := PackedVector2Array([
		Vector2(0, -11),
		Vector2(8, 0),
		Vector2(0, 11),
		Vector2(-8, 0)
	])
	
	# Outer soft aura
	draw_circle(Vector2.ZERO, 14.0, Color(0.2, 0.6, 1.0, 0.25))
	draw_arc(Vector2.ZERO, 10.0, 0.0, TAU, 16, glow_col, 1.5, true)
	
	# Diamond core
	draw_colored_polygon(pts, inner_col)
	draw_polyline(pts, glow_col, 1.5)
	draw_circle(Vector2(0, -2), 3.0, core_col)

func _physics_process(delta: float) -> void:
	lifetime += delta
	queue_redraw()
	
	if not is_magnetized:
		magnetize_delay -= delta
		if magnetize_delay <= 0.0:
			is_magnetized = true
	
	if not is_instance_valid(target_player):
		if not is_inside_tree() or get_tree() == null:
			return
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			target_player = p_nodes[0]
			
	if is_magnetized and is_instance_valid(target_player):
		var to_player := target_player.global_position - global_position
		var dist := to_player.length()
		
		# Accelerating magnet suction
		var magnet_speed := clampf(450.0 + (lifetime * 350.0), 450.0, 1100.0)
		velocity = velocity.move_toward(to_player.normalized() * magnet_speed, 2200.0 * delta)
		global_position += velocity * delta
		
		if dist < 26.0:
			_collect()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 340.0 * delta)
		global_position += velocity * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	set_deferred("monitoring", false)
	GameManager.add_run_xp(value)
	if AudioManager:
		AudioManager.play_sfx("coin_pickup", 0.1)
	queue_free()
