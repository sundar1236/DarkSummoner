extends Node

# Automated Regression & Feature Test Suite for Phase 5:
# BattleArena HUD, Single-Stick Controls, In-Run XP, Valkyrie Skill Draft Modal,
# Skill Progression & Stat Application, Feedback, and Combat Lifecycle.

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print("  RUNNING PHASE 5 COMBAT, HUD & SKILLS TEST SUITE")
	print("==================================================\n")
	
	test_single_stick_and_touch_safety()
	test_hud_reactivity_and_game_speed()
	test_combat_wave_progression()
	test_xp_progression_and_level_up()
	test_valkyrie_draft_modal_and_offers()
	test_skill_evolution_combinations()
	test_skill_stat_application_and_progression()
	test_learned_skills_drawer()
	test_combat_feedback_announcements()
	test_pause_confirmation_and_defeat_revive()
	
	print("\n==================================================")
	print("  PHASE 5 TEST RESULTS: %d PASSED, %d FAILED" % [tests_passed, tests_failed])
	print("==================================================\n")
	
	if tests_failed > 0:
		print("FAILED SOME PHASE 5 TESTS!")
	else:
		print("SUCCESS: All Phase 5 assertions passed successfully!")
		
	get_tree().quit(tests_failed)

func assert_true(condition: bool, message: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] " + message)
	else:
		tests_failed += 1
		print("  [FAIL] " + message)

# 1. Test Dual-Stick Independent Controls & Input Safety
func test_single_stick_and_touch_safety() -> void:
	print("--- 1. Single-Stick Archero Controls & Input Safety ---")
	var player := PlayerController.new()
	var move_joy := VirtualJoystick.new()

	add_child(player)
	add_child(move_joy)
	player.move_joystick = move_joy

	# Moving left moves the hunter and suppresses the basic attack.
	move_joy.touch_index = 0
	move_joy.is_pressed = true
	move_joy.output_vector = Vector2(-1.0, 0.0)
	player._physics_process(0.016)

	assert_true(player.velocity.x < 0.0, "Single joystick moves the player left")
	assert_true(player.aim_direction.x < 0.0, "While moving, the hunter faces the movement direction")
	assert_true(not player.is_attacking, "Movement suppresses basic attacks")

	# Releasing the only stick allows stationary auto-targeting.
	move_joy._reset_joystick()
	player.velocity = Vector2.ZERO
	var enemy := Node2D.new()
	enemy.add_to_group("enemies")
	enemy.global_position = Vector2(120.0, 0.0)
	add_child(enemy)
	player._physics_process(0.016)

	assert_true(player.is_attacking, "Hunter automatically attacks a nearby enemy while stationary")
	assert_true(player.aim_direction.x > 0.0, "Hunter automatically aims toward the nearest enemy")

	# An unhandled touch release must not leave the movement joystick stuck.
	move_joy.touch_index = 2
	move_joy.is_pressed = true
	var release_ev := InputEventScreenTouch.new()
	release_ev.index = 2
	release_ev.pressed = false
	move_joy._unhandled_input(release_ev)
	assert_true(not move_joy.is_pressed and move_joy.touch_index == -1, "Touch release cancels a stuck movement joystick")

	player.queue_free()
	move_joy.queue_free()
	enemy.queue_free()

# 2. Test Combat HUD Reactivity & Game Speed
func test_hud_reactivity_and_game_speed() -> void:
	print("--- 2. BattleArena HUD Reactivity & Game Speed ---")
	var arena_scene := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	assert_true(arena_scene != null, "CombatArena scene loads cleanly")
	var arena := arena_scene.instantiate() as CombatManager
	add_child(arena)
	
	var hud := arena.get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
	assert_true(hud != null, "CombatHUD node exists in CombatArena")
	assert_true(hud.move_joystick != null, "MoveJoystick connected in CombatHUD")
	assert_true(hud.get_node_or_null("AimJoystick") == null, "Duplicate AimJoystick eliminated from CombatHUD")
	assert_true(hud.xp_bar != null, "XpBar exists in TopContainer")
	assert_true(hud.btn_speed != null, "Game speed button exists")
	
	# Initial game speed is 1.0
	assert_true(Engine.time_scale == 1.0, "Default Engine.time_scale is 1.0")
	assert_true(hud.btn_speed.text == "x1", "Game speed label is x1")
	
	# Toggle game speed to 2x
	hud._on_speed_toggle()
	assert_true(Engine.time_scale == 2.0, "Engine.time_scale toggles to 2.0")
	assert_true(hud.btn_speed.text == "x2", "Game speed label displays x2")
	
	# Toggle back to 1x
	hud._on_speed_toggle()
	assert_true(Engine.time_scale == 1.0, "Engine.time_scale returns to 1.0")
	assert_true(hud.btn_speed.text == "x1", "Game speed label returns to x1")
	
	# Pause signal verification
	var pause_fired := [false]
	var pause_conn = func(): pause_fired[0] = true
	hud.pause_requested.connect(pause_conn)
	hud.btn_pause.pressed.emit()
	assert_true(pause_fired[0], "Pause button emits pause_requested")
	hud.pause_requested.disconnect(pause_conn)
	
	# Stage timer increments
	var initial_timer_text := hud.timer_label.text if hud.timer_label else ""
	hud._process(65.0) # simulate 65 seconds
	assert_true(hud.timer_label.text == "01:05", "Stage timer formats elapsed MM:SS (01:05)")
	
	arena.queue_free()


# 3. Test two-wave encounter progression and duplicate defeat protection
func test_combat_wave_progression() -> void:
	print("--- 3. Combat Wave Progression ---")
	var arena := CombatManager.new()
	arena.current_wave = 1
	arena.total_waves = 2
	arena.enemies_remaining = 1
	arena._on_enemy_defeated(Node2D.new())

	assert_true(arena.current_wave == 2, "Clearing wave one advances to wave two")
	assert_true(arena.enemies_remaining == arena._get_wave_enemy_count(GameManager.level_number, 2), "Second wave spawns its own enemy group")
	assert_true(arena.enemies_remaining > 0, "Encounter remains active between waves")
	assert_true(arena._get_wave_enemy_count(1, 2) > arena._get_wave_enemy_count(1, 1), "Second wave increases enemy count")
	assert_true(arena._get_wave_enemy_type(0, true) == "elite", "Elite encounters include an elite enemy")
	assert_true(arena._get_wave_enemy_type(1, false) == "cultist", "Wave composition includes ranged cultists")
	arena.free()

# 4. Test In-Run XP Progression & Level-Up
func test_xp_progression_and_level_up() -> void:
	print("--- 3. In-Run XP Progression & Level-Up ---")
	GameManager.run_xp = 0.0
	GameManager.run_xp_to_next = 60.0
	GameManager.run_player_level = 1
	
	var xp_signal_fired := [false]
	var reported_curr_xp := [0.0]
	var level_up_fired := [false]
	var reported_new_level := [0]
	
	var on_xp = func(curr, _max):
		xp_signal_fired[0] = true
		reported_curr_xp[0] = curr
	var on_lvl = func(lvl):
		level_up_fired[0] = true
		reported_new_level[0] = lvl
		
	GameManager.run_xp_changed.connect(on_xp)
	GameManager.run_level_up.connect(on_lvl)
	
	# Add partial XP (30 / 60)
	GameManager.add_run_xp(30.0)
	assert_true(xp_signal_fired[0], "run_xp_changed signal fires on XP gain")
	assert_true(GameManager.run_xp == 30.0, "Current run XP is 30.0")
	assert_true(not level_up_fired[0], "Level up does not fire before threshold")
	
	# Add remaining XP to trigger Level Up (30 + 40 = 70 >= 60)
	GameManager.add_run_xp(40.0)
	assert_true(level_up_fired[0], "run_level_up fires when XP threshold is reached")
	assert_true(GameManager.run_player_level == 2, "Player level advanced to Lv.2")
	assert_true(GameManager.run_xp == 10.0, "Surplus XP carried over to next level (10.0)")
	assert_true(GameManager.run_xp_to_next > 60.0, "Next level XP requirement scaled up")
	
	GameManager.run_xp_changed.disconnect(on_xp)
	GameManager.run_level_up.disconnect(on_lvl)
	
	# Verify XpPickup drop mechanics
	var xp_pickup := XpPickup.new()
	add_child(xp_pickup)
	xp_pickup.setup(25.0, Vector2(100, 100))
	assert_true(xp_pickup.value == 25.0, "XpPickup initialized with 25.0 XP value")
	xp_pickup._collect()
	assert_true(GameManager.run_xp == 35.0, "Collecting XpPickup adds XP to GameManager")

# 4. Test Valkyrie Skill Draft Modal & Offer Generation
func test_valkyrie_draft_modal_and_offers() -> void:
	print("--- 4. Valkyrie Skill Draft Modal & Offer Generation ---")
	var draft_scene := load("res://scenes/ui/skill_draft_modal.tscn") as PackedScene
	assert_true(draft_scene != null, "SkillDraftModal scene loads cleanly")
	var modal := draft_scene.instantiate() as SkillDraftModal
	add_child(modal)
	
	GameManager.run_learned_skills.clear()
	modal.show_draft(1337) # deterministic seed
	assert_true(modal.is_modal_active and modal.visible, "Modal is active and visible")
	assert_true(get_tree().paused, "SceneTree is paused while draft modal is open")
	assert_true(not modal.card_1_offer.is_empty(), "Card 1 offer generated")
	assert_true(not modal.card_2_offer.is_empty(), "Card 2 offer generated")
	assert_true(not modal.card_3_offer.is_empty(), "Card 3 offer generated")
	assert_true(modal.card_1_offer["id"] != modal.card_2_offer["id"], "Offers 1 and 2 offer distinct skills")
	assert_true(modal.card_1_offer["id"] != modal.card_3_offer["id"], "Offers 1 and 3 offer distinct skills")
	assert_true(modal.card_2_offer["id"] != modal.card_3_offer["id"], "Offers 2 and 3 offer distinct skills")
	assert_true(modal.card_3_btn != null, "Third skill card has a selectable button")
	assert_true(modal.card_1_offer.get("is_new", false), "Initial skill is marked as NEW")
	
	# Refresh roll test
	assert_true(modal.refreshes_left == 1, "Initial refreshes count is 1")
	assert_true(modal.refresh_btn != null and not modal.refresh_btn.disabled, "Refresh button is enabled")
	
	var initial_offer1_id: String = modal.card_1_offer["id"]
	modal._on_refresh_pressed()
	assert_true(modal.refreshes_left == 0, "Refresh count decremented to 0")
	assert_true(modal.refresh_btn.disabled, "Refresh button disabled when out of rolls")
	assert_true(not modal.card_1_offer.is_empty(), "New cards re-rolled successfully")
	assert_true(GameManager.run_learned_skills.is_empty(), "Refreshing does NOT apply skills prematurely")
	
	# Select Card 1
	var chosen_id: String = modal.card_1_offer["id"]
	modal._choose_card(1)
	
	assert_true(not modal.is_modal_active and not modal.visible, "Modal closes after selection")
	assert_true(not get_tree().paused, "SceneTree unpaused after selection")
	assert_true(GameManager.run_learned_skills.has(chosen_id), "Selected skill applied to GameManager")
	assert_true(GameManager.run_learned_skills[chosen_id] == 1, "Skill level initialized at Rank 1")
	
	modal.queue_free()

# 5. Test Skill Stat Application & Upgrade Progression
func test_skill_stat_application_and_progression() -> void:
	print("--- 5. Skill Stat Application & Progression ---")
	GameManager.run_learned_skills.clear()
	GameManager.run_skill_modifiers.clear()
	GameManager.run_extra_revives = 0
	
	var base_stats := GameManager.get_player_effective_stats()
	var base_atk: float = base_stats["atk"]
	var base_crit: float = base_stats["crit_chance"]
	
	# Apply Rank 1 Shadow Flurry (+15 ATK, +0.15 ATK SPD)
	GameManager.apply_run_skill("shadow_flurry")
	var stats_r1 := GameManager.get_player_effective_stats()
	assert_true(stats_r1["atk"] > base_atk, "ATK increased after Rank 1 Shadow Flurry")
	assert_true(stats_r1["extra_projectiles"] >= 1, "Extra projectile count granted")
	
	# Upgrade to Rank 2 (+30 ATK)
	GameManager.apply_run_skill("shadow_flurry")
	var stats_r2 := GameManager.get_player_effective_stats()
	assert_true(stats_r2["atk"] > stats_r1["atk"], "ATK scaled up further after Rank 2 upgrade")
	assert_true(GameManager.run_learned_skills["shadow_flurry"] == 2, "Shadow Flurry is now Rank 2")
	
	# Upgrade to Rank 3 (Max Mastery)
	GameManager.apply_run_skill("shadow_flurry")
	assert_true(GameManager.run_learned_skills["shadow_flurry"] == 3, "Shadow Flurry reached Rank 3 (Max)")
	
	# Max level skills are eliminated from candidates
	var offers := RunSkillDatabase.generate_offers(GameManager.run_learned_skills, 4)
	var contains_flurry := false
	for o in offers:
		if o["id"] == "shadow_flurry":
			contains_flurry = true
	assert_true(not contains_flurry, "Max level skill (Lv.3) is excluded from draft pool")
	
	# Apply Void Aegis with revive mastery
	GameManager.apply_run_skill("void_aegis") # Rank 1
	GameManager.apply_run_skill("void_aegis") # Rank 2
	GameManager.apply_run_skill("void_aegis") # Rank 3 (Mastery: +1 Revive)
	assert_true(GameManager.get_available_revives() >= 1, "Void Aegis Mastery granted an extra revive")


# 6. Test skill evolution recipes and fallback choices
func test_skill_evolution_combinations() -> void:
	print("--- 6. Skill Evolution Combinations ---")
	var old_learned: Dictionary = GameManager.run_learned_skills.duplicate(true)
	var old_modifiers: Dictionary = GameManager.run_skill_modifiers.duplicate(true)
	var old_evolutions: Array[String] = GameManager.run_skill_evolutions.duplicate()
	var old_evolution_modifiers: Dictionary = GameManager.run_skill_evolution_modifiers.duplicate(true)
	var old_revives: int = GameManager.run_extra_revives

	GameManager.run_learned_skills = {"hellfire_infusion": 2, "shadow_flurry": 2}
	GameManager.run_skill_modifiers.clear()
	GameManager.run_skill_evolutions.clear()
	GameManager.run_skill_evolution_modifiers.clear()
	GameManager.apply_run_skill("hellfire_infusion")
	assert_true(not GameManager.run_skill_evolutions.has("infernal_blade_storm"), "Evolution stays locked until both required skills reach Rank 3")
	GameManager.apply_run_skill("shadow_flurry")
	assert_true(GameManager.run_skill_evolutions.has("infernal_blade_storm"), "Rank 3 Hellfire and Shadow Flurry unlock Infernal Blade Storm")
	var evolved_stats: Dictionary = GameManager.get_player_effective_stats()
	assert_true(int(evolved_stats.get("extra_projectiles", 0)) >= 6, "Infernal Blade Storm adds extra projectiles")
	assert_true(evolved_stats.get("burn_on_hit", false), "Infernal Blade Storm enables burn on hit")

	var maxed: Dictionary = {}
	for skill in RunSkillDatabase.get_all_skills():
		maxed[skill.id] = skill.max_level
	var fallback_offers := RunSkillDatabase.generate_offers(maxed, 3, 7)
	assert_true(fallback_offers.size() == 3, "Fully mastered runs still receive three choices")
	assert_true(fallback_offers[0].id != fallback_offers[1].id and fallback_offers[1].id != fallback_offers[2].id, "Fallback choices are distinct")

	GameManager.run_learned_skills = old_learned
	GameManager.run_skill_modifiers = old_modifiers
	GameManager.run_skill_evolutions = old_evolutions
	GameManager.run_skill_evolution_modifiers = old_evolution_modifiers
	GameManager.run_extra_revives = old_revives
	GameManager.recalculate_stats_and_synergies()


# 6. Test Learned Skills Drawer
func test_learned_skills_drawer() -> void:
	print("--- 6. Learned Skills Drawer Content ---")
	var draft_scene := load("res://scenes/ui/skill_draft_modal.tscn") as PackedScene
	var modal := draft_scene.instantiate() as SkillDraftModal
	add_child(modal)
	
	# Open learned skills drawer
	modal._on_learned_pressed()
	assert_true(modal.learned_drawer.visible, "LearnedDrawer opened on button press")
	assert_true(modal.learned_list.get_child_count() > 0, "Learned skills list populated with active blessings")
	
	modal.close_drawer_btn.pressed.emit()
	assert_true(not modal.learned_drawer.visible, "LearnedDrawer closed cleanly")
	
	modal.queue_free()

# 7. Test Combat Feedback Announcements
func test_combat_feedback_announcements() -> void:
	print("--- 7. Combat Feedback Announcements ---")
	var arena_scene := load("res://scenes/combat/combat_arena.tscn") as PackedScene
	var arena := arena_scene.instantiate() as CombatManager
	add_child(arena)
	
	var hud := arena.get_node_or_null("HUDLayer/CombatHUD") as CombatHUD
	assert_true(hud.feedback_banner != null, "FeedbackBanner exists")
	assert_true(hud.feedback_label != null, "FeedbackLabel exists")
	
	hud.show_announcement("✦ TEST ANNOUNCEMENT ✦", 1.0, Color.GOLD)
	assert_true(hud.feedback_banner.visible, "Feedback banner becomes visible")
	assert_true(hud.feedback_label.text == "✦ TEST ANNOUNCEMENT ✦", "Feedback label displays message")
	assert_true(hud.feedback_label.modulate == Color.GOLD, "Feedback text color applied")
	
	# Floating damage number
	var dmg := DamageNumber.new()
	add_child(dmg)
	dmg.setup(85.0, true, Vector2(100, 100))
	assert_true(dmg.label.text.begins_with("CRIT!"), "DamageNumber marks critical strikes")
	
	dmg.queue_free()
	arena.queue_free()

# 8. Test Pause Confirmation and Defeat Revive
func test_pause_confirmation_and_defeat_revive() -> void:
	print("--- 8. Pause Confirmation and Defeat Revive ---")
	var set_scene := load("res://scenes/ui/settings_modal.tscn") as PackedScene
	var set_modal := set_scene.instantiate() as SettingsModal
	add_child(set_modal)
	
	var abandon_emitted := [false]
	set_modal.abandon_run_requested.connect(func(): abandon_emitted[0] = true)
	
	# First click on ABANDON requires confirmation
	set_modal.btn_abandon.pressed.emit()
	assert_true(not abandon_emitted[0], "First abandon click does NOT leave immediately")
	assert_true(set_modal.is_confirming_abandon, "Modal enters abandon confirmation state")
	assert_true(set_modal.btn_abandon.text.begins_with("CONFIRM"), "Abandon button requests confirmation")
	
	# Second click executes abandon
	set_modal.btn_abandon.pressed.emit()
	assert_true(abandon_emitted[0], "Second abandon click emits abandon_run_requested")
	
	set_modal.queue_free()
	
	# Defeat Screen Revive Button
	var gov_scene := load("res://scenes/ui/game_over_view.tscn") as PackedScene
	var gov := gov_scene.instantiate() as GameOverView
	add_child(gov)
	
	# With 1 revive available
	GameManager.run_extra_revives = 1
	gov.setup(1, 3)
	assert_true(gov.btn_revive != null and gov.btn_revive.visible, "Revive button visible when revives > 0")
	
	var revive_emitted := [false]
	gov.revive_requested.connect(func(): revive_emitted[0] = true)
	gov.btn_revive.pressed.emit()
	assert_true(revive_emitted[0], "Clicking Revive consumes revive and emits revive_requested")
	assert_true(GameManager.run_extra_revives == 0, "Revive count decremented to 0")
	assert_true(GameManager.player_hp > 0, "Player HP restored after revive")
	
	# Without revives
	gov.setup(1, 3)
	assert_true(not gov.btn_revive.visible, "Revive button hidden when revives == 0")
	
	gov.queue_free()
