extends Node

# Autoload SaveManager for Abyssal Altar
# Manages persistent profile saving, meta-progression, Shades currency, character unlocks, and settings.

const SAVE_PATH: String = "user://abyssal_altar_profile.json"
const SAVE_VERSION: int = 1

signal shades_changed(new_amount: int)
signal profile_loaded()

var shades: int = 0
var highest_floor_unlocked: int = 1
var unlocked_characters: Array[String] = ["shadow_hunter"]
var character_levels: Dictionary = {
	"shadow_hunter": 1,
	"storm_reaper": 1,
	"soul_binder": 1
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
		"highest_floor_unlocked": highest_floor_unlocked,
		"unlocked_characters": unlocked_characters,
		"character_levels": character_levels,
		"permanent_upgrades": permanent_upgrades,
		"settings": settings_data
	}

	var json_str := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
		file.close()

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	
	var content := file.get_as_text()
	file.close()
	
	var parsed: Variant = JSON.parse_string(content)
	if not (parsed is Dictionary):
		push_warning("Save file corrupted or invalid format, using defaults.")
		return
	
	var dict: Dictionary = parsed
	shades = dict.get("shades", 0)
	highest_floor_unlocked = dict.get("highest_floor_unlocked", 1)
	
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
