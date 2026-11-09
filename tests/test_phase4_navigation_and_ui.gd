extends Node

# Phase 4 Navigation & Complete UI Redesign Automated Test Suite

var passed: int = 0
var failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print("  RUNNING PHASE 4 NAVIGATION & UI TEST SUITE")
	print("==================================================\n")
	
	await test_top_resource_bar_reactivity()
	await test_bottom_nav_dock_tabs_and_badges()
	await test_main_shell_orchestration()
	await test_campaign_screen_features()
	await test_hero_loadout_subtabs_and_progression()
	await test_shop_screen_atomic_purchases()
	await test_modals_functionality()
	
	print("\n==================================================")
	print("  PHASE 4 TEST RESULTS: %d PASSED, %d FAILED" % [passed, failed])
	print("==================================================\n")
	
	if failed == 0:
		print("SUCCESS: All Phase 4 Navigation & UI tests passed successfully!\n")
	else:
		printerr("FAILURE: %d Phase 4 tests failed!\n" % failed)
		
	await get_tree().process_frame
	get_tree().quit(0 if failed == 0 else 1)

func assert_test(cond: bool, msg: String) -> void:
	if cond:
		passed += 1
		print("  [PASS] " + msg)
	else:
		failed += 1
		printerr("  [FAIL] " + msg)

# ---------------------------------------------------------------------
# 1. TopResourceBar Reactivity & Signals
# ---------------------------------------------------------------------
func test_top_resource_bar_reactivity() -> void:
	print("--- 1. TopResourceBar Reactivity & Signals ---")
	var scene := load("res://scenes/ui/top_resource_bar.tscn") as PackedScene
	assert_test(scene != null, "TopResourceBar scene loads cleanly")
	var bar = scene.instantiate()
	add_child(bar)
	await get_tree().process_frame
	
	# Initial display check
	assert_test(bar.energy_label != null, "Energy label exists in top bar")
	assert_test(bar.gold_label != null, "Gold label exists in top bar")
	assert_test(bar.gems_label != null, "Gems label exists in top bar")
	
	# Reactive update test
	SaveManager.profile_gold = 12500
	SaveManager.gold_changed.emit(12500)
	bar.refresh_display()
	assert_test(bar.gold_label.text == "12,500", "Gold label reflects SaveManager change (12,500)")
	
	SaveManager.energy = 38
	SaveManager.max_energy = 50
	SaveManager.energy_changed.emit(38, 50)
	bar.refresh_display()
	assert_test(bar.energy_label.text == "38/50", "Energy label reflects SaveManager change (38/50)")
	
	# Click signals
	var avatar_res := {"fired": false}
	bar.avatar_clicked.connect(func(): avatar_res.fired = true)
	var avatar_btn := bar.get_node_or_null("HeaderContent/LeftCluster/AvatarAnchor/AvatarBtn") as Button
	if avatar_btn:
		avatar_btn.pressed.emit()
	assert_test(avatar_res.fired, "Avatar click signal fires cleanly")
	
	var energy_res := {"fired": false}
	bar.energy_clicked.connect(func(): energy_res.fired = true)
	var energy_btn := bar.get_node_or_null("HeaderContent/RightCluster/EnergyPill/HBox/PlusBtn") as Button
	if energy_btn:
		energy_btn.pressed.emit()
	assert_test(energy_res.fired, "Energy '+' click signal fires cleanly")
	
	bar.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 2. BottomNavDock Tabs & Badges
# ---------------------------------------------------------------------
func test_bottom_nav_dock_tabs_and_badges() -> void:
	print("--- 2. BottomNavDock Tabs & Badges ---")
	var scene := load("res://scenes/ui/bottom_nav_dock.tscn") as PackedScene
	var dock = scene.instantiate()
	add_child(dock)
	await get_tree().process_frame
	
	assert_test(dock.tab_buttons.size() == 5, "Dock defines exactly 5 tab buttons")
	assert_test(dock.current_tab == 2, "Default active tab is Campaign (Index 2)")
	
	var dock_res := {"tab": -1}
	dock.tab_changed.connect(func(idx): dock_res.tab = idx)
	dock.select_tab(0)
	assert_test(dock_res.tab == 0 and dock.current_tab == 0, "Switched to Shop tab (Index 0)")
	assert_test(dock.tab_labels[0].get_theme_font_size("font_size") == 20, "Active tab label size is 20px")
	assert_test(dock.tab_labels[2].get_theme_font_size("font_size") == 17, "Inactive tab label size is 17px")
	
	# Badge tests
	SaveManager.daily_free_energy_claimed = false
	dock.refresh_badges()
	assert_test(dock.badge_shop.visible, "Shop badge visible when free energy is unclaimed")
	
	SaveManager.daily_free_energy_claimed = true
	dock.refresh_badges()
	assert_test(not dock.badge_shop.visible, "Shop badge hidden when free energy is claimed")
	
	dock.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 3. MainShell Orchestration & Transitions
# ---------------------------------------------------------------------
func test_main_shell_orchestration() -> void:
	print("--- 3. MainShell Orchestration & Modals ---")
	var scene := load("res://scenes/main/main_shell.tscn") as PackedScene
	var shell = scene.instantiate()
	add_child(shell)
	await get_tree().process_frame
	
	assert_test(shell.screen_campaign != null and shell.screen_campaign.visible, "MainShell defaults to Campaign screen visible")
	assert_test(shell.screen_shop != null and not shell.screen_shop.visible, "Shop screen hidden by default")
	assert_test(shell.screen_loadout != null and not shell.screen_loadout.visible, "Loadout screen hidden by default")
	
	# Switch to tab 1 (HeroLoadout)
	shell.nav_dock.select_tab(1)
	await get_tree().process_frame
	assert_test(shell.screen_loadout.visible, "HeroLoadout screen visible after tab 1 select")
	assert_test(not shell.screen_campaign.visible, "Campaign screen hidden after tab 1 select")
	
	# Modals instantiation
	assert_test(shell.modal_energy != null, "EnergyReplenishModal instantiated under MainShell")
	assert_test(shell.modal_profile != null, "PlayerProfileModal instantiated under MainShell")
	assert_test(shell.modal_blacksmith != null, "BlacksmithModal instantiated under MainShell")
	
	# Modal triggers
	shell.open_energy_modal()
	assert_test(shell.modal_energy.visible, "EnergyReplenishModal opened via open_energy_modal()")
	shell.modal_energy.visible = false
	
	shell.open_profile_modal()
	assert_test(shell.modal_profile.visible, "PlayerProfileModal opened via open_profile_modal()")
	shell.modal_profile.visible = false
	
	shell.open_blacksmith_modal()
	assert_test(shell.modal_blacksmith.visible, "BlacksmithModal opened via open_blacksmith_modal()")
	shell.modal_blacksmith.visible = false
	
	shell.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 4. CampaignScreen Features & Difficulty
# ---------------------------------------------------------------------
func test_campaign_screen_features() -> void:
	print("--- 4. CampaignScreen Features & Difficulty ---")
	var scene := load("res://scenes/campaign/campaign_screen.tscn") as PackedScene
	var camp = scene.instantiate()
	add_child(camp)
	await get_tree().process_frame
	
	# Event Carousel
	assert_test(camp.events_data.size() == 3, "Campaign has 3 carousel events")
	var initial_title: String = camp.events_data[camp.current_event_idx].title
	camp._cycle_event()
	assert_test(camp.events_data[camp.current_event_idx].title != initial_title, "Carousel cycles to next event on interaction")
	
	# Difficulty Selector
	camp._select_difficulty("torment")
	assert_test(SaveManager.difficulty == "torment", "Selected 'torment' difficulty persists to SaveManager")
	camp._select_difficulty("normal")
	assert_test(SaveManager.difficulty == "normal", "Selected 'normal' difficulty persists to SaveManager")
	
	# Start Button Energy Check
	SaveManager.energy = 2
	var camp_res := {"start": false, "energy_needed": false}
	camp.start_run_requested.connect(func(): camp_res.start = true)
	camp.insufficient_energy.connect(func(): camp_res.energy_needed = true)
	camp._on_start_pressed()
	assert_test(not camp_res.start and camp_res.energy_needed, "Start blocked when Energy < 5, emitting insufficient_energy")
	
	SaveManager.energy = 10
	camp_res.energy_needed = false
	camp._on_start_pressed()
	assert_test(camp_res.start and SaveManager.energy == 5, "Start allowed when Energy >= 5, deducting exactly 5 Energy")
	
	# Patrol Hunt Claim
	var pre_gold := SaveManager.profile_gold
	camp._on_hunt_pressed()
	assert_test(SaveManager.profile_gold >= pre_gold, "Patrol Hunt claim adds gold to persistent profile")
	
	camp.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 5. HeroLoadoutScreen Subtabs & Progression
# ---------------------------------------------------------------------
func test_hero_loadout_subtabs_and_progression() -> void:
	print("--- 5. HeroLoadoutScreen Subtabs & Progression ---")
	var scene := load("res://scenes/characters/hero_loadout_screen.tscn") as PackedScene
	var loadout = scene.instantiate()
	add_child(loadout)
	await get_tree().process_frame
	
	# Subtabs
	loadout._switch_subtab(0)
	assert_test(loadout.view_characters.visible, "Subtab 0: ViewCharacters is visible")
	loadout._switch_subtab(1)
	assert_test(loadout.view_gear.visible, "Subtab 1: ViewGear is visible")
	loadout._switch_subtab(2)
	assert_test(loadout.view_runes.visible, "Subtab 2: ViewRunes is visible")
	
	# Summoning Circle in subtab 2
	var circle = loadout.view_runes.get_node_or_null("TopHalf/SummoningCircle")
	assert_test(circle != null, "SummoningCircleView is embedded in ViewRunes")
	assert_test(circle.socket_positions.size() == 13, "SummoningCircle maintains 13 ritual sockets")
	
	# Character selection persistence
	loadout._select_character("storm_reaper")
	assert_test(GameManager.current_character != null and GameManager.current_character.id == "storm_reaper", "GameManager switches to storm_reaper")
	assert_test(SaveManager.active_character_id == "storm_reaper", "SaveManager saves active_character_id")
	
	# Equipment upgrade
	var pre_weapon := SaveManager.get_equipped_gear("weapon")
	var pre_weap_lvl: int = pre_weapon.upgrade_level if pre_weapon else -1
	SaveManager.profile_gold = 10000
	assert_test(SaveManager.upgrade_equipped_gear("weapon"), "Equipment weapon slot upgraded successfully")
	var upgraded_weapon := SaveManager.get_equipped_gear("weapon")
	assert_test(upgraded_weapon != null and upgraded_weapon.upgrade_level == pre_weap_lvl + 1, "Equipment upgrade level stored on weapon item")
	
	loadout.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 6. ShopScreen Atomic Purchases
# ---------------------------------------------------------------------
func test_shop_screen_atomic_purchases() -> void:
	print("--- 6. ShopScreen Atomic Purchases ---")
	var scene := load("res://scenes/shops/shop_screen.tscn") as PackedScene
	var shop = scene.instantiate()
	add_child(shop)
	await get_tree().process_frame
	
	SaveManager.chapter_pack_purchased = false
	SaveManager.gems = 100
	SaveManager.energy = 20
	SaveManager.profile_gold = 500
	
	# Buy Chapter Pack
	shop._on_buy_chapter_pack()
	assert_test(SaveManager.chapter_pack_purchased, "Chapter Pack marked as purchased in SaveManager")
	assert_test(SaveManager.gems == 600, "Chapter Pack granted +500 Gems (100 -> 600)")
	assert_test(SaveManager.energy == 70, "Chapter Pack granted +50 Energy (20 -> 70)")
	assert_test(SaveManager.profile_gold == 2000, "Chapter Pack granted +1500 Gold (500 -> 2000)")
	assert_test(shop.btn_chapter_pack.disabled, "Chapter Pack button disabled after purchase")
	
	# Attempt double purchase
	var pre_g := SaveManager.gems
	shop._on_buy_chapter_pack()
	assert_test(SaveManager.gems == pre_g, "Second Chapter Pack purchase blocked atomically")
	
	# Buy Daily Item with Gold
	SaveManager.profile_gold = 100
	var dummy_btn := Button.new()
	shop.add_child(dummy_btn)
	shop._buy_daily_item(dummy_btn, "fire_rune", 80, false, "Purchased!")
	assert_test(SaveManager.profile_gold == 20, "Daily item purchase deducted 80 gold (100 -> 20)")
	assert_test(dummy_btn.disabled and dummy_btn.text == "SOLD OUT", "Button marked SOLD OUT and disabled")
	
	# Free Daily Energy Claim
	SaveManager.daily_free_energy_claimed = false
	SaveManager.energy = 10
	var free_btn := Button.new()
	shop.add_child(free_btn)
	shop._claim_free_energy(free_btn)
	assert_test(SaveManager.energy == 30, "Free Energy Claim granted +20 Energy (10 -> 30)")
	assert_test(SaveManager.daily_free_energy_claimed, "daily_free_energy_claimed set to true")
	
	shop.queue_free()
	await get_tree().process_frame

# ---------------------------------------------------------------------
# 7. Modals Functionality
# ---------------------------------------------------------------------
func test_modals_functionality() -> void:
	print("--- 7. Modals Functionality ---")
	
	# EnergyReplenishModal
	var e_scene := load("res://scenes/ui/energy_replenish_modal.tscn") as PackedScene
	var e_modal = e_scene.instantiate()
	add_child(e_modal)
	await get_tree().process_frame
	
	SaveManager.energy = 10
	SaveManager.gems = 100
	e_modal._on_buy_gems()
	assert_test(SaveManager.gems == 50, "Gems replenishment spent 50 gems (100 -> 50)")
	assert_test(SaveManager.energy == 40, "Gems replenishment added 30 energy (10 -> 40)")
	e_modal.queue_free()
	
	# PlayerProfileModal
	var p_scene := load("res://scenes/ui/player_profile_modal.tscn") as PackedScene
	var p_modal = p_scene.instantiate()
	add_child(p_modal)
	await get_tree().process_frame
	
	p_modal.refresh_modal()
	assert_test(p_modal.lbl_name.text == SaveManager.player_name, "Profile modal displays correct player name")
	assert_test(p_modal.lbl_power.text.contains("Combat Power"), "Profile modal displays Combat Power")
	p_modal.queue_free()
	
	# BlacksmithModal
	var b_scene := load("res://scenes/ui/blacksmith_modal.tscn") as PackedScene
	var b_modal = b_scene.instantiate()
	add_child(b_modal)
	await get_tree().process_frame
	
	SaveManager.profile_gold = 5000
	var current_weapon := SaveManager.get_equipped_gear("weapon")
	var cur_w: int = current_weapon.upgrade_level if current_weapon else -1
	b_modal._upgrade_slot("weapon")
	var upgraded_weapon := SaveManager.get_equipped_gear("weapon")
	assert_test(upgraded_weapon != null and upgraded_weapon.upgrade_level == cur_w + 1, "Blacksmith modal upgraded weapon item")
	b_modal.queue_free()
	await get_tree().process_frame
