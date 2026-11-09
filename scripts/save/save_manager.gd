extends Node

# Autoload SaveManager for Abyssal Altar
# Manages persistent profile saving, meta-progression, Shades currency, character unlocks, and settings.

const SAVE_PATH: String = "user://abyssal_altar_profile.json"
const SAVE_VERSION: int = 1

signal shades_changed(new_amount: int)
signal energy_changed(current: int, max_val: int)
signal gold_changed(new_amount: int)
signal gems_changed(new_amount: int)
signal profile_changed()
signal profile_loaded()

var shades: int = 0
var gems: int = 150
var energy: int = 45
var max_energy: int = 50
var profile_gold: int = 5000
var player_name: String = "Hunter Raven"
var player_level: int = 5
var active_character_id: String = "shadow_hunter"
var difficulty: String = "normal" # "normal", "hard", "torment"
var patrol_last_claim: int = 0
var chapter_stars: Dictionary = { 1: 3, 2: 1, 3: 0 }
var daily_free_energy_claimed: bool = false
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
	"muted": false
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_profile()

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
	if gems >= amount or shades >= amount:
		gems = max(0, gems - amount)
		shades = max(0, shades - amount)
		save_profile()
		gems_changed.emit(gems)
		shades_changed.emit(shades)
		return true
	return false

func add_gems(amount: int) -> void:
	if amount <= 0:
		return
	gems += amount
	shades += amount
	save_profile()
	gems_changed.emit(gems)
	shades_changed.emit(shades)

func set_difficulty(diff: String) -> void:
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

func claim_patrol_rewards() -> Dictionary:
	var base_gold: int = 1200 + (player_level * 150)
	var base_xp: int = 400 + (player_level * 50)
	add_gold(base_gold)
	patrol_last_claim = int(Time.get_unix_time_from_system())
	save_profile()
	return { "gold": base_gold, "xp": base_xp }

func calculate_combat_power() -> int:
	var base_power := 2500 * player_level
	var gear_power := 0
	for lvl in equipment_levels.values():
		gear_power += int(lvl) * 45
	var star_power := 0
	for stars in character_stars.values():
		star_power += int(stars) * 650
	var card_power := 0
	for stars in talent_cards.values():
		card_power += int(stars) * 400
	return base_power + gear_power + star_power + card_power

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
	difficulty = "normal"
	patrol_last_claim = 0
	chapter_stars = { 1: 3, 2: 1, 3: 0 }
	daily_free_energy_claimed = false
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
		"muted": false
	}
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
		"difficulty": difficulty,
		"patrol_last_claim": patrol_last_claim,
		"chapter_stars": chapter_stars,
		"daily_free_energy_claimed": daily_free_energy_claimed,
		"chapter_pack_purchased": chapter_pack_purchased,
		"highest_floor_unlocked": highest_floor_unlocked,
		"unlocked_characters": unlocked_characters,
		"character_levels": character_levels,
		"character_shards": character_shards,
		"character_stars": character_stars,
		"equipment_levels": equipment_levels,
		"talent_cards": talent_cards,
		"permanent_upgrades": permanent_upgrades,
		"settings": settings_data,
		"combat_power": calculate_combat_power()
	}

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
	difficulty = dict.get("difficulty", "normal")
	patrol_last_claim = dict.get("patrol_last_claim", 0)
	daily_free_energy_claimed = dict.get("daily_free_energy_claimed", false)
	chapter_pack_purchased = dict.get("chapter_pack_purchased", false)
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
