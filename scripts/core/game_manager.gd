extends Node

const RunSkillDatabaseClass = preload("res://scripts/combat/run_skill_database.gd")

# Autoload GameManager for Abyssal Altar
# Coordinates game state, run progression, floor/level tracking, inventory state, and combat lifecycle.

signal run_started()
signal level_started(floor_num: int, level_num: int, encounter_type: String)
signal level_completed(floor_num: int, level_num: int)
signal boss_defeated(floor_num: int)
signal player_defeated(floor_num: int, level_num: int)
signal gold_changed(new_amount: int)
signal run_shades_changed(new_amount: int)
signal player_hp_changed(current: float, max_val: float)
signal potion_count_changed(new_count: int)
signal inventory_changed()
signal run_xp_changed(current_xp: float, max_xp: float)
signal run_level_up(new_level: int)
signal run_skill_applied(skill_id: String, new_level: int)

# Run State
var is_in_run: bool = false
var is_combat_active: bool = false
var has_claimed_level_reward: bool = false

var current_character: CharacterData
var floor_number: int = 1
var level_number: int = 1 # 1 to 5; level 5 is always Floor Boss!
var current_encounter_type: String = "combat"

var run_gold: int = 0
var run_shades: int = 0
var player_hp: float = 100.0
var player_max_hp: float = 100.0
var potions: int = 3
const MAX_POTIONS: int = 5
const BACKPACK_CAPACITY: int = 10

# In-Run Combat Progression & Learned Skills (Phase 5)
var run_xp: float = 0.0
var run_xp_to_next: float = 60.0
var run_player_level: int = 1
var run_learned_skills: Dictionary = {} # skill_id -> int level (1..3)
var run_skill_modifiers: Dictionary = {} # Accumulated stat buffs from drafted blessings
var run_extra_revives: int = 0

# Inventory
var altar_items: Array[ItemInstance] = []
var backpack_items: Array[ItemInstance] = []
var grid_manager: GridManager
var cached_synergies: Dictionary = {}
var active_move_tx: MoveTransaction = null

# Transactional Move Management
func begin_move_transaction(item: ItemInstance, source: String = "ALTAR_GRID") -> MoveTransaction:
	active_move_tx = MoveTransaction.begin(item, source)
	return active_move_tx

func commit_active_move_transaction(dest: Vector2i) -> bool:
	if not active_move_tx:
		return false
	var tx := active_move_tx
	var success := tx.commit(dest, grid_manager, altar_items)
	if success:
		if tx.source_type == "BACKPACK" and backpack_items.has(tx.item):
			backpack_items.erase(tx.item)
			if not altar_items.has(tx.item):
				altar_items.append(tx.item)
		if AudioManager: AudioManager.play_sfx("item_place")
		recalculate_stats_and_synergies()
	else:
		if AudioManager: AudioManager.play_sfx("ui_error")
	active_move_tx = null
	return success

func rollback_active_move_transaction() -> void:
	if active_move_tx:
		active_move_tx.rollback()
		active_move_tx = null
		recalculate_stats_and_synergies()

func rotate_active_move_transaction() -> void:
	if active_move_tx:
		active_move_tx.rotate_clockwise()

func recycle_item(item: ItemInstance) -> int:
	if not item or not item.data:
		return 0
	var tier: int = item.data.tier
	var gold_val: int = 25
	if tier == 2:
		gold_val = 60
	elif tier >= 3:
		gold_val = 150
		
	if altar_items.has(item):
		altar_items.erase(item)
		recalculate_stats_and_synergies()
	elif backpack_items.has(item):
		backpack_items.erase(item)
		inventory_changed.emit()
	else:
		return 0
		
	add_gold(gold_val)
	if AudioManager:
		AudioManager.play_sfx("shop_buy")
	return gold_val

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dims := Vector2i(4, 4)
	if SaveManager:
		dims = SaveManager.get_altar_grid_dimensions()
	grid_manager = GridManager.new(dims.x, dims.y)

func start_new_run(char_id: String, start_floor: int = 1) -> void:
	is_in_run = true
	is_combat_active = false
	has_claimed_level_reward = false
	
	current_character = CharacterDatabase.get_character(char_id)
	floor_number = max(1, start_floor)
	level_number = 1
	current_encounter_type = "combat"
	
	# Update grid dimensions based on permanent upgrade
	var dims := SaveManager.get_altar_grid_dimensions()
	grid_manager = GridManager.new(dims.x, dims.y)
	
	run_gold = 30 + SaveManager.get_permanent_starting_gold()
	run_shades = 0
	potions = 3
	
	# Reset in-run XP & skills
	run_xp = 0.0
	run_xp_to_next = 60.0
	run_player_level = 1
	run_learned_skills.clear()
	run_skill_modifiers.clear()
	run_extra_revives = 0
	
	altar_items.clear()
	backpack_items.clear()
	
	# Populate starter items
	var starter_ids := current_character.starter_item_ids
	var slot_x := 0
	var slot_y := 0
	for item_id in starter_ids:
		var data := ItemDatabase.get_item(item_id)
		if data:
			var inst := ItemInstance.new(data, Vector2i(slot_x, slot_y), 0)
			if grid_manager.can_place_item(inst, inst.grid_pos, altar_items):
				altar_items.append(inst)
				slot_x += inst.get_width_and_height().x
			else:
				backpack_items.append(inst)
				
	recalculate_stats_and_synergies()
	player_hp = player_max_hp
	
	run_started.emit()
	level_started.emit(floor_number, level_number, current_encounter_type)

func recalculate_stats_and_synergies() -> void:
	cached_synergies = ItemSynergyManager.evaluate_synergies(altar_items, grid_manager)
	
	# Calculate total player max HP
	var base_hp: float = current_character.base_hp if current_character else 100.0
	var perm_hp: float = SaveManager.get_permanent_hp_bonus() if SaveManager else 0.0
	var gear_stats: Dictionary = SaveManager.get_equipped_gear_stats() if SaveManager else {}
	var item_hp: float = cached_synergies.get("total_hp", 0.0) + gear_stats.get("bonus_hp", 0.0)
	var skill_hp: float = run_skill_modifiers.get("bonus_hp", 0.0)
	
	player_max_hp = base_hp + perm_hp + item_hp + skill_hp
	player_hp = clampf(player_hp, 0.0, player_max_hp)
	
	player_hp_changed.emit(player_hp, player_max_hp)
	inventory_changed.emit()

func get_player_effective_stats() -> Dictionary:
	var base_atk: float = current_character.base_atk if current_character else 15.0
	var base_speed: float = current_character.base_speed if current_character else 220.0
	var base_crit: float = current_character.base_crit_chance if current_character else 0.1
	var base_atk_rate: float = current_character.base_attack_rate if current_character else 2.0
	
	var perm_atk_mult: float = SaveManager.get_permanent_atk_multiplier() if SaveManager else 1.0
	var perm_spd_mult: float = SaveManager.get_permanent_speed_multiplier() if SaveManager else 1.0
	var perm_crit: float = SaveManager.get_permanent_crit_bonus() if SaveManager else 0.0
	
	var gear_stats: Dictionary = SaveManager.get_equipped_gear_stats() if SaveManager else {}
	var item_atk: float = cached_synergies.get("total_atk", 0.0) + gear_stats.get("bonus_atk", 0.0) + run_skill_modifiers.get("bonus_atk", 0.0)
	var item_crit: float = cached_synergies.get("total_crit", 0.0) + gear_stats.get("bonus_crit", 0.0) + run_skill_modifiers.get("bonus_crit", 0.0)
	var item_speed: float = cached_synergies.get("total_speed", 0.0) + gear_stats.get("bonus_speed", 0.0) + run_skill_modifiers.get("bonus_speed", 0.0)
	var item_atk_speed: float = cached_synergies.get("total_atk_speed", 0.0) + gear_stats.get("bonus_atk_speed", 0.0) + run_skill_modifiers.get("bonus_atk_speed", 0.0)
	
	var final_atk: float = (base_atk + item_atk) * perm_atk_mult
	var final_speed: float = (base_speed + item_speed) * perm_spd_mult
	var final_crit: float = clampf(base_crit + perm_crit + item_crit, 0.0, 1.0)
	var final_atk_rate: float = base_atk_rate * (1.0 + item_atk_speed)
	
	return {
		"atk": final_atk,
		"speed": final_speed,
		"crit_chance": final_crit,
		"attack_rate": final_atk_rate,
		"burn_on_hit": run_skill_modifiers.get("burn_on_hit", false),
		"chain_lightning": run_skill_modifiers.get("chain_lightning", false),
		"life_steal": run_skill_modifiers.get("life_steal", false),
		"dodge_cdr": run_skill_modifiers.get("dodge_cdr", 0.0),
		"extra_projectiles": run_skill_modifiers.get("extra_projectiles", 0),
		"hp_on_kill": run_skill_modifiers.get("hp_on_kill", 0.0),
		"synergies": cached_synergies
	}

# In-Run XP & Valkyrie Level Progression
func add_run_xp(amount: float) -> void:
	if amount <= 0.0:
		return
	run_xp += amount
	
	while run_xp >= run_xp_to_next:
		run_xp -= run_xp_to_next
		run_player_level += 1
		# Exponential curve for XP threshold
		run_xp_to_next = float(int(run_xp_to_next * 1.45))
		run_level_up.emit(run_player_level)
		if AudioManager:
			AudioManager.play_sfx("level_win")
			
	run_xp_changed.emit(run_xp, run_xp_to_next)

func apply_run_skill(skill_id: String) -> bool:
	if skill_id == "valkyrie_boon":
		# Fallback boon: Full heal + 150 gold
		heal_player(player_max_hp)
		add_gold(150)
		if AudioManager: AudioManager.play_sfx("potion")
		return true
	elif skill_id == "abyssal_tithe":
		# Fallback tithe: +25 permanent shades
		add_run_shades(25)
		if AudioManager: AudioManager.play_sfx("item_merge")
		return true
		
	var skill = RunSkillDatabaseClass.get_skill(skill_id)
	if not skill:
		return false
		
	var cur_lvl: int = run_learned_skills.get(skill_id, 0)
	var new_lvl: int = mini(cur_lvl + 1, skill.max_level)
	run_learned_skills[skill_id] = new_lvl
	
	# Apply rank stat modifications atomically
	var rank_info := skill.get_rank_info(new_lvl)
	var mods: Dictionary = rank_info.get("mods", {})
	for k in mods:
		if mods[k] is bool:
			run_skill_modifiers[k] = mods[k]
		elif mods[k] is int:
			run_skill_modifiers[k] = int(mods[k])
		elif mods[k] is float:
			run_skill_modifiers[k] = float(mods[k])
			
	if mods.has("extra_revive"):
		run_extra_revives += int(mods["extra_revive"])
		
	recalculate_stats_and_synergies()
	run_skill_applied.emit(skill_id, new_lvl)
	if AudioManager:
		AudioManager.play_sfx("item_place")
	return true

func get_learned_skills_summary() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for s_id in run_learned_skills:
		var skill = RunSkillDatabaseClass.get_skill(s_id)
		if skill:
			var lvl: int = run_learned_skills[s_id]
			var rank_info := skill.get_rank_info(lvl)
			list.append({
				"id": s_id,
				"name": skill.name,
				"level": lvl,
				"max_level": skill.max_level,
				"icon_symbol": skill.icon_symbol,
				"rarity": skill.rarity,
				"desc": rank_info.get("desc", ""),
				"stat_arrow": rank_info.get("stat_arrow", "")
			})
	return list

func get_available_revives() -> int:
	return run_extra_revives

func use_revive() -> bool:
	if run_extra_revives <= 0:
		return false
	run_extra_revives -= 1
	heal_player(player_max_hp * 0.6)
	is_combat_active = true
	if AudioManager:
		AudioManager.play_sfx("potion")
	return true

func heal_player(amount: float) -> void:
	if player_hp <= 0:
		return
	player_hp = minf(player_hp + amount, player_max_hp)
	player_hp_changed.emit(player_hp, player_max_hp)

func damage_player(amount: float) -> void:
	if player_hp <= 0:
		return
	player_hp = maxf(0.0, player_hp - amount)
	player_hp_changed.emit(player_hp, player_max_hp)
	if player_hp <= 0:
		on_player_death()

func use_potion() -> bool:
	if potions <= 0 or player_hp >= player_max_hp or player_hp <= 0:
		if AudioManager:
			AudioManager.play_sfx("ui_error")
		return false
	
	potions -= 1
	var heal_amt: float = 40.0 + (SaveManager.get_permanent_potion_heal_bonus() if SaveManager else 0.0)
	heal_player(heal_amt)
	if AudioManager:
		AudioManager.play_sfx("potion")
	potion_count_changed.emit(potions)
	return true

func add_gold(amount: int) -> void:
	if amount <= 0: return
	run_gold += amount
	gold_changed.emit(run_gold)

func spend_gold(amount: int) -> bool:
	if amount <= 0: return true
	if run_gold >= amount:
		run_gold -= amount
		gold_changed.emit(run_gold)
		return true
	if AudioManager:
		AudioManager.play_sfx("ui_error")
	return false

func add_run_shades(amount: int) -> void:
	if amount <= 0: return
	run_shades += amount
	run_shades_changed.emit(run_shades)

# Level and Progression Control
func complete_current_level() -> void:
	if has_claimed_level_reward:
		return # Prevent duplicate claim!
	has_claimed_level_reward = true
	is_combat_active = false
	
	if level_number == 5:
		# Floor Boss Defeated!
		if AudioManager:
			AudioManager.play_sfx("boss_defeat")
		boss_defeated.emit(floor_number)
	else:
		if AudioManager:
			AudioManager.play_sfx("level_win")
		level_completed.emit(floor_number, level_number)

func advance_to_next_level() -> void:
	has_claimed_level_reward = false
	if level_number == 5:
		# Beat floor boss -> Unlock next floor, restart at Level 1 of next floor!
		var completed_floor := floor_number
		SaveManager.unlock_next_floor(completed_floor)
		SaveManager.add_shades(run_shades)
		run_shades = 0
		floor_number += 1
		level_number = 1
	else:
		level_number += 1
		
	# Select encounter type: Level 5 is GUARANTEED boss!
	if level_number == 5:
		current_encounter_type = "boss"
	elif level_number == 3:
		# Keep the run focused on continuous action combat. The Bazaar is a hub feature.
		current_encounter_type = "elite"
	else:
		current_encounter_type = "combat"
		
	level_started.emit(floor_number, level_number, current_encounter_type)

func on_player_death() -> void:
	is_combat_active = false
	# Deposit collected shades into permanent bank so progress is preserved!
	if run_shades > 0:
		SaveManager.add_shades(run_shades)
		run_shades = 0
		
	player_defeated.emit(floor_number, level_number)

# Retry same floor on death
func retry_current_floor() -> void:
	has_claimed_level_reward = false
	is_combat_active = false
	# Boss defeat restarts player at Level 1 of the same floor.
	# Losing to a boss must not send the player back to Floor 1!
	level_number = 1
	current_encounter_type = "combat"
	
	# Restore player HP and replenish basic potions
	player_hp = player_max_hp
	potions = 3
	player_hp_changed.emit(player_hp, player_max_hp)
	potion_count_changed.emit(potions)
	
	level_started.emit(floor_number, level_number, current_encounter_type)

# Inventory Actions
func can_merge_items(a: ItemInstance, b: ItemInstance) -> bool:
	if a == b or not a.data or not b.data:
		return false
	return a.data.id == b.data.id and a.data.merge_into_id != ""

func merge_items(item_a: ItemInstance, item_b: ItemInstance) -> ItemInstance:
	if not can_merge_items(item_a, item_b):
		return null
		
	var target_id := item_a.data.merge_into_id
	var new_data := ItemDatabase.get_item(target_id)
	if not new_data:
		return null
		
	var target_pos := item_b.grid_pos
	var target_rot := item_b.rotation_step
	var is_in_altar: bool = altar_items.has(item_b)
	
	# Remove both items from their collections
	altar_items.erase(item_a)
	backpack_items.erase(item_a)
	altar_items.erase(item_b)
	backpack_items.erase(item_b)
	
	var merged_item := ItemInstance.new(new_data, target_pos, target_rot)
	if is_in_altar:
		if grid_manager.can_place_item(merged_item, merged_item.grid_pos, altar_items):
			altar_items.append(merged_item)
		else:
			backpack_items.append(merged_item)
	else:
		backpack_items.append(merged_item)
		
	if AudioManager:
		AudioManager.play_sfx("item_merge")
	recalculate_stats_and_synergies()
	return merged_item

func can_move_item_to(item: ItemInstance, target_pos: Vector2i, target_rot: int = -1) -> bool:
	if not item or not grid_manager:
		return false
	var saved_rot: int = item.rotation_step
	if target_rot >= 0:
		item.rotation_step = target_rot % 4
	var valid: bool = grid_manager.can_place_item_ignoring(item, target_pos, altar_items, item)
	item.rotation_step = saved_rot
	return valid

func move_item_on_altar(item: ItemInstance, target_pos: Vector2i, target_rot: int = -1) -> bool:
	if is_combat_active:
		if AudioManager: AudioManager.play_sfx("ui_error")
		return false
	if not altar_items.has(item):
		return false
		
	var tx := begin_move_transaction(item, "ALTAR_GRID")
	if target_rot >= 0:
		tx.preview_rotation = target_rot % 4
	
	if not commit_active_move_transaction(target_pos):
		return false
	return true

func move_item_to_altar(item: ItemInstance, target_pos: Vector2i, target_rot: int = -1) -> bool:
	if is_combat_active:
		if AudioManager: AudioManager.play_sfx("ui_error")
		return false
		
	if altar_items.has(item):
		return move_item_on_altar(item, target_pos, target_rot)
		
	var tx := begin_move_transaction(item, "BACKPACK")
	if target_rot >= 0:
		tx.preview_rotation = target_rot % 4
		
	if not commit_active_move_transaction(target_pos):
		return false
	return true

func add_item_to_backpack(item: ItemInstance) -> bool:
	if backpack_items.size() >= BACKPACK_CAPACITY:
		return false
	backpack_items.append(item)
	recalculate_stats_and_synergies()
	return true

func move_item_to_backpack(item: ItemInstance) -> bool:
	if is_combat_active:
		if AudioManager: AudioManager.play_sfx("ui_error")
		return false
		
	if backpack_items.size() >= BACKPACK_CAPACITY and not backpack_items.has(item):
		if AudioManager: AudioManager.play_sfx("ui_error")
		return false # Backpack full! Never silently delete.
		
	altar_items.erase(item)
	if not backpack_items.has(item):
		backpack_items.append(item)
		
	if AudioManager: AudioManager.play_sfx("item_place")
	recalculate_stats_and_synergies()
	return true

func set_character(char_id: String) -> void:
	current_character = CharacterDatabase.get_character(char_id)
	recalculate_stats_and_synergies()
