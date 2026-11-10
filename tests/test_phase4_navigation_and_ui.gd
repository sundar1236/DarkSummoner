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
	assert_test(shell.screen_sanctuary != null and not shell.screen_sanctuary.visible, "Events screen exists and is hidden on Campaign")
	shell.nav_dock.select_tab(4)
	await get_tree().process_frame
	assert_test(shell.screen_sanctuary.visible, "Events tab opens dedicated Events page")
	assert_test(shell.screen_sanctuary.get_node("Content/EventsTitle").text == "ABYSSAL EVENTS", "Events page no longer displays champion selection")
	shell.nav_dock.select_tab(2)
	await get_tree().process_frame

	# Daily tasks shortcut opens the real mission panel in the Shop screen.
	shell.screen_campaign.btn_tasks.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_test(shell.current_tab == 0 and shell.screen_shop.visible, "Campaign daily-tasks shortcut opens the Shop screen")
	assert_test((shell.screen_shop.get_node("ScrollContainer") as ScrollContainer).scroll_vertical > 0, "Daily-tasks shortcut scrolls to the mission panel")
	
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
	
	# Campaign hub shows only real, implemented actions.
	assert_test(camp.banner_title.text == "Tower Expedition", "Campaign banner describes the actual tower progression")
	assert_test(not camp.banner_btn.visible, "Non-functional live-event carousel is not clickable")
	assert_test(not (camp.get_node("LeftSidebar") as Control).visible, "Unimplemented VIP, gift, and ranking shortcuts are hidden")
	assert_test(not camp.btn_friends.visible, "Unimplemented social shortcut is hidden")
	assert_test(not (camp.get_node("BottomControls/QuickAccessRow/ChestBtn") as Button).visible, "Repeatable placeholder chest reward is hidden")
	assert_test(not (camp.get_node("BottomControls/QuickAccessRow/GuildBtn") as Button).visible, "Unimplemented guild shortcut is hidden")
	assert_test(not (camp.get_node("BottomControls/ChatTicker") as Control).visible, "Fake online-player ticker is hidden")
	var tasks_requested := [false]
	camp.daily_tasks_requested.connect(func(): tasks_requested[0] = true)
	camp.btn_tasks.pressed.emit()
	assert_test(tasks_requested[0], "Daily tasks shortcut emits the real navigation signal")
	
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
	
	# Patrol rewards can be claimed once per eight-hour cycle.
	var old_patrol_claim: int = SaveManager.patrol_last_claim
	var old_profile_gold: int = SaveManager.profile_gold
	SaveManager.patrol_last_claim = 0
	camp._on_hunt_pressed()
	var claimed_profile_gold: int = SaveManager.profile_gold
	assert_test(claimed_profile_gold > old_profile_gold, "Ready Patrol Rewards add Gold to the persistent profile")
	camp._on_hunt_pressed()
	assert_test(SaveManager.profile_gold == claimed_profile_gold, "Patrol Rewards cannot be claimed repeatedly during cooldown")
	assert_test(int(SaveManager.get_patrol_reward_status().get("seconds_remaining", 0)) > 0, "Patrol claim starts the eight-hour cooldown")
	SaveManager.patrol_last_claim = old_patrol_claim
	SaveManager.profile_gold = old_profile_gold
	SaveManager.save_profile()
	
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
	
	# Blacksmith exposes all six persistent gear slots.
	var smith_scene := load("res://scenes/ui/blacksmith_modal.tscn") as PackedScene
	var smith := smith_scene.instantiate() as BlacksmithModal
	add_child(smith)
	await get_tree().process_frame
	assert_test(smith.btn_upgrade_weapon != null and smith.btn_upgrade_armor != null and smith.btn_upgrade_ring != null, "Blacksmith retains weapon, armor, and ring upgrade controls")
	assert_test(smith.btn_upgrade_helmet != null and smith.btn_upgrade_boots != null and smith.btn_upgrade_amulet != null, "Blacksmith exposes helmet, boots, and amulet upgrades")
	smith.queue_free()
	await get_tree().process_frame

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
	var shop := scene.instantiate() as ShopScreen
	add_child(shop)
	await get_tree().process_frame
	assert_test(shop.daily_mission_list.get_child_count() == 3, "Daily Hunts panel displays three missions")
	assert_test(shop.achievements_list.get_child_count() == 3, "Hunter Achievements panel displays three milestones")

	# Real-money offers must not mint resources without a billing provider.
	SaveManager.chapter_pack_purchased = false
	SaveManager.gems = 100
	SaveManager.energy = 20
	SaveManager.profile_gold = 500
	shop._on_buy_chapter_pack()
	assert_test(shop.btn_chapter_pack.disabled, "Chapter Pack is disabled without platform billing")
	assert_test(SaveManager.gems == 100 and SaveManager.energy == 20 and SaveManager.profile_gold == 500, "Unavailable paid offer grants no resources")

	# Buy a run item: currency is deducted and the actual item is stored for the next run.
	SaveManager.refresh_daily_shop_state()
	SaveManager.daily_shop_purchased_items.erase("fire_rune")
	SaveManager.shop_item_inventory.erase("fire_rune")
	SaveManager.profile_gold = 100
	var rune_btn := Button.new()
	shop.add_child(rune_btn)
	shop._buy_daily_item(rune_btn, "fire_rune", 80, false, "Fire Rune Acquired!")
	assert_test(SaveManager.profile_gold == 20, "Daily Fire Rune purchase deducts the correct gold")
	assert_test(SaveManager.get_shop_item_quantity("fire_rune") == 1, "Purchased Fire Rune is delivered to persistent run-item stash")
	assert_test(rune_btn.disabled and rune_btn.text == "SOLD OUT", "Purchased daily offer is marked sold out")
	SaveManager.save_profile()
	SaveManager.load_profile()
	assert_test(SaveManager.get_shop_item_quantity("fire_rune") == 1 and SaveManager.is_daily_offer_purchased("fire_rune"), "Purchased stock and daily limit persist after profile reload")
	shop._buy_daily_item(rune_btn, "fire_rune", 80, false, "Fire Rune Acquired!")
	assert_test(SaveManager.profile_gold == 20 and SaveManager.get_shop_item_quantity("fire_rune") == 1, "Daily offer cannot be purchased twice")

	# Premium shard offer grants the stated character shards, not an unrelated currency.
	SaveManager.daily_shop_purchased_items.erase("storm_shard")
	SaveManager.gems = 100
	var old_storm_shards: int = SaveManager.character_shards.get("storm_reaper", 0)
	var shard_btn := Button.new()
	shop.add_child(shard_btn)
	shop._buy_daily_item(shard_btn, "storm_shard", 50, true, "Storm shards acquired")
	assert_test(SaveManager.gems == 50, "Storm Shard offer deducts its gem price")
	assert_test(SaveManager.character_shards["storm_reaper"] == old_storm_shards + 5, "Storm Shard offer delivers five Storm Reaper shards")

	# Healing elixirs are carried into the next run as potion charges.
	SaveManager.daily_shop_purchased_items.erase("healing_elixir")
	SaveManager.shop_item_inventory.erase("healing_elixir")
	SaveManager.profile_gold = 100
	var elixir_btn := Button.new()
	shop.add_child(elixir_btn)
	shop._buy_daily_item(elixir_btn, "healing_elixir", 45, false, "Elixirs acquired")
	assert_test(SaveManager.get_shop_item_quantity("healing_elixir") == 2, "Healing Elixir offer stores two bonus potions")
	assert_test(SaveManager.consume_shop_item("healing_elixir", 2) == 2 and SaveManager.get_shop_item_quantity("healing_elixir") == 0, "Run startup can consume the purchased potion charges")

	# Daily missions and lifetime achievements have independent, claim-once rewards.
	SaveManager.daily_mission_progress.clear()
	SaveManager.daily_mission_claimed.clear()
	SaveManager.record_daily_mission_progress("enemy_slayer", 20)
	var slayer_mission: Dictionary = {}
	for mission in SaveManager.get_daily_missions():
		if str(mission.get("id", "")) == "enemy_slayer":
			slayer_mission = mission
	assert_test(bool(slayer_mission.get("completed", false)), "Defeating 20 enemies completes the daily slayer mission")
	var mission_gold_before: int = SaveManager.profile_gold
	var mission_shades_before: int = SaveManager.shades
	assert_test(SaveManager.claim_daily_mission_reward("enemy_slayer"), "Completed daily mission reward can be claimed")
	assert_test(SaveManager.profile_gold == mission_gold_before + 250 and SaveManager.shades == mission_shades_before + 5, "Daily mission grants its displayed Gold and Shades")
	assert_test(not SaveManager.claim_daily_mission_reward("enemy_slayer"), "Daily mission reward cannot be claimed twice")

	SaveManager.achievement_progress["abyssal_slayer"] = 99
	SaveManager.record_achievement_progress("abyssal_slayer", 1)
	var slayer_achievement: Dictionary = {}
	for achievement in SaveManager.get_achievements():
		if str(achievement.get("id", "")) == "abyssal_slayer":
			slayer_achievement = achievement
	assert_test(bool(slayer_achievement.get("completed", false)), "Lifetime slayer achievement completes at 100 kills")
	var achievement_gold_before: int = SaveManager.profile_gold
	var achievement_shades_before: int = SaveManager.shades
	assert_test(SaveManager.claim_achievement_reward("abyssal_slayer"), "Completed lifetime achievement reward can be claimed")
	assert_test(SaveManager.profile_gold == achievement_gold_before + 500 and SaveManager.shades == achievement_shades_before + 10, "Achievement grants its Gold and Shades rewards")
	assert_test(not SaveManager.claim_achievement_reward("abyssal_slayer"), "Lifetime achievement reward cannot be claimed twice")
	SaveManager.save_profile()
	SaveManager.load_profile()
	assert_test(bool(SaveManager.daily_mission_claimed.get("enemy_slayer", false)) and bool(SaveManager.achievement_claimed.get("abyssal_slayer", false)), "Daily and lifetime reward claims persist after profile reload")

	# Daily mission progress resets with the local shop date; lifetime achievements remain.
	SaveManager.daily_shop_date_key = "2000-01-01"
	SaveManager.daily_mission_progress["enemy_slayer"] = 12
	SaveManager.refresh_daily_shop_state()
	assert_test(SaveManager.daily_mission_progress.is_empty(), "Daily mission progress resets at the next local day")
	assert_test(int(SaveManager.achievement_progress.get("abyssal_slayer", 0)) == 100, "Lifetime achievement progress survives daily reset")

	# Free energy is limited by the local calendar date and has a real reset countdown.
	SaveManager.daily_free_energy_claim_date = ""
	SaveManager.daily_free_energy_claimed = false
	SaveManager.refresh_daily_shop_state()
	SaveManager.energy = 10
	assert_test(SaveManager.claim_daily_free_energy(20), "Daily free energy can be claimed once")
	assert_test(SaveManager.energy == 30 and SaveManager.daily_free_energy_claimed, "Daily claim grants +20 energy and persists claim state")
	assert_test(not SaveManager.claim_daily_free_energy(20), "Second free-energy claim on the same date is rejected")
	assert_test(SaveManager.get_seconds_until_daily_reset() > 0 and SaveManager.get_seconds_until_daily_reset() <= 86400, "Daily shop countdown is based on local midnight")

	assert_test(shop.btn_tab_chest.disabled and shop.btn_tab_wish.disabled and shop.btn_tab_limited.disabled and shop.btn_tab_topup.disabled, "Unimplemented store tabs are disabled rather than showing fake navigation")
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

	# Reduced motion is saved and applied to active arena backgrounds.
	var settings_scene := load("res://scenes/ui/settings_modal.tscn") as PackedScene
	var settings_modal := settings_scene.instantiate() as SettingsModal
	add_child(settings_modal)
	var arena_background := ArenaBackground.new()
	add_child(arena_background)
	await get_tree().process_frame
	SaveManager.settings_data["reduced_motion"] = false
	arena_background.set_reduced_motion(false)
	settings_modal.check_reduced_motion.toggled.emit(true)
	assert_test(bool(SaveManager.settings_data.get("reduced_motion", false)), "Reduced motion preference is saved")
	assert_test(arena_background.reduced_motion_enabled and not arena_background.is_processing(), "Reduced motion stops continuous arena flicker redraws")
	settings_modal.check_reduced_motion.toggled.emit(false)
	assert_test(not arena_background.reduced_motion_enabled and arena_background.is_processing(), "Full arena motion can be restored")
	settings_modal.queue_free()
	arena_background.queue_free()
	await get_tree().process_frame
