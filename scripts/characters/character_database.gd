class_name CharacterDatabase
extends RefCounted

# Central registry for playable characters in Abyssal Altar.

static var _characters: Dictionary = {}
static var _initialized: bool = false

static func init_database() -> void:
	if _initialized:
		return
	_initialized = true

	# 1. Shadow Hunter (Default)
	var hunter := CharacterData.new()
	hunter.id = "shadow_hunter"
	hunter.name = "Shadow Hunter"
	hunter.title = "The Veiled Blade"
	hunter.description = "A swift assassin of the abyss. Excels in rapid consecutive strikes and deadly critical strikes."
	hunter.passive_desc = "Flurry Instinct: Consecutive attacks grant +25% Attack Speed and +10% Crit Chance."
	hunter.active_desc = "Shadow Flurry: Unleashes an explosive ring of 8 piercing obsidian blades in all directions."
	hunter.unlocked_by_default = true
	hunter.unlock_cost_shades = 0
	hunter.unlock_floor_required = 1
	hunter.base_hp = 120.0
	hunter.base_speed = 250.0
	hunter.base_atk = 18.0
	hunter.base_crit_chance = 0.15
	hunter.base_attack_rate = 2.4
	hunter.attack_type = "slashes"
	hunter.primary_color = Color(0.68, 0.28, 0.95)
	hunter.accent_color = Color(0.98, 0.35, 0.65)
	hunter.active_skill_name = "Shadow Flurry"
	hunter.active_skill_cooldown = 6.0
	hunter.starter_item_ids = ["shadow_dagger", "fire_rune"]
	_characters[hunter.id] = hunter

	# 2. Storm Reaper (Progression Unlock)
	var reaper := CharacterData.new()
	reaper.id = "storm_reaper"
	reaper.name = "Storm Reaper"
	reaper.title = "Herald of the Tempest"
	reaper.description = "Wields raw celestial lightning. Dominates battlefields with high-burst voltage and area shocks."
	reaper.passive_desc = "Static Discharge: Every 4th attack unleashes an electric shockwave hitting nearby targets."
	reaper.active_desc = "Chain Lightning: Strikes target area with devastating lightning that bounces between 5 enemies."
	reaper.unlocked_by_default = false
	reaper.unlock_cost_shades = 40
	reaper.unlock_floor_required = 2
	reaper.base_hp = 105.0
	reaper.base_speed = 230.0
	reaper.base_atk = 24.0
	reaper.base_crit_chance = 0.10
	reaper.base_attack_rate = 1.8
	reaper.attack_type = "lightning_bolts"
	reaper.primary_color = Color(0.2, 0.75, 1.0)
	reaper.accent_color = Color(0.85, 0.95, 1.0)
	reaper.active_skill_name = "Chain Lightning"
	reaper.active_skill_cooldown = 7.5
	reaper.starter_item_ids = ["lightning_orb", "iron_shield"]
	_characters[reaper.id] = reaper

	# 3. Soul Binder (Special Unlock)
	var binder := CharacterData.new()
	binder.id = "soul_binder"
	binder.name = "Soul Binder"
	binder.title = "The Undying Conduit"
	binder.description = "Commands spectral entities and soul familiars. Synergizes massively with altar companions."
	binder.passive_desc = "Necrotic Bond: Summons and pets deal +40% damage, and 15% of pet damage heals the player."
	binder.active_desc = "Soul Swarm: Conjures a swarm of 6 seeking abyssal wisps that home in on foes."
	binder.unlocked_by_default = false
	binder.unlock_cost_shades = 80
	binder.unlock_floor_required = 3
	binder.base_hp = 140.0
	binder.base_speed = 210.0
	binder.base_atk = 15.0
	binder.base_crit_chance = 0.08
	binder.base_attack_rate = 1.6
	binder.attack_type = "soul_missiles"
	binder.primary_color = Color(0.18, 0.85, 0.55)
	binder.accent_color = Color(0.4, 1.0, 0.8)
	binder.active_skill_name = "Soul Swarm"
	binder.active_skill_cooldown = 8.0
	binder.starter_item_ids = ["wolf_core", "soul_urn"]
	_characters[binder.id] = binder

static func get_character(id: String) -> CharacterData:
	init_database()
	if _characters.has(id):
		return _characters[id]
	return _characters["shadow_hunter"]

static func get_all_characters() -> Array[CharacterData]:
	init_database()
	var list: Array[CharacterData] = []
	for k in _characters:
		list.append(_characters[k])
	return list
