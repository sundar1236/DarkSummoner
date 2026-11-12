class_name CombatManager
extends Node2D

const MAX_ENEMIES_PER_WAVE: int = 16

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
var encounter_completed: bool = false

func _ready() -> void:
	GameManager.is_combat_active = true
	hud_ref = get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
	var arena_background := get_node_or_null("Background") as ArenaBackground
	if arena_background:
		arena_background.set_floor_theme(GameManager.floor_number)
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
	var arena_background := get_node_or_null("Background") as ArenaBackground
	if arena_background:
		var theme_name := arena_background.set_floor_theme(floor_num)
		if hud_ref:
			hud_ref.set_floor_theme_name(theme_name)
	
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

	current_wave = 1
	total_waves = 2
	encounter_completed = false
	_spawn_wave_group(floor_num, level_num, enc_type)

func _spawn_wave_group(floor_num: int, level_num: int, enc_type: String) -> void:
	var enemy_count: int = _get_wave_enemy_count(level_num, current_wave)
	enemies_remaining = enemy_count
	var is_elite_room: bool = (enc_type == "elite")

	if hud_ref:
		hud_ref.update_wave_progress(current_wave, total_waves, enemies_remaining)
		if is_elite_room:
			hud_ref.show_announcement("⚠ ELITE HORDE — WAVE %d/%d ⚠" % [current_wave, total_waves], 1.8, Color(1.0, 0.45, 0.2))
		else:
			hud_ref.show_announcement("✦ WAVE %d/%d — DEFEAT THE ABYSSAL SWARM ✦" % [current_wave, total_waves], 1.6, Color(0.4, 0.85, 1.0))

	for i in range(enemy_count):
		var enemy := EnemyController.new()
		add_child(enemy)
		enemy.global_position = _get_random_arena_edge_pos()

		var enemy_type: String = _get_wave_enemy_type(i, is_elite_room)
		enemy.setup(enemy_type, floor_num)
		enemy.enemy_defeated.connect(_on_enemy_defeated)

func _get_wave_enemy_count(level_num: int, wave_num: int) -> int:
	return mini(MAX_ENEMIES_PER_WAVE, 4 + (level_num * 2) + ((wave_num - 1) * 2))

func _get_wave_enemy_type(index: int, is_elite_room: bool) -> String:
	if is_elite_room and index == 0:
		return "mini_boss" if current_wave == 1 else "elite"

	var floor_theme_index := posmod(maxi(GameManager.floor_number, 1) - 1, 5)
	match floor_theme_index:
		0:
			if index % 5 == 4:
				return "charger"
			if index % 2 == 1:
				return "cultist"
		1:
			if index % 3 == 0:
				return "charger"
			if index % 3 == 1:
				return "cultist"
		2:
			if index % 4 == 3:
				return "charger"
			if index % 2 == 0:
				return "cultist"
		3:
			if index % 5 == 3:
				return "elite"
			if index % 3 == 0:
				return "cultist"
			if index % 2 == 0:
				return "charger"
		4:
			if index % 6 == 5:
				return "elite"
			if index % 3 == 0:
				return "charger"
			if index % 3 == 1:
				return "cultist"
	return "swarmer"

func _start_next_wave() -> void:
	if encounter_completed or current_wave >= total_waves:
		return
	current_wave += 1
	if hud_ref:
		hud_ref.show_announcement("⚔ INCOMING — WAVE %d ⚔" % current_wave, 1.6, Color(1.0, 0.72, 0.3))
	_spawn_wave_group(GameManager.floor_number, GameManager.level_number, GameManager.current_encounter_type)

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
	if encounter_completed or enemies_remaining <= 0:
		return

	enemies_remaining -= 1
	if hud_ref:
		hud_ref.update_wave_progress(current_wave, total_waves, enemies_remaining)

	if enemies_remaining > 0:
		return

	if current_wave < total_waves:
		_start_next_wave()
		return

	encounter_completed = true
	if hud_ref:
		hud_ref.show_announcement("✦ VICTORY! ENCOUNTER CLEARED ✦", 2.2, Color(0.4, 1.0, 0.6))
	if is_instance_valid(player) and player.has_method("trigger_victory"):
		player.trigger_victory()
	GameManager.complete_current_level()
	combat_finished.emit(true)
