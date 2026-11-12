class_name PetController
extends Node2D

# Autonomous Pet/Summon companion.
# Orbits the player, auto-acquires targets, and fires attacks automatically.

@export var pet_type: String = "wolf" # "wolf", "hellhound", "demon"
var damage: float = 12.0
var attack_cooldown: float = 1.3
var attack_range: float = 380.0
var target_offset: Vector2 = Vector2(-45, -30)

var attack_timer: float = 0.0
var player_ref: Node2D
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("pets")
	sprite = Sprite2D.new()
	add_child(sprite)
	_update_appearance()

func setup(p_type: String, p_damage: float, p_player: Node2D) -> void:
	pet_type = p_type
	damage = p_damage
	player_ref = p_player
	_update_appearance()

func _update_appearance() -> void:
	if not sprite:
		return
	var tex_path := "res://assets/sprites/pets/pet_wolf.png"
	if pet_type == "hellhound":
		tex_path = "res://assets/sprites/pets/pet_hellhound.png"
		attack_cooldown = 1.1
		damage = 24.0
	elif pet_type == "demon":
		tex_path = "res://assets/sprites/pets/pet_hellhound.png"
		attack_cooldown = 1.2
		damage = 18.0
	sprite.texture = TextureLoader.get_texture(tex_path)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return
		
	# Smoothly follow player with floating bob
	var t: float = Time.get_ticks_msec() / 1000.0
	var bob := Vector2(cos(t * 2.5) * 8.0, sin(t * 3.0) * 8.0)
	var desired_pos := player_ref.global_position + target_offset + bob
	global_position = global_position.lerp(desired_pos, 8.0 * delta)
	
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		var target := _find_nearest_enemy()
		if target:
			_attack_target(target)
			attack_timer = 0.0

func _find_nearest_enemy() -> Node2D:
	if not is_inside_tree() or get_tree() == null:
		return null
	var enemies := get_tree().get_nodes_in_group("enemies")
	var nearest: Node2D = null
	var min_dist: float = attack_range
	for e in enemies:
		if is_instance_valid(e) and e is Node2D:
			var d := global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				nearest = e
	return nearest

func _attack_target(target: Node2D) -> void:
	if not ProjectileController.can_spawn_projectile() or not is_inside_tree():
		return
	var parent_node := get_parent()
	if not parent_node:
		return
	var dir := (target.global_position - global_position).normalized()
	
	# Spawn pet projectile
	var proj := ProjectileController.new()
	parent_node.add_child(proj)
	proj.global_position = global_position
	
	var is_soul_binder: bool = (GameManager.current_character and GameManager.current_character.id == "soul_binder")
	var final_dmg: float = damage * (1.4 if is_soul_binder else 1.0)
	
	var p_type := "fireball" if pet_type == "hellhound" else "slash"
	proj.setup(final_dmg, false, dir, 520.0, p_type, true)
	
	# Soul Binder necrotic bond heals player on pet hits
	if is_soul_binder:
		proj.has_life_steal = true
		
	if AudioManager:
		AudioManager.play_sfx("pet_attack")
