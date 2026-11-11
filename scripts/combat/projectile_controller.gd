class_name ProjectileController
extends Area2D

const ImpactSparkVFXClass = preload("res://scripts/combat/impact_spark_vfx.gd")
const MAX_ACTIVE_PROJECTILES: int = 64

# Unified projectile controller supporting player weapons, homing souls,
# chain discharges, pet fireballs, and enemy/boss projectiles.

@export var is_player_projectile: bool = true
var damage: float = 15.0
var is_crit: bool = false
var speed: float = 550.0
var direction: Vector2 = Vector2.RIGHT
var pierce_count: int = 1
var lifetime: float = 2.0
var is_homing: bool = false
var homing_turn_speed: float = 4.0
var has_burn: bool = false
var has_life_steal: bool = false

var sprite: Sprite2D
var timer: float = 0.0
var hit_target_ids: Dictionary = {}

static func can_spawn_projectile() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	return tree == null or tree.get_nodes_in_group("projectiles").size() < MAX_ACTIVE_PROJECTILES

func _ready() -> void:
	if not can_spawn_projectile():
		queue_free()
		return
	add_to_group("projectiles")
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
	_apply_collision_profile()
	
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	var col := CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _apply_collision_profile() -> void:
	if is_player_projectile:
		collision_layer = 4
		collision_mask = 2 | 16
	else:
		collision_layer = 8
		collision_mask = 1 | 16

func setup(p_damage: float, p_is_crit: bool, p_dir: Vector2, p_speed: float = 550.0, p_type: String = "slash", p_is_player: bool = true) -> void:
	damage = p_damage
	is_crit = p_is_crit
	direction = p_dir.normalized()
	speed = p_speed
	is_player_projectile = p_is_player
	_apply_collision_profile()
	
	if not sprite:
		sprite = Sprite2D.new()
		add_child(sprite)
		
	var tex_path := "res://assets/sprites/projectiles/proj_slash.png"
	match p_type:
		"slash":
			tex_path = "res://assets/sprites/projectiles/proj_slash.png"
		"lightning":
			tex_path = "res://assets/sprites/projectiles/proj_lightning.png"
			speed = 750.0
		"soul":
			tex_path = "res://assets/sprites/projectiles/proj_soul.png"
			is_homing = true
			speed = 420.0
		"fireball":
			tex_path = "res://assets/sprites/projectiles/proj_fireball.png"
			has_burn = true
			speed = 480.0
		"enemy":
			tex_path = "res://assets/sprites/projectiles/proj_enemy.png"
			is_player_projectile = false
			speed = 320.0
			
	_apply_collision_profile()
	sprite.texture = TextureLoader.get_texture(tex_path)
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
		
	# Homing behavior for soul projectiles
	if is_homing and is_player_projectile:
		var target := _find_nearest_enemy()
		if target:
			var target_dir := (target.global_position - global_position).normalized()
			direction = direction.slerp(target_dir, homing_turn_speed * delta).normalized()
			rotation = direction.angle()
			
	global_position += direction * speed * delta

func _is_valid_enemy_target(target: Node2D) -> bool:
	if not is_instance_valid(target):
		return false
	if "is_dead" in target and bool(target.get("is_dead")):
		return false
	if "hp" in target and float(target.get("hp")) <= 0.0:
		return false
	if "current_hp" in target and float(target.get("current_hp")) <= 0.0:
		return false
	return true

func _find_nearest_enemy() -> Node2D:
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = 600.0
	for e in enemies:
		if is_instance_valid(e) and e is Node2D:
			if ("is_dead" in e and e.is_dead) or ("hp" in e and e.hp <= 0.0):
				continue
			var d := global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func _on_body_entered(body: Node2D) -> void:
	_handle_hit(body)

func _on_area_entered(area: Area2D) -> void:
	_handle_hit(area.get_parent())

func _handle_hit(target: Node) -> void:
	if not is_instance_valid(target):
		return
		
	if is_player_projectile:
		if target is Node2D and target.has_method("take_damage"):
			if not _is_valid_enemy_target(target as Node2D):
				return
			var target_id := target.get_instance_id()
			if hit_target_ids.has(target_id):
				return
			hit_target_ids[target_id] = true
			target.take_damage(damage, is_crit)
			
			# Spawn impact spark
			if ImpactSparkVFXClass.can_spawn_spark():
				var spark = ImpactSparkVFXClass.new()
				var p_tint := Color(0.95, 0.75, 1.0)
				if sprite and sprite.texture:
					var path := sprite.texture.resource_path
					if "lightning" in path:
						p_tint = Color(0.4, 0.9, 1.0)
					elif "soul" in path:
						p_tint = Color(0.3, 1.0, 0.65)
					elif "fireball" in path:
						p_tint = Color(1.0, 0.6, 0.2)
				spark.setup(is_crit, global_position, -direction, p_tint)
				get_parent().add_child(spark)
			if has_burn and target.has_method("apply_burn"):
				target.apply_burn(6.0, 3)
			if has_life_steal:
				GameManager.heal_player(damage * 0.15)
				
			pierce_count -= 1
			if pierce_count <= 0:
				queue_free()
		elif target is TileMap or target is StaticBody2D:
			# Hit wall with spark
			if ImpactSparkVFXClass.can_spawn_spark():
				var spark = ImpactSparkVFXClass.new()
				spark.setup(false, global_position, -direction, Color(0.8, 0.8, 0.8))
				get_parent().add_child(spark)
			queue_free()
	else:
		# Enemy projectile hits player
		if target.has_method("take_player_damage"):
			target.take_player_damage(damage)
			if ImpactSparkVFXClass.can_spawn_spark():
				var spark = ImpactSparkVFXClass.new()
				spark.setup(false, global_position, -direction, Color(1.0, 0.3, 0.3))
				get_parent().add_child(spark)
			queue_free()
		elif target is TileMap or target is StaticBody2D:
			queue_free()
