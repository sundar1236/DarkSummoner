class_name TestCharacterAnimationAndCombat
extends Node2D

const CharacterAnimationControllerClass = preload("res://scripts/combat/character_animation_controller.gd")
const OverheadHealthBarClass = preload("res://scripts/combat/overhead_health_bar.gd")
const CoinPickupClass = preload("res://scripts/combat/coin_pickup.gd")
const ImpactSparkVFXClass = preload("res://scripts/combat/impact_spark_vfx.gd")

# Comprehensive automated test suite for Phase 3:
# Character Art, Animation, Combat Feedback, Readability, and Summoning Circle Presentation.

var passed: int = 0
var failed: int = 0
var total: int = 0

func _ready() -> void:
	print("--- Running Phase 3 Character Animation & Combat Tests ---")
	
	test_animation_controller_state_machine()
	test_three_stage_combo_cycle()
	test_overhead_health_bar()
	test_character_sprites_and_ambience()
	test_enemy_visual_distinctions_and_telegraphs()
	test_impact_sparks_and_projectiles()
	test_boss_controller_telegraphs()
	test_summoning_circle_hero_presentation()
	
	print("\n=== Phase 3 Test Results: %d/%d PASSED (%d failed) ===" % [passed, total, failed])
	if failed == 0:
		print("ALL PHASE 3 TESTS COMPLETED SUCCESSFULLY!")
	else:
		print("SOME TESTS FAILED!")
	
	await get_tree().process_frame
	get_tree().quit(0 if failed == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	total += 1
	if condition:
		passed += 1
		print("  [PASS] %s" % test_name)
	else:
		failed += 1
		printerr("  [FAIL] %s" % test_name)

func assert_eq(actual, expected, test_name: String) -> void:
	total += 1
	if actual == expected:
		passed += 1
		print("  [PASS] %s" % test_name)
	else:
		failed += 1
		printerr("  [FAIL] %s - Expected: %s, Actual: %s" % [test_name, str(expected), str(actual)])

func test_animation_controller_state_machine() -> void:
	print("\n--- Test: Animation Controller State Machine & Interrupts ---")
	var anim_ctrl = CharacterAnimationControllerClass.new()
	var test_sprite := Sprite2D.new()
	add_child(anim_ctrl)
	add_child(test_sprite)
	anim_ctrl.setup(test_sprite)
	
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.IDLE, "Initial state is IDLE")
	
	anim_ctrl.play_run()
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.RUN, "Transitions to RUN")
	
	# Attack lock
	var _st = anim_ctrl.trigger_attack(Vector2.RIGHT, "slash")
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.ATTACK, "Transitions to ATTACK")
	assert_true(anim_ctrl.is_locked, "Attack locks movement transition")
	
	# Dodge interrupt during attack
	anim_ctrl.trigger_dodge(Vector2.RIGHT)
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.DODGE, "Dodge immediately interrupts ATTACK")
	
	# Hurt interrupt
	anim_ctrl.trigger_hurt(Vector2.LEFT)
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.HURT, "Hurt immediately interrupts with high priority")
	
	# Victory celebration
	anim_ctrl.trigger_victory()
	assert_eq(anim_ctrl.current_state, CharacterAnimationControllerClass.AnimState.VICTORY, "Transitions to VICTORY celebration")
	
	anim_ctrl.queue_free()
	test_sprite.queue_free()

func test_three_stage_combo_cycle() -> void:
	print("\n--- Test: 3-Stage Attack Combo Cycle ---")
	var anim_ctrl = CharacterAnimationControllerClass.new()
	var test_sprite := Sprite2D.new()
	var test_socket := Marker2D.new()
	var test_weapon := Sprite2D.new()
	add_child(anim_ctrl)
	add_child(test_sprite)
	add_child(test_socket)
	test_socket.add_child(test_weapon)
	anim_ctrl.setup(test_sprite, test_socket, test_weapon)
	
	var stage0: int = anim_ctrl.trigger_attack(Vector2.RIGHT, "slash")
	assert_eq(stage0, 0, "First swing is Combo Stage 0 (Cleave)")
	assert_eq(anim_ctrl.combo_stage, 1, "Next combo queued is Stage 1")
	
	var stage1: int = anim_ctrl.trigger_attack(Vector2.RIGHT, "slash")
	assert_eq(stage1, 1, "Second swing is Combo Stage 1 (Reverse Upper)")
	assert_eq(anim_ctrl.combo_stage, 2, "Next combo queued is Stage 2")
	
	var stage2: int = anim_ctrl.trigger_attack(Vector2.RIGHT, "slash")
	assert_eq(stage2, 2, "Third swing is Combo Stage 2 (Heavy Thrust)")
	assert_eq(anim_ctrl.combo_stage, 0, "Combo resets back to Stage 0")
	
	# Test combo timeout reset
	anim_ctrl.trigger_attack(Vector2.RIGHT, "slash")
	assert_eq(anim_ctrl.combo_stage, 1, "Combo stage advanced to 1")
	anim_ctrl.combo_reset_timer = 0.05
	anim_ctrl.update(0.1, Vector2.ZERO, Vector2.RIGHT, 240.0)
	assert_eq(anim_ctrl.combo_stage, 0, "Combo resets to 0 after window expires")
	
	anim_ctrl.queue_free()
	test_sprite.queue_free()
	test_socket.queue_free()

func test_overhead_health_bar() -> void:
	print("\n--- Test: Overhead Floating Health Bar ---")
	var hp_bar = OverheadHealthBarClass.new()
	add_child(hp_bar)
	
	assert_true(is_instance_valid(hp_bar), "OverheadHealthBar instantiates cleanly")
	assert_eq(hp_bar.bg_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter ignores input (no joystick blocking)")
	
	hp_bar.set_health(120.0, 120.0, false)
	assert_eq(hp_bar.hp_label.text, "120 / 120", "HP Label shows formatted current/max")
	assert_true(hp_bar.fill_rect.color.g > 0.8, "HP > 50% renders healthy green fill")
	
	hp_bar.set_health(45.0, 120.0, false)
	assert_eq(hp_bar.hp_label.text, "45 / 120", "HP Label updates on health drop")
	assert_true(hp_bar.fill_rect.color.r > 0.8 and hp_bar.fill_rect.color.g > 0.6, "HP between 25-50% renders amber fill")
	
	hp_bar.set_health(15.0, 120.0, false)
	assert_true(hp_bar.fill_rect.color.r > 0.9 and hp_bar.fill_rect.color.g < 0.4, "HP < 25% renders danger red fill")
	
	hp_bar.queue_free()

func test_character_sprites_and_ambience() -> void:
	print("\n--- Test: Chibi Character Sprites & Ambience ---")
	var chars := ["shadow_hunter", "storm_reaper", "soul_binder", "base"]
	for c_id in chars:
		var path := "res://assets/sprites/characters/player_%s.png" % c_id
		var tex := TextureLoader.get_texture(path)
		assert_true(tex != null, "Character sprite exists & loads: %s" % path)
		if tex:
			assert_true(tex.get_width() > 0 and tex.get_height() > 0, "Character sprite has valid dimensions (%dx%d)" % [tex.get_width(), tex.get_height()])
			
	# Test PlayerController character switching & ambience
	var player := PlayerController.new()
	add_child(player)
	
	# Verify ground shadow
	assert_true(is_instance_valid(player.shadow_sprite), "Player ground contact shadow created")
	assert_eq(player.shadow_sprite.z_index, -2, "Shadow renders behind character")
	
	# Verify overhead health bar attached
	assert_true(is_instance_valid(player.overhead_hp_bar), "Player overhead health bar attached")
	
	# Test Soul Binder spirit companion
	GameManager.set_character("soul_binder")
	player._setup_character_ambience()
	assert_true(is_instance_valid(player.spirit_wisp), "Soul Binder spawns orbiting spirit wisp")
	
	# Test Storm Reaper electric sparks
	GameManager.set_character("storm_reaper")
	player._setup_character_ambience()
	assert_true(is_instance_valid(player.storm_sparks), "Storm Reaper spawns electric spark ambience")
	assert_true(player.spirit_wisp == null, "Previous wisp cleanly cleaned up")
	
	# Reset to default
	GameManager.set_character("shadow_hunter")
	player.queue_free()

func test_enemy_visual_distinctions_and_telegraphs() -> void:
	print("\n--- Test: Enemy Visuals, Elite Auras & Telegraphs ---")
	var e_types := ["swarmer", "cultist", "elite"]
	for t_id in e_types:
		var path := "res://assets/sprites/enemies/enemy_%s.png" % t_id
		var tex := TextureLoader.get_texture(path)
		assert_true(tex != null, "Enemy sprite exists & loads: %s" % path)
		
	var swarmer := EnemyController.new()
	add_child(swarmer)
	swarmer.setup("swarmer", 1)
	assert_eq(swarmer.max_hp, 35.0, "Swarmer HP initialized")
	swarmer.queue_free()
	
	var elite := EnemyController.new()
	add_child(elite)
	elite.setup("elite", 1)
	assert_eq(elite.max_hp, 140.0, "Elite brute has high max HP")
	assert_true(is_instance_valid(elite.elite_aura), "Elite brute has golden aura node")
	elite.queue_free()

	var charger := EnemyController.new()
	add_child(charger)
	charger.setup("charger", 1)
	assert_eq(charger.max_hp, 70.0, "Charger has its own durable enemy profile")
	assert_eq(charger.contact_damage, 20.0, "Charger dash has higher contact damage")
	assert_true(charger.has_method("_telegraph_charger"), "Charger uses a dedicated directional telegraph")
	charger.queue_free()
	
	# Test coin pickup
	var coin = CoinPickupClass.new()
	add_child(coin)
	coin.setup(5, Vector2(100, 100))
	assert_true(is_instance_valid(coin.sprite), "Coin pickup visual sprite initialized")
	assert_eq(coin.value, 5, "Coin value preserved")
	coin.queue_free()

func test_impact_sparks_and_projectiles() -> void:
	print("\n--- Test: Impact Sparks & Projectiles ---")
	var spark = ImpactSparkVFXClass.new()
	add_child(spark)
	spark.setup(false, Vector2(50, 50), Vector2.UP, Color.WHITE)
	assert_true(is_instance_valid(spark.sprite), "Impact spark sprite initialized")
	spark.queue_free()
	
	var crit_spark = ImpactSparkVFXClass.new()
	add_child(crit_spark)
	crit_spark.setup(true, Vector2(50, 50), Vector2.UP, Color(1, 0.8, 0.2))
	assert_true(is_instance_valid(crit_spark.sprite), "Critical impact spark sprite initialized")
	crit_spark.queue_free()
	
	var proj_types := ["slash", "lightning", "soul", "fireball", "enemy"]
	for p_type in proj_types:
		var proj := ProjectileController.new()
		add_child(proj)
		proj.setup(10.0, false, Vector2.RIGHT, 500.0, p_type, true)
		assert_true(proj.sprite != null and proj.sprite.texture != null, "Projectile type '%s' loads texture" % p_type)
		proj.queue_free()

func test_boss_controller_telegraphs() -> void:
	print("\n--- Test: Boss Controller & Danger Telegraphs ---")
	var boss_tex := TextureLoader.get_texture("res://assets/sprites/bosses/boss_abyssal_dread.png")
	assert_true(boss_tex != null, "Lord Malakar boss sprite loads")
	
	var boss := BossController.new()
	add_child(boss)
	boss.setup(1)
	assert_true(boss.max_hp >= 380.0, "Boss max HP correctly scaled")
	assert_true(is_instance_valid(boss.shadow_sprite), "Boss heavy contact shadow initialized")
	assert_eq(BossController.get_attack_pattern_name(3), "abyssal_cross", "Boss cycles through a fourth cross-lane attack")
	assert_eq(BossController.get_attack_pattern_name(4), "void_eruption", "Boss attack cycle returns to its first pattern")
	assert_true(boss._claim_boss_defeat(), "Boss defeat can be claimed once")
	assert_true(not boss._claim_boss_defeat(), "Duplicate boss defeat is rejected")
	boss.queue_free()

func test_summoning_circle_hero_presentation() -> void:
	print("\n--- Test: Summoning Circle Hero Presentation ---")
	var board := AltarBoard.new()
	board.size = Vector2(680, 560)
	add_child(board)
	
	# Verify 13 sockets remain intact
	assert_eq(AltarBoard.SOCKET_DEFS.size(), 13, "Summoning Circle maintains exactly 13 sockets")
	assert_true(board.get_socket_pos(0) != Vector2.ZERO, "Socket 0 has valid position")
	assert_true(board.get_socket_pos(12) != Vector2.ZERO, "Socket 12 has valid position")
	
	# Verify Hero Pedestal view
	var ped := HeroPedestalView.new()
	ped.size = Vector2(300, 300)
	ped.character_id = "shadow_hunter"
	add_child(ped)
	assert_true(is_instance_valid(ped), "HeroPedestalView renders properly")
	
	board.queue_free()
	ped.queue_free()
