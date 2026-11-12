class_name CoinPickup
extends Area2D

# Tactile gold coin pickup that pops out upon enemy defeat, settles briefly,
# and smoothly magnetizes towards the player.

var value: int = 1
var is_magnetized: bool = false
var magnetize_delay: float = 0.35
var is_collected: bool = false
var velocity: Vector2 = Vector2.ZERO
var target_player: Node2D
var sprite: Sprite2D
var lifetime: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	
	sprite = Sprite2D.new()
	sprite.texture = TextureLoader.get_texture("res://assets/sprites/ui/icon_gold.png")
	sprite.scale = Vector2(0.9, 0.9)
	add_child(sprite)
	
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	col.shape = shape
	add_child(col)
	
	body_entered.connect(_on_body_entered)

func setup(p_val: int, start_pos: Vector2) -> void:
	value = p_val
	global_position = start_pos
	
	# Initial bounce pop out
	var angle := randf() * TAU
	var pop_force := randf_range(60.0, 140.0)
	velocity = Vector2.RIGHT.rotated(angle) * pop_force
	magnetize_delay = 0.35

func _physics_process(delta: float) -> void:
	lifetime += delta
	if not is_magnetized:
		magnetize_delay -= delta
		if magnetize_delay <= 0.0:
			is_magnetized = true
	if not is_instance_valid(target_player):
		var p_nodes := get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			target_player = p_nodes[0]
			
	if is_magnetized and is_instance_valid(target_player):
		var to_player := target_player.global_position - global_position
		var dist := to_player.length()
		
		# Magnet suction acceleration
		var magnet_speed := clampf(400.0 + (lifetime * 300.0), 400.0, 950.0)
		velocity = velocity.move_toward(to_player.normalized() * magnet_speed, 1800.0 * delta)
		global_position += velocity * delta
		
		# Proximity collect
		if dist < 24.0:
			_collect()
	else:
		# Slow down initial bounce
		velocity = velocity.move_toward(Vector2.ZERO, 300.0 * delta)
		global_position += velocity * delta
		
		# Gentle bobbing
		if sprite:
			sprite.position.y = sin(lifetime * 6.0) * 2.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_collect()

func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	set_deferred("monitoring", false)
	GameManager.add_gold(value)
	if AudioManager:
		AudioManager.play_sfx("coin_pickup", 0.05)
	
	# Visual pop collect
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.08)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.08)
	tw.tween_callback(queue_free)
