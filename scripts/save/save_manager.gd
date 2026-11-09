extends Node

# Autoload SaveManager for Abyssal Altar
# Manages persistent profile saving, meta-progression, Shades currency, character unlocks, and settings.

const SAVE_PATH: String = "user://abyssal_altar_profile.json"
const SAVE_VERSION: int = 1
const PATROL_REWARD_COOLDOWN_SECONDS: int = 8 * 60 * 60

const DAILY_MISSION_DEFINITIONS: Dictionary = {
	"enemy_slayer": {"title": "Abyssal Slayer", "description": "Defeat 20 enemies", "target": 20, "reward_gold": 250, "reward_shades": 5},
	"encounter_clearer": {"title": "Relentless Hunter", "description": "Clear 3 encounters", "target": 3, "reward_gold": 300, "reward_shades": 8},
	"boss_hunter": {"title": "Boss Hunter", "description": "Defeat a floor boss", "target": 1, "reward_gold": 500, "reward_shades": 15}
}

const ACHIEVEMENT_DEFINITIONS: Dictionary = {
	"abyssal_slayer": {"title": "Abyssal Slayer", "description": "Defeat 100 enemies", "target": 100, "reward_gold": 500, "reward_shades": 10},
	"tower_climber": {"title": "Tower Climber", "description": "Clear 10 encounters", "target": 10, "reward_gold": 750, "reward_shades": 15},
	"lord_breaker": {"title": "Lord Breaker", "description": "Defeat 5 floor bosses", "target": 5, "reward_gold": 1500, "reward_shades": 30}
}

signal shades_changed(new_amount: int)
signal energy_changed(current: int, max_val: int)
signal gold_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal profile_changed()
signal profile_loaded()
signal daily_missions_changed()
signal achievements_changed()

var shades: int = 0
var gems: int = 150
var energy: int = 45
var max_energy: int = 50
var profile_gold: int = 5000
var player_name: String = "Hunter Raven"
var player_level: int = 5
var active_character_id: String = "shadow_hunter"
var has_completed_initial_character_selection: bool = false
var difficulty: String = "normal" # "normal", "hard", "torment"
var patrol_last_claim: int = 0
var chapter_stars: Dictionary = { 1: 3, 2: 1, 3: 0 }
var daily_free_energy_claimed: bool = false
var daily_free_energy_claim_date: String = ""
var daily_shop_date_key: String = ""
var daily_shop_purchased_items: Dictionary = {}
var shop_item_inventory: Dictionary = {}
var daily_mission_progress: Dictionary = {}
var daily_mission_claimed: Dictionary = {}
var achievement_progress: Dictionary = {}
var achievement_claimed: Dictionary = {}
var chapter_pack_purchased: bool = false

var highest_floor_unlocked: int = 1
var unlocked_characters: Array[String] = ["shadow_hunter"]
var character_levels: Dictionary = {
	"shadow_hunter": 1,
	"storm_reaper": 1,
	"soul_binder": 1,
	"frost_valkyrie": 1
}

var character_shards: Dictionary = {
	"shadow_hunter": 45,
	"storm_reaper": 20,
	"soul_binder": 12,
	"frost_valkyrie": 0
}

var character_stars: Dictionary = {
	"shadow_hunter": 2,
	"storm_reaper": 3,
	"soul_binder": 2,
	"frost_valkyrie": 1
}

var gear_inventory: Array[Dictionary] = []
var equipped_gear: Dictionary = {
	"weapon": "", "helmet": "", "armor": "", "boots": "", "amulet": "", "ring": ""
}
var _gear_profile_initialized: bool = false

var equipment_levels: Dictionary = {
	"weapon": 60,
	"amulet": 55,
	"ring": 58,
	"helmet": 60,
	"armor": 60,
	"boots": 55
}

var talent_cards: Dictionary = {
	"glory": 5,
	"tactics": 4,
	"swift_wind": 3,
	"super_crit": 4,
	"iron_will": 3,
	"vampiric": 3,
	"storm_call": 0,
	"flame_burst": 0
}

# Permanent upgrade tiers (0 to 5)
var permanent_upgrades: Dictionary = {
	"max_hp": 0,
	"atk": 0,
	"speed": 0,
	"crit": 0,
	"altar_expand": 0,
	"start_gold": 0,
	"potion_potency": 0
}

var settings_data: Dictionary = {
	"master_vol": 0.8,
	"music_vol": 0.7,
	"sfx_vol": 0.8,
	"ambience_vol": 0.6,
	"muted": false,
	"screen_shake": true,
	"reduced_motion": false
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()
	_ensure_starter_gear()
	refresh_daily_shop_state()

func get_upgrade_cost(stat_name: String) -> int:
	var current_level: int = permanent_upgrades.get(stat_name, 0)
	if current_level >= 5:
		return 999999 # Maxed
	# Configurable base costs
	var base_cost: int = 20
	if stat_name == "altar_expand":
		base_cost = 40
	return (current_level + 1) * base_cost

func upgrade_stat(stat_name: String) -> bool:
	if not permanent_upgrades.has(stat_name):
		return false
	var current_level: int = permanent_upgrades[stat_name]
	if current_level >= 5:
		return false
	var cost: int = get_upgrade_cost(stat_name)
	if shades >= cost:
		shades -= cost
		permanent_upgrades[stat_name] += 1
		save_profile()
		shades_changed.emit(shades)
		if AudioManager:
			AudioManager.play_sfx("upgrade")
		return true
	if AudioManager:
		AudioManager.play_sfx("ui_error")
	return false

func add_shades(amount: int) -> void:
	if amount <= 0:
		return
	shades += amount
	save_profile()
	shades_changed.emit(shades)

func spend_shades(amount: int) -> bool:
	if amount <= 0:
		return true
	if shades >= amount:
		shades -= amount
		save_profile()
		shades_changed.emit(shades)
		return true
	return false

func is_character_unlocked(char_id: String) -> bool:
	return unlocked_characters.has(char_id)

func complete_initial_character_selection(char_id: String) -> bool:
	if has_completed_initial_character_selection:
		return false
	if not ["shadow_hunter", "storm_reaper", "soul_binder"].has(char_id):
		return false
	if not unlocked_characters.has(char_id):
		unlocked_characters.append(char_id)
	active_character_id = char_id
	has_completed_initial_character_selection = true
	save_profile()
	profile_changed.emit()
	return true

func unlock_character(char_id: String, shade_cost: int = 0) -> bool:
	if is_character_unlocked(char_id):
		return true
	if shade_cost > 0:
		if not spend_shades(shade_cost):
			return false
	unlocked_characters.append(char_id)
	save_profile()
	if AudioManager:
		AudioManager.play_sfx("upgrade")
	return true

func unlock_next_floor(completed_floor: int) -> void:
	var target_floor: int = completed_floor + 1
	if target_floor > highest_floor_unlocked:
		highest_floor_unlocked = target_floor
		save_profile()

func get_altar_grid_dimensions() -> Vector2i:
	var expand_lvl: int = permanent_upgrades.get("altar_expand", 0)
	match expand_lvl:
		0: return Vector2i(4, 4)
		1: return Vector2i(5, 4)
		2: return Vector2i(5, 5)
		3: return Vector2i(6, 5)
		_: return Vector2i(6, 6)

func get_permanent_hp_bonus() -> float:
	return permanent_upgrades.get("max_hp", 0) * 15.0

func get_permanent_atk_multiplier() -> float:
	return 1.0 + (permanent_upgrades.get("atk", 0) * 0.08)

func get_permanent_speed_multiplier() -> float:
	return 1.0 + (permanent_upgrades.get("speed", 0) * 0.06)

func get_permanent_crit_bonus() -> float:
	return permanent_upgrades.get("crit", 0) * 0.04

func get_permanent_starting_gold() -> int:
	return permanent_upgrades.get("start_gold", 0) * 25

func get_permanent_potion_heal_bonus() -> float:
	return permanent_upgrades.get("potion_potency", 0) * 12.0

func spend_energy(amount: int) -> bool:
	if amount <= 0:
		return true
	if energy >= amount:
		energy -= amount
		save_profile()
		energy_changed.emit(energy, max_energy)
		return true
	return false

func add_energy(amount: int) -> void:
	if amount <= 0:
		return
	energy += amount
	save_profile()
	energy_changed.emit(energy, max_energy)

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if profile_gold >= amount:
		profile_gold -= amount
		save_profile()
		gold_changed.emit(profile_gold)
		return true
	return false

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	profile_gold += amount
	save_profile()
	gold_changed.emit(profile_gold)

func spend_gems(amount: int) -> bool:
	if amount <= 0:
		return true
	if gems < amount:
		return false
	gems -= amount
	save_profile()
	gems_changed.emit(gems)
	return true

func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	gems += amount
	save_profile()
	gems_changed.emit(gems)


func _get_local_date_key() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [int(now.get("year", 2000)), int(now.get("month", 1)), int(now.get("day", 1))]

func refresh_daily_shop_state() -> void:
	var today := _get_local_date_key()
	var changed := false
	if daily_free_energy_claimed and daily_free_energy_claim_date.is_empty():
		# Migrate old saves without a claim date without granting a second same-day claim.
		daily_free_energy_claim_date = today
		changed = true
	if daily_shop_date_key != today:
		daily_shop_date_key = today
		daily_shop_purchased_items.clear()
		daily_mission_progress.clear()
		daily_mission_claimed.clear()
		changed = true
		daily_missions_changed.emit()
	var claimed_today := daily_free_energy_claim_date == today
	if daily_free_energy_claimed != claimed_today:
		daily_free_energy_claimed = claimed_today
		changed = true
	if changed:
		save_profile()
		profile_changed.emit()

func get_seconds_until_daily_reset() -> int:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var seconds_today := int(now.get("hour", 0)) * 3600 + int(now.get("minute", 0)) * 60 + int(now.get("second", 0))
	return maxi(1, 86400 - seconds_today)

func is_daily_offer_purchased(item_id: String) -> bool:
	refresh_daily_shop_state()
	return bool(daily_shop_purchased_items.get(item_id, false))

func mark_daily_offer_purchased(item_id: String) -> bool:
	if item_id.is_empty() or is_daily_offer_purchased(item_id):
		return false
	daily_shop_purchased_items[item_id] = true
	save_profile()
	profile_changed.emit()
	return true

func claim_daily_free_energy(amount: int = 20) -> bool:
	refresh_daily_shop_state()
	if daily_free_energy_claimed or amount <= 0:
		return false
	add_energy(amount)
	daily_free_energy_claimed = true
	daily_free_energy_claim_date = _get_local_date_key()
	save_profile()
	profile_changed.emit()
	return true

func add_shop_item(item_id: String, amount: int = 1) -> bool:
	if item_id.is_empty() or amount <= 0:
		return false
	shop_item_inventory[item_id] = int(shop_item_inventory.get(item_id, 0)) + amount
	save_profile()
	profile_changed.emit()
	return true

func get_shop_item_quantity(item_id: String) -> int:
	return maxi(0, int(shop_item_inventory.get(item_id, 0)))

func consume_shop_item(item_id: String, amount: int = 1) -> int:
	if item_id.is_empty() or amount <= 0:
		return 0
	var available := get_shop_item_quantity(item_id)
	var consumed := mini(available, amount)
	if consumed <= 0:
		return 0
	var remaining := available - consumed
	if remaining == 0:
		shop_item_inventory.erase(item_id)
	else:
		shop_item_inventory[item_id] = remaining
	save_profile()
	profile_changed.emit()
	return consumed

func add_character_shards(char_id: String, amount: int) -> bool:
	if not character_shards.has(char_id) or amount <= 0:
		return false
	character_shards[char_id] = int(character_shards.get(char_id, 0)) + amount
	save_profile()
	profile_changed.emit()
	return true


func record_daily_mission_progress(mission_id: String, amount: int = 1) -> void:
	refresh_daily_shop_state()
	if amount <= 0 or not DAILY_MISSION_DEFINITIONS.has(mission_id) or bool(daily_mission_claimed.get(mission_id, false)):
		return
	var definition: Dictionary = DAILY_MISSION_DEFINITIONS[mission_id]
	var target: int = int(definition.get("target", 1))
	var current: int = int(daily_mission_progress.get(mission_id, 0))
	var updated: int = mini(target, current + amount)
	if updated == current:
		return
	daily_mission_progress[mission_id] = updated
	if updated >= target or updated % 5 == 0:
		save_profile()
	daily_missions_changed.emit()

func get_daily_missions() -> Array[Dictionary]:
	refresh_daily_shop_state()
	var result: Array[Dictionary] = []
	for mission_id in DAILY_MISSION_DEFINITIONS:
		var definition: Dictionary = DAILY_MISSION_DEFINITIONS[mission_id]
		var target: int = int(definition.get("target", 1))
		var progress: int = mini(target, int(daily_mission_progress.get(mission_id, 0)))
		result.append({
			"id": mission_id,
			"title": str(definition.get("title", mission_id)),
			"description": str(definition.get("description", "")),
			"target": target,
			"progress": progress,
			"completed": progress >= target,
			"claimed": bool(daily_mission_claimed.get(mission_id, false)),
			"reward_gold": int(definition.get("reward_gold", 0)),
			"reward_shades": int(definition.get("reward_shades", 0))
		})
	return result

func claim_daily_mission_reward(mission_id: String) -> bool:
	refresh_daily_shop_state()
	if not DAILY_MISSION_DEFINITIONS.has(mission_id) or bool(daily_mission_claimed.get(mission_id, false)):
		return false
	var definition: Dictionary = DAILY_MISSION_DEFINITIONS[mission_id]
	if int(daily_mission_progress.get(mission_id, 0)) < int(definition.get("target", 1)):
		return false
	daily_mission_claimed[mission_id] = true
	profile_gold += int(definition.get("reward_gold", 0))
	shades += int(definition.get("reward_shades", 0))
	save_profile()
	gold_changed.emit(profile_gold)
	shades_changed.emit(shades)
	profile_changed.emit()
	daily_missions_changed.emit()
	if AudioManager:
		AudioManager.play_sfx("upgrade")
	return true

func record_achievement_progress(achievement_id: String, amount: int = 1) -> void:
	if amount <= 0 or not ACHIEVEMENT_DEFINITIONS.has(achievement_id) or bool(achievement_claimed.get(achievement_id, false)):
		return
	var definition: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
	var target: int = int(definition.get("target", 1))
	var current: int = int(achievement_progress.get(achievement_id, 0))
	var updated: int = mini(target, current + amount)
	if updated == current:
		return
	achievement_progress[achievement_id] = updated
	if updated >= target or updated % 10 == 0:
		save_profile()
	achievements_changed.emit()

func get_achievements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for achievement_id in ACHIEVEMENT_DEFINITIONS:
		var definition: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
		var target: int = int(definition.get("target", 1))
		var progress: int = mini(target, int(achievement_progress.get(achievement_id, 0)))
		result.append({
			"id": achievement_id,
			"title": str(definition.get("title", achievement_id)),
			"description": str(definition.get("description", "")),
			"target": target,
			"progress": progress,
			"completed": progress >= target,
			"claimed": bool(achievement_claimed.get(achievement_id, false)),
			"reward_gold": int(definition.get("reward_gold", 0)),
			"reward_shades": int(definition.get("reward_shades", 0))
		})
	return result

func claim_achievement_reward(achievement_id: String) -> bool:
	if not ACHIEVEMENT_DEFINITIONS.has(achievement_id) or bool(achievement_claimed.get(achievement_id, false)):
		return false
	var definition: Dictionary = ACHIEVEMENT_DEFINITIONS[achievement_id]
	if int(achievement_progress.get(achievement_id, 0)) < int(definition.get("target", 1)):
		return false
	achievement_claimed[achievement_id] = true
	profile_gold += int(definition.get("reward_gold", 0))
	shades += int(definition.get("reward_shades", 0))
	save_profile()
	gold_changed.emit(profile_gold)
	shades_changed.emit(shades)
	profile_changed.emit()
	achievements_changed.emit()
	if AudioManager:
		AudioManager.play_sfx("upgrade")
	return true

func get_difficulty_multipliers() -> Dictionary:
	match difficulty:
		"hard":
			return {"enemy_hp": 1.5, "enemy_damage": 1.25, "boss_hp": 1.5, "boss_damage": 1.25, "rewards": 1.25}
		"torment":
			return {"enemy_hp": 2.0, "enemy_damage": 1.5, "boss_hp": 2.0, "boss_damage": 1.5, "rewards": 1.5}
		_:
			return {"enemy_hp": 1.0, "enemy_damage": 1.0, "boss_hp": 1.0, "boss_damage": 1.0, "rewards": 1.0}

func set_difficulty(diff: String) -> void:
	if not ["normal", "hard", "torment"].has(diff):
		return
	difficulty = diff
	save_profile()
	profile_changed.emit()

func set_player_name(new_name: String) -> void:
	player_name = new_name
	save_profile()
	profile_changed.emit()

func star_up_character(char_id: String) -> bool:
	var cur_stars: int = character_stars.get(char_id, 1)
	if cur_stars >= 6:
		return false
	var shard_cost: int = cur_stars * 15
	var gold_cost: int = cur_stars * 800
	var cur_shards: int = character_shards.get(char_id, 0)
	
	if cur_shards >= shard_cost and spend_gold(gold_cost):
		character_shards[char_id] = cur_shards - shard_cost
		character_stars[char_id] = cur_stars + 1
		save_profile()
		profile_changed.emit()
		if AudioManager: AudioManager.play_sfx("upgrade")
		return true
	return false

const EQUIPMENT_SLOTS: Array[String] = ["weapon", "helmet", "armor", "boots", "amulet", "ring"]


func _ensure_starter_gear(persist: bool = true) -> void:
	if _gear_profile_initialized:
		return
	var starter_items := {
		"weapon": "shadow_dagger",
		"helmet": "void_helm",
		"armor": "iron_shield",
		"boots": "ranger_boots",
		"amulet": "ember_amulet",
		"ring": "wraith_ring"
	}
	gear_inventory.clear()
	for slot in starter_items:
		var data := ItemDatabase.get_item(starter_items[slot])
		if not data:
			continue
		var item := ItemInstance.new(data)
		gear_inventory.append(item.to_dict())
		equipped_gear[slot] = item.uid
	_gear_profile_initialized = true
	if persist:
		save_profile()
	profile_changed.emit()

func get_gear_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for item_dict in gear_inventory:
		var item := ItemInstance.from_dict(item_dict)
		if item:
			result.append(item)
	return result

func get_gear_item(uid: String) -> ItemInstance:
	if uid.is_empty():
		return null
	for item_dict in gear_inventory:
		if str(item_dict.get("uid", "")) == uid:
			return ItemInstance.from_dict(item_dict)
	return null

func has_gear_item(item_id: String) -> bool:
	if item_id.is_empty():
		return false
	for item_dict in gear_inventory:
		if str(item_dict.get("item_id", "")) == item_id:
			return true
	return false

func buy_gear_item(item_id: String) -> bool:
	var data := ItemDatabase.get_item(item_id)
	if not data or not EQUIPMENT_SLOTS.has(data.equipment_slot):
		return false
	if has_gear_item(item_id) or data.price <= 0 or profile_gold < data.price:
		return false

	var item := ItemInstance.new(data)
	profile_gold -= data.price
	gear_inventory.append(item.to_dict())
	_gear_profile_initialized = true
	save_profile()
	gold_changed.emit(profile_gold)
	profile_changed.emit()
	if AudioManager:
		AudioManager.play_sfx("upgrade")
	return true


func get_equipped_gear(slot_name: String) -> ItemInstance:
	if not equipped_gear.has(slot_name):
		return null
	return get_gear_item(str(equipped_gear.get(slot_name, "")))

func add_gear_item(item: ItemInstance) -> bool:
	if not item or not item.data or not EQUIPMENT_SLOTS.has(item.data.equipment_slot):
		return false
	for item_dict in gear_inventory:
		if str(item_dict.get("uid", "")) == item.uid:
			return false
	gear_inventory.append(item.to_dict())
	_gear_profile_initialized = true
	save_profile()
	profile_changed.emit()
	return true

func equip_gear_item(uid: String) -> bool:
	var item := get_gear_item(uid)
	if not item or not item.data or not EQUIPMENT_SLOTS.has(item.data.equipment_slot):
		return false
	equipped_gear[item.data.equipment_slot] = item.uid
	save_profile()
	profile_changed.emit()
	return true

func unequip_gear_slot(slot_name: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot_name):
		return false
	if str(equipped_gear.get(slot_name, "")).is_empty():
		return false
	equipped_gear[slot_name] = ""
	save_profile()
	profile_changed.emit()
	return true

func get_equipped_gear_stats() -> Dictionary:
	var totals := {
		"bonus_atk": 0.0,
		"bonus_hp": 0.0,
		"bonus_crit": 0.0,
		"bonus_speed": 0.0,
		"bonus_atk_speed": 0.0
	}
	for slot_name in EQUIPMENT_SLOTS:
		var item := get_equipped_gear(slot_name)
		if not item or not item.data:
			continue
		var level: int = maxi(0, item.upgrade_level)
		totals["bonus_atk"] += item.data.bonus_atk + level
		totals["bonus_hp"] += item.data.bonus_hp + (level * 5.0)
		totals["bonus_crit"] += item.data.bonus_crit + (level * 0.001)
		totals["bonus_speed"] += item.data.bonus_speed + level
		totals["bonus_atk_speed"] += item.data.bonus_atk_speed + (level * 0.005)
	return totals

const GEAR_SET_DEFINITIONS: Dictionary = {
	"abyssal_regalia": {
		"name": "Abyssal Regalia",
		"description": "Void-forged hunter equipment",
		"pieces": 4,
		"bonuses": {
			2: {"bonus_atk": 8.0, "bonus_crit": 0.03},
			4: {"bonus_hp": 40.0, "bonus_crit": 0.05}
		}
	},
	"stormguard": {
		"name": "Stormguard",
		"description": "Storm-charged defensive equipment",
		"pieces": 2,
		"bonuses": {
			2: {"bonus_speed": 10.0, "bonus_atk_speed": 0.08}
		}
	}
}

func get_active_gear_sets() -> Array[Dictionary]:
	var counts: Dictionary = {}
	for slot_name in EQUIPMENT_SLOTS:
		var item := get_equipped_gear(slot_name)
		if not item or not item.data or item.data.gear_set_id.is_empty():
			continue
		counts[item.data.gear_set_id] = int(counts.get(item.data.gear_set_id, 0)) + 1
	var active: Array[Dictionary] = []
	for set_id in GEAR_SET_DEFINITIONS:
		var definition: Dictionary = GEAR_SET_DEFINITIONS[set_id]
		var count: int = int(counts.get(set_id, 0))
		var thresholds: Dictionary = definition.get("bonuses", {})
		var active_threshold := 0
		var active_bonus := {"bonus_atk": 0.0, "bonus_hp": 0.0, "bonus_crit": 0.0, "bonus_speed": 0.0, "bonus_atk_speed": 0.0}
		for threshold in thresholds:
			if count < int(threshold):
				continue
			active_threshold = maxi(active_threshold, int(threshold))
			var threshold_bonus: Dictionary = thresholds[threshold]
			for stat_name in active_bonus:
				active_bonus[stat_name] += float(threshold_bonus.get(stat_name, 0.0))
		active.append({
			"id": set_id,
			"name": str(definition.get("name", set_id)),
			"description": str(definition.get("description", "")),
			"count": count,
			"required": int(definition.get("pieces", 0)),
			"active_threshold": active_threshold,
			"next_threshold": _get_next_gear_set_threshold(thresholds, count),
			"bonus": active_bonus if active_threshold > 0 else {}
		})
	return active

func _get_next_gear_set_threshold(thresholds: Dictionary, count: int) -> int:
	var next_threshold := 0
	for threshold in thresholds:
		var value := int(threshold)
		if value > count and (next_threshold == 0 or value < next_threshold):
			next_threshold = value
	return next_threshold

func get_gear_set_bonus_stats() -> Dictionary:
	var totals := {"bonus_atk": 0.0, "bonus_hp": 0.0, "bonus_crit": 0.0, "bonus_speed": 0.0, "bonus_atk_speed": 0.0}
	for set_info in get_active_gear_sets():
		var bonus: Dictionary = set_info.get("bonus", {})
		for stat_name in totals:
			totals[stat_name] += float(bonus.get(stat_name, 0.0))
	return totals

func get_total_gear_stats() -> Dictionary:
	var totals := get_equipped_gear_stats()
	var set_bonus := get_gear_set_bonus_stats()
	for stat_name in totals:
		totals[stat_name] += float(set_bonus.get(stat_name, 0.0))
	return totals



func get_gear_upgrade_cost(slot_name: String) -> int:
	var item := get_equipped_gear(slot_name)
	if not item or not item.data:
		return 0
	return (item.upgrade_level + 1) * 50 * item.data.tier

func upgrade_equipped_gear(slot_name: String) -> bool:
	if not EQUIPMENT_SLOTS.has(slot_name):
		return false
	var item := get_equipped_gear(slot_name)
	if not item or not item.data:
		return false
	var cost := get_gear_upgrade_cost(slot_name)
	if profile_gold < cost:
		return false
	profile_gold -= cost
	item.upgrade_level += 1
	for index in range(gear_inventory.size()):
		if str(gear_inventory[index].get("uid", "")) == item.uid:
			gear_inventory[index] = item.to_dict()
			break
	save_profile()
	gold_changed.emit(profile_gold)
	profile_changed.emit()
	if AudioManager:
		AudioManager.play_sfx("upgrade")
	return true

func upgrade_equipment_slot(slot_name: String) -> bool:
	var cur_lvl: int = equipment_levels.get(slot_name, 1)
	var cost: int = cur_lvl * 50
	if spend_gold(cost):
		equipment_levels[slot_name] = cur_lvl + 1
		save_profile()
		profile_changed.emit()
		if AudioManager: AudioManager.play_sfx("upgrade")
		return true
	return false

func get_patrol_reward_status() -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var elapsed := now - patrol_last_claim
	var remaining := 0 if patrol_last_claim <= 0 else maxi(0, PATROL_REWARD_COOLDOWN_SECONDS - elapsed)
	return {
		"ready": patrol_last_claim <= 0 or remaining == 0,
		"seconds_remaining": remaining,
		"gold": 1200 + (player_level * 150)
	}

func claim_patrol_rewards() -> Dictionary:
	var status := get_patrol_reward_status()
	if not bool(status.get("ready", false)):
		return {"ready": false, "seconds_remaining": int(status.get("seconds_remaining", 0))}
	var base_gold: int = int(status.get("gold", 0))
	add_gold(base_gold)
	patrol_last_claim = int(Time.get_unix_time_from_system())
	save_profile()
	return {"ready": true, "gold": base_gold}

func get_combat_power_breakdown() -> Dictionary:
	var base_power := 2500 * player_level
	var legacy_gear_power := 0
	for lvl in equipment_levels.values():
		legacy_gear_power += int(lvl) * 45
	var raw_gear_stats: Dictionary = get_equipped_gear_stats()
	var set_stats: Dictionary = get_gear_set_bonus_stats()
	var equipped_gear_power := _calculate_gear_stat_power(raw_gear_stats)
	var set_bonus_power := _calculate_gear_stat_power(set_stats)
	var equipped_stats: Dictionary = get_total_gear_stats()
	var character_power := 0
	for stars in character_stars.values():
		character_power += int(stars) * 650
	var talent_power := 0
	for stars in talent_cards.values():
		talent_power += int(stars) * 400
	return {
		"base": base_power,
		"legacy_gear": legacy_gear_power,
		"equipped_gear": equipped_gear_power,
		"set_bonus": set_bonus_power,
		"character": character_power,
		"talents": talent_power,
		"total": base_power + legacy_gear_power + equipped_gear_power + set_bonus_power + character_power + talent_power,
		"gear_stats": equipped_stats,
		"gear_set_stats": set_stats,
		"active_gear_sets": get_active_gear_sets()
	}

func _calculate_gear_stat_power(stats: Dictionary) -> int:
	return int(
		float(stats.get("bonus_atk", 0.0)) * 20.0
		+ float(stats.get("bonus_hp", 0.0)) * 2.0
		+ float(stats.get("bonus_crit", 0.0)) * 500.0
		+ float(stats.get("bonus_speed", 0.0)) * 2.0
		+ float(stats.get("bonus_atk_speed", 0.0)) * 300.0
	)

func calculate_combat_power() -> int:
	return int(get_combat_power_breakdown().get("total", 0))

const WEB_STORAGE_KEY: String = "dark_summoner_save_profile"
const WEB_RUN_KEY: String = "dark_summoner_run_state"

func _sync_to_web_storage(json_str: String) -> void:
	if OS.has_feature("web"):
		if ClassDB.class_exists("JavaScriptBridge"):
			var js = Engine.get_singleton("JavaScriptBridge")
			if js:
				js.eval("try { window.localStorage.setItem('%s', %s); } catch(e) { console.warn(e); }" % [
					WEB_STORAGE_KEY, JSON.stringify(json_str)
				])

func _load_from_web_storage() -> String:
	if OS.has_feature("web"):
		if ClassDB.class_exists("JavaScriptBridge"):
			var js = Engine.get_singleton("JavaScriptBridge")
			if js:
				var res = js.eval("window.localStorage.getItem('%s') || ''" % WEB_STORAGE_KEY)
				if res is String and not res.is_empty():
					return res
	return ""

func _clear_web_storage() -> void:
	if OS.has_feature("web"):
		if ClassDB.class_exists("JavaScriptBridge"):
			var js = Engine.get_singleton("JavaScriptBridge")
			if js:
				js.eval("try { window.localStorage.removeItem('%s'); window.localStorage.removeItem('%s'); } catch(e) {}" % [
					WEB_STORAGE_KEY, WEB_RUN_KEY
				])

func reset_all_data() -> void:
	# Purge all local user files (guaranteeing player progress and combat power reset)
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

	_clear_web_storage()

	# Reset in-memory state to clean fresh reinstall defaults
	shades = 0
	gems = 150
	energy = 45
	max_energy = 50
	profile_gold = 5000
	player_name = "Hunter Raven"
	player_level = 5
	active_character_id = "shadow_hunter"
	has_completed_initial_character_selection = false
	difficulty = "normal"
	patrol_last_claim = 0
	chapter_stars = { 1: 3, 2: 1, 3: 0 }
	daily_free_energy_claimed = false
	daily_free_energy_claim_date = ""
	daily_shop_date_key = ""
	daily_shop_purchased_items.clear()
	shop_item_inventory.clear()
	daily_mission_progress.clear()
	daily_mission_claimed.clear()
	achievement_progress.clear()
	achievement_claimed.clear()
	chapter_pack_purchased = false
	highest_floor_unlocked = 1
	unlocked_characters = ["shadow_hunter"]
	character_levels = {
		"shadow_hunter": 1,
		"storm_reaper": 1,
		"soul_binder": 1,
		"frost_valkyrie": 1
	}
	character_shards = {
		"shadow_hunter": 45,
		"storm_reaper": 20,
		"soul_binder": 12,
		"frost_valkyrie": 0
	}
	character_stars = {
		"shadow_hunter": 2,
		"storm_reaper": 3,
		"soul_binder": 2,
		"frost_valkyrie": 1
	}
	gear_inventory.clear()
	equipped_gear = {"weapon": "", "helmet": "", "armor": "", "boots": "", "amulet": "", "ring": ""}
	_gear_profile_initialized = false
	equipment_levels = {
		"weapon": 60,
		"amulet": 55,
		"ring": 58,
		"helmet": 60,
		"armor": 60,
		"boots": 55
	}
	talent_cards = {
		"glory": 5,
		"tactics": 4,
		"swift_wind": 3,
		"super_crit": 4,
		"iron_will": 3,
		"vampiric": 3,
		"storm_call": 0,
		"flame_burst": 0
	}
	permanent_upgrades = {
		"max_hp": 0,
		"atk": 0,
		"speed": 0,
		"crit": 0,
		"altar_expand": 0,
		"start_gold": 0,
		"potion_potency": 0
	}
	settings_data = {
		"master_vol": 0.8,
		"music_vol": 0.7,
		"sfx_vol": 0.8,
		"ambience_vol": 0.6,
		"muted": false,
		"screen_shake": true,
		"reduced_motion": false
	}
	_gear_profile_initialized = false
	_ensure_starter_gear(false)
	profile_changed.emit()
	profile_loaded.emit()

func save_profile() -> void:
	# Capture settings
	if AudioManager:
		settings_data["master_vol"] = AudioManager.master_vol
		settings_data["music_vol"] = AudioManager.music_vol
		settings_data["sfx_vol"] = AudioManager.sfx_vol
		settings_data["ambience_vol"] = AudioManager.ambience_vol
		settings_data["muted"] = AudioManager.is_muted

	var data: Dictionary = {
		"version": SAVE_VERSION,
		"shades": shades,
		"gems": gems,
		"energy": energy,
		"max_energy": max_energy,
		"profile_gold": profile_gold,
		"player_name": player_name,
		"player_level": player_level,
		"active_character_id": active_character_id,
		"has_completed_initial_character_selection": has_completed_initial_character_selection,
		"difficulty": difficulty,
		"patrol_last_claim": patrol_last_claim,
		"chapter_stars": chapter_stars,
		"daily_free_energy_claimed": daily_free_energy_claimed,
		"daily_free_energy_claim_date": daily_free_energy_claim_date,
		"daily_shop_date_key": daily_shop_date_key,
		"daily_shop_purchased_items": daily_shop_purchased_items,
		"shop_item_inventory": shop_item_inventory,
		"daily_mission_progress": daily_mission_progress,
		"daily_mission_claimed": daily_mission_claimed,
		"achievement_progress": achievement_progress,
		"achievement_claimed": achievement_claimed,
		"chapter_pack_purchased": chapter_pack_purchased,
		"highest_floor_unlocked": highest_floor_unlocked,
		"unlocked_characters": unlocked_characters,
		"character_levels": character_levels,
		"character_shards": character_shards,
		"character_stars": character_stars,
		"equipment_levels": equipment_levels,
		"gear_inventory": gear_inventory,
		"equipped_gear": equipped_gear,
		"talent_cards": talent_cards,
		"permanent_upgrades": permanent_upgrades,
		"settings": settings_data,
		"combat_power": calculate_combat_power()
	}

	_gear_profile_initialized = true
	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

	# Synchronize state directly to browser/app localStorage if running in web environment
	_sync_to_web_storage(json_str)

func load_profile() -> void:
	var content: String = ""
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			content = file.get_as_text()
			file.close()

	# If running on web and local user file was missing or empty, attempt loading from browser localStorage
	if content.is_empty():
		content = _load_from_web_storage()

	if content.is_empty():
		return
	
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		push_warning("Save file corrupted or invalid format, using defaults.")
		return
	
	var dict: Dictionary = parsed
	shades = dict.get("shades", 0)
	gems = dict.get("gems", max(150, shades))
	energy = dict.get("energy", 45)
	max_energy = dict.get("max_energy", 50)
	profile_gold = dict.get("profile_gold", 5000)
	player_name = dict.get("player_name", "Hunter Raven")
	player_level = dict.get("player_level", 5)
	active_character_id = dict.get("active_character_id", "shadow_hunter")
	has_completed_initial_character_selection = bool(dict.get("has_completed_initial_character_selection", false))
	difficulty = dict.get("difficulty", "normal")
	patrol_last_claim = dict.get("patrol_last_claim", 0)
	daily_free_energy_claimed = bool(dict.get("daily_free_energy_claimed", false))
	daily_free_energy_claim_date = str(dict.get("daily_free_energy_claim_date", ""))
	daily_shop_date_key = str(dict.get("daily_shop_date_key", ""))
	var saved_daily_purchases: Variant = dict.get("daily_shop_purchased_items", {})
	daily_shop_purchased_items = saved_daily_purchases.duplicate(true) if saved_daily_purchases is Dictionary else {}
	var saved_shop_inventory: Variant = dict.get("shop_item_inventory", {})
	shop_item_inventory = saved_shop_inventory.duplicate(true) if saved_shop_inventory is Dictionary else {}
	var saved_mission_progress: Variant = dict.get("daily_mission_progress", {})
	daily_mission_progress = saved_mission_progress.duplicate(true) if saved_mission_progress is Dictionary else {}
	var saved_mission_claimed: Variant = dict.get("daily_mission_claimed", {})
	daily_mission_claimed = saved_mission_claimed.duplicate(true) if saved_mission_claimed is Dictionary else {}
	var saved_achievement_progress: Variant = dict.get("achievement_progress", {})
	achievement_progress = saved_achievement_progress.duplicate(true) if saved_achievement_progress is Dictionary else {}
	var saved_achievement_claimed: Variant = dict.get("achievement_claimed", {})
	achievement_claimed = saved_achievement_claimed.duplicate(true) if saved_achievement_claimed is Dictionary else {}
	chapter_pack_purchased = bool(dict.get("chapter_pack_purchased", false))
	highest_floor_unlocked = dict.get("highest_floor_unlocked", 1)
	
	var ch_stars: Variant = dict.get("chapter_stars", {})
	if ch_stars is Dictionary:
		for k in ch_stars.keys():
			chapter_stars[int(k)] = ch_stars[k]
			
	var c_shards: Variant = dict.get("character_shards", {})
	if c_shards is Dictionary:
		for k in c_shards.keys():
			character_shards[str(k)] = c_shards[k]
			
	var c_stars: Variant = dict.get("character_stars", {})
	if c_stars is Dictionary:
		for k in c_stars.keys():
			character_stars[str(k)] = c_stars[k]
			
	var saved_gear: Variant = dict.get("gear_inventory", null)
	if saved_gear is Array:
		gear_inventory.clear()
		for entry in saved_gear:
			if entry is Dictionary and ItemDatabase.get_item(str(entry.get("item_id", ""))):
				gear_inventory.append(entry.duplicate(true))
		_gear_profile_initialized = true
	var saved_equipped: Variant = dict.get("equipped_gear", {})
	if saved_equipped is Dictionary:
		for slot_name in EQUIPMENT_SLOTS:
			equipped_gear[slot_name] = str(saved_equipped.get(slot_name, ""))
	var eq_lvls: Variant = dict.get("equipment_levels", {})
	if eq_lvls is Dictionary:
		for k in eq_lvls.keys():
			equipment_levels[str(k)] = eq_lvls[k]
			
	var t_cards: Variant = dict.get("talent_cards", {})
	if t_cards is Dictionary:
		for k in t_cards.keys():
			talent_cards[str(k)] = t_cards[k]
	
	var chars: Variant = dict.get("unlocked_characters", ["shadow_hunter"])
	if chars is Array:
		unlocked_characters = []
		for c in chars:
			unlocked_characters.append(str(c))
		if not unlocked_characters.has("shadow_hunter"):
			unlocked_characters.append("shadow_hunter")
			
	var levels: Variant = dict.get("character_levels", {})
	if levels is Dictionary:
		for k in levels.keys():
			character_levels[k] = levels[k]
			
	var upgs: Variant = dict.get("permanent_upgrades", {})
	if upgs is Dictionary:
		for k in upgs.keys():
			permanent_upgrades[k] = upgs[k]
			
	var sett: Variant = dict.get("settings", {})
	if sett is Dictionary:
		for k in sett.keys():
			settings_data[k] = sett[k]
		if AudioManager:
			AudioManager.master_vol = settings_data.get("master_vol", 0.8)
			AudioManager.music_vol = settings_data.get("music_vol", 0.7)
			AudioManager.sfx_vol = settings_data.get("sfx_vol", 0.8)
			AudioManager.ambience_vol = settings_data.get("ambience_vol", 0.6)
			AudioManager.is_muted = settings_data.get("muted", false)
			AudioManager.apply_volumes()
			
	profile_loaded.emit()

# Active Run Inventory & Loadout Persistence
const RUN_SAVE_PATH: String = "user://abyssal_altar_run.json"

func has_active_run_save() -> bool:
	return FileAccess.file_exists(RUN_SAVE_PATH)

func clear_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)

func save_run_state(altar_items: Array[ItemInstance], backpack_items: Array[ItemInstance], floor_num: int = 1, level_num: int = 1, gold: int = 0) -> void:
	var altar_data: Array[Dictionary] = []
	for it in altar_items:
		if it:
			altar_data.append(it.to_dict())
			
	var backpack_data: Array[Dictionary] = []
	for it in backpack_items:
		if it:
			backpack_data.append(it.to_dict())
			
	var payload: Dictionary = {
		"floor": floor_num,
		"level": level_num,
		"gold": gold,
		"altar_items": altar_data,
		"backpack_items": backpack_data
	}
	
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(payload, "\t"))
		file.close()

func load_run_state() -> Dictionary:
	if not FileAccess.file_exists(RUN_SAVE_PATH):
		return {}
	var file := FileAccess.open(RUN_SAVE_PATH, FileAccess.READ)
	if not file:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		return {}
	
	var dict: Dictionary = parsed
	var restored_altar: Array[ItemInstance] = []
	for it_dict in dict.get("altar_items", []):
		var inst := ItemInstance.from_dict(it_dict)
		if inst:
			restored_altar.append(inst)
			
	var restored_backpack: Array[ItemInstance] = []
	for it_dict in dict.get("backpack_items", []):
		var inst := ItemInstance.from_dict(it_dict)
		if inst:
			restored_backpack.append(inst)
			
	return {
		"floor": dict.get("floor", 1),
		"level": dict.get("level", 1),
		"gold": dict.get("gold", 0),
		"altar_items": restored_altar,
		"backpack_items": restored_backpack
	}
