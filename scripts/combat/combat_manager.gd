class_name CombatManager
extends Node2D

# Manages arena combat flow, wave progression, enemy spawning,
# boss encounters, and HUD announcement coordination.

signal combat_finished(is_victory: bool)

@export var player: PlayerController
@export var boss_health_bar: ProgressBar
@export var boss_title_label: Label

var enemies_remaining: int = 0
var current_wave: int = 1
var total_waves: int = 2
var arena_bounds := Rect2(40, 100, 640, 1000)

var hud_ref: CombatHUD = null

func _ready() -> void:
	GameManager.is_combat_active = true
	hud_ref = get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
	_setup_arena_boundaries()
	_start_encounter()

func _setup_arena_boundaries() -> void:
	var static_body := StaticBody2D.new()
	static_body.collision_layer = 16 # Layer 5: Walls
	static_body.collision_mask = 0
	add_child(static_body)
	
	var walls := [
		Rect2(Vector2(20, 60), Vector2(680, 20)), # Top
		Rect2(Vector2(20, 1160), Vector2(680, 20)), # Bottom
		Rect2(Vector2(20, 60), Vector2(20, 1120)), # Left
		Rect2(Vector2(680, 60), Vector2(20, 1120)) # Right
	]
	
	for r in walls:
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = r.size
		col.shape = shape
		col.position = r.position + r.size * 0.5
		static_body.add_child(col)

func _start_encounter() -> void:
	var floor_num := GameManager.floor_number
	var level_num := GameManager.level_number
	var enc_type := GameManager.current_encounter_type
	
	if level_num == 5 or enc_type == "boss":
		_spawn_boss_encounter(floor_num)
	else:
		_spawn_wave_encounter(floor_num, level_num, enc_type)

func _spawn_wave_encounter(floor_num: int, level_num: int, enc_type: String) -> void:
	if AudioManager:
		AudioManager.play_music("combat")
	if boss_health_bar:
		boss_health_bar.visible = false
	if boss_title_label:
		boss_title_label.visible = false
		
	var enemy_count: int = 4 + (level_num * 2)
	enemies_remaining = enemy_count
	
	var is_elite_room: bool = (enc_type == "elite")
	
	if hud_ref:
		hud_ref.update_wave_progress(current_wave, total_waves, enemies_remaining)
		if is_elite_room:
			hud_ref.show_announcement("⚠ ELITE HORDE DETECTED ⚠", 2.2, Color(1.0, 0.45, 0.2))
		else:
			hud_ref.show_announcement("✦ Wave %d: Defeat the Abyssal Swarm ✦" % current_wave, 2.0, Color(0.4, 0.85, 1.0))
			
	for i in range(enemy_count):
		var enemy := EnemyController.new()
		add_child(enemy)
		
		# Random spawn position along periphery
		var spawn_pos := _get_random_arena_edge_pos()
		enemy.global_position = spawn_pos
		
		var e_type: String = "swarmer"
		if is_elite_room and i == 0:
			e_type = "elite"
		elif i % 2 == 1:
			e_type = "cultist"
			
		enemy.setup(e_type, floor_num)
		enemy.enemy_defeated.connect(_on_enemy_defeated)

func _spawn_boss_encounter(floor_num: int) -> void:
	if boss_health_bar:
		boss_health_bar.visible = true
	if boss_title_label:
		boss_title_label.visible = true
		boss_title_label.text = "LORD MALAKAR — ABYSSAL DREAD (FLOOR %d)" % floor_num
		
	if hud_ref:
		hud_ref.update_wave_progress(1, 1, 1)
		hud_ref.show_announcement("⚠ BOSS ENCOUNTER: LORD MALAKAR ⚠", 3.0, Color(1.0, 0.25, 0.35))
		
	var boss := BossController.new()
	add_child(boss)
	boss.global_position = Vector2(360, 300)
	boss.setup(floor_num)
	
	if boss_health_bar:
		boss.boss_hp_changed.connect(func(curr: float, max_v: float):
			boss_health_bar.max_value = max_v
			boss_health_bar.value = curr
		)
		
	boss.boss_defeated.connect(func():
		if boss_health_bar: boss_health_bar.visible = false
		if boss_title_label: boss_title_label.visible = false
		if hud_ref:
			hud_ref.show_announcement("✦ BOSS VANQUISHED! FLOOR CLEARED ✦", 2.6, Color(1.0, 0.88, 0.3))
		if is_instance_valid(player) and player.has_method("trigger_victory"):
			player.trigger_victory()
		combat_finished.emit(true)
	)

func _get_random_arena_edge_pos() -> Vector2:
	var side := randi() % 4
	match side:
		0: return Vector2(randf_range(80, 640), 140) # Top
		1: return Vector2(randf_range(80, 640), 1080) # Bottom
		2: return Vector2(80, randf_range(160, 1000)) # Left
		_: return Vector2(640, randf_range(160, 1000)) # Right

func _on_enemy_defeated(_enemy: Node2D) -> void:
	enemies_remaining -= 1
	if hud_ref:
		hud_ref.update_wave_progress(current_wave, total_waves, max(0, enemies_remaining))
		
	if enemies_remaining <= 0:
		if hud_ref:
			hud_ref.show_announcement("✦ VICTORY! ENCOUNTER CLEARED ✦", 2.2, Color(0.4, 1.0, 0.6))
		if is_instance_valid(player) and player.has_method("trigger_victory"):
			player.trigger_victory()
		GameManager.complete_current_level()
		combat_finished.emit(true)
