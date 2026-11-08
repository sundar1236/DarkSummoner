class_name RunSkillDatabase
extends RefCounted

# Central registry for in-run Valkyrie blessing skills.
# Provides offer generation, rank validation, max-level filtering,
# deterministic seed support for automated testing, and fallback blessings.

static var _skills: Dictionary = {}
static var _initialized: bool = false

static func init_database() -> void:
	if _initialized:
		return
	_initialized = true
	
	# 1. Shadow Flurry (Legendary)
	var s_flurry := RunSkillData.new()
	s_flurry.id = "shadow_flurry"
	s_flurry.name = "Shadow Flurry"
	s_flurry.rarity = "legendary"
	s_flurry.tier = 3
	s_flurry.icon_symbol = "🗡"
	s_flurry.max_level = 3
	s_flurry.stat_type = "atk"
	s_flurry.ranks = [
		{
			"desc": "Unleashes 2 extra piercing obsidian blades with every combo swing.",
			"stat_arrow": "ATK PWR ↑↑↑↑",
			"mods": {"bonus_atk": 15.0, "bonus_atk_speed": 0.15, "extra_projectiles": 1}
		},
		{
			"desc": "Fires 4 extra piercing blades and widens projectile arc by 30%.",
			"stat_arrow": "ATK PWR ↑↑↑↑↑",
			"mods": {"bonus_atk": 30.0, "bonus_atk_speed": 0.30, "extra_projectiles": 2}
		},
		{
			"desc": "Mastery: Blade storm creates an explosive 8-blade nova on every 3rd strike.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"bonus_atk": 50.0, "bonus_atk_speed": 0.45, "extra_projectiles": 4}
		}
	]
	_register(s_flurry)
	
	# 2. Thunder Tempest (Epic)
	var s_thunder := RunSkillData.new()
	s_thunder.id = "thunder_tempest"
	s_thunder.name = "Thunder Tempest"
	s_thunder.rarity = "epic"
	s_thunder.tier = 2
	s_thunder.icon_symbol = "⚡"
	s_thunder.max_level = 3
	s_thunder.stat_type = "chain_lightning"
	s_thunder.ranks = [
		{
			"desc": "Calls down fork lightning every 3s, arcing across 3 nearby enemies.",
			"stat_arrow": "LIGHTNING PWR ↑↑↑",
			"mods": {"chain_lightning": true, "bonus_crit": 0.08}
		},
		{
			"desc": "Lightning strikes 5 targets, dealing +50% shock damage with brief stun.",
			"stat_arrow": "LIGHTNING PWR ↑↑↑↑",
			"mods": {"chain_lightning": true, "bonus_crit": 0.16, "bonus_atk": 12.0}
		},
		{
			"desc": "Mastery: Fork lightning strikes twice per burst with guaranteed critical hits.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"chain_lightning": true, "bonus_crit": 0.25, "bonus_atk": 25.0}
		}
	]
	_register(s_thunder)
	
	# 3. Hellfire Infusion (Rare)
	var s_fire := RunSkillData.new()
	s_fire.id = "hellfire_infusion"
	s_fire.name = "Hellfire Infusion"
	s_fire.rarity = "rare"
	s_fire.tier = 1
	s_fire.icon_symbol = "🔥"
	s_fire.max_level = 3
	s_fire.stat_type = "burn"
	s_fire.ranks = [
		{
			"desc": "Attacks ignite enemies, dealing burning damage over 3 seconds.",
			"stat_arrow": "BURN DMG ↑↑",
			"mods": {"burn_on_hit": true, "bonus_atk": 6.0}
		},
		{
			"desc": "Burn damage doubled; burning targets deal 20% reduced contact damage.",
			"stat_arrow": "BURN DMG ↑↑↑",
			"mods": {"burn_on_hit": true, "bonus_atk": 14.0}
		},
		{
			"desc": "Mastery: Slaying a burning foe triggers a scorching fiery detonation.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"burn_on_hit": true, "bonus_atk": 25.0}
		}
	]
	_register(s_fire)
	
	# 4. Void Aegis (Epic)
	var s_aegis := RunSkillData.new()
	s_aegis.id = "void_aegis"
	s_aegis.name = "Void Aegis"
	s_aegis.rarity = "epic"
	s_aegis.tier = 2
	s_aegis.icon_symbol = "🛡"
	s_aegis.max_level = 3
	s_aegis.stat_type = "hp"
	s_aegis.ranks = [
		{
			"desc": "Null-matter ward increases Max HP by +40 and absorbs 15% incoming damage.",
			"stat_arrow": "DEF & HP ↑↑↑",
			"mods": {"bonus_hp": 40.0}
		},
		{
			"desc": "Increases Max HP by +80 and reflects 25% absorbed damage back to attackers.",
			"stat_arrow": "DEF & HP ↑↑↑↑",
			"mods": {"bonus_hp": 80.0, "bonus_atk": 8.0}
		},
		{
			"desc": "Mastery: Grants an arcane shield that completely negates one fatal hit per floor.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"bonus_hp": 130.0, "bonus_atk": 16.0, "extra_revive": 1}
		}
	]
	_register(s_aegis)
	
	# 5. Blood Harvest (Rare)
	var s_blood := RunSkillData.new()
	s_blood.id = "blood_harvest"
	s_blood.name = "Blood Harvest"
	s_blood.rarity = "rare"
	s_blood.tier = 1
	s_blood.icon_symbol = "🩸"
	s_blood.max_level = 3
	s_blood.stat_type = "life_steal"
	s_blood.ranks = [
		{
			"desc": "Defeating enemies restores 5 HP and grants +10% move speed for 2 seconds.",
			"stat_arrow": "SUSTAIN & SPD ↑↑",
			"mods": {"life_steal": true, "hp_on_kill": 5.0}
		},
		{
			"desc": "HP restore increased to 10 per kill; weapon strikes siphon 8% life.",
			"stat_arrow": "LIFE STEAL ↑↑↑",
			"mods": {"life_steal": true, "hp_on_kill": 10.0, "bonus_atk": 10.0}
		},
		{
			"desc": "Mastery: Defeating elite monsters or bosses instantly restores 30% Max HP.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"life_steal": true, "hp_on_kill": 18.0, "bonus_atk": 20.0}
		}
	]
	_register(s_blood)
	
	# 6. Phantom Dash (Rare)
	var s_dash := RunSkillData.new()
	s_dash.id = "phantom_dash"
	s_dash.name = "Phantom Dash"
	s_dash.rarity = "rare"
	s_dash.tier = 1
	s_dash.icon_symbol = "💨"
	s_dash.max_level = 3
	s_dash.stat_type = "speed"
	s_dash.ranks = [
		{
			"desc": "Reduces dodge cooldown by 25% and increases movement speed by +35.",
			"stat_arrow": "AGILITY & SPD ↑↑↑",
			"mods": {"bonus_speed": 35.0, "dodge_cdr": 0.25}
		},
		{
			"desc": "Dodge leaves behind a shadow decoy that draws enemy attacks and explodes.",
			"stat_arrow": "AGILITY & SPD ↑↑↑↑",
			"mods": {"bonus_speed": 60.0, "dodge_cdr": 0.40}
		},
		{
			"desc": "Mastery: Dodging through enemies executes an instant counter-cleave.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"bonus_speed": 85.0, "dodge_cdr": 0.55, "bonus_atk": 15.0}
		}
	]
	_register(s_dash)
	
	# 7. Spectral Prowler (Epic)
	var s_pet := RunSkillData.new()
	s_pet.id = "spectral_prowler"
	s_pet.name = "Spectral Prowler"
	s_pet.rarity = "epic"
	s_pet.tier = 2
	s_pet.icon_symbol = "🐺"
	s_pet.max_level = 3
	s_pet.stat_type = "pet"
	s_pet.ranks = [
		{
			"desc": "Summons a spectral wolf companion that hunts and bites nearby foes.",
			"stat_arrow": "PET COMPANION ↑↑↑",
			"mods": {"pet": true, "pet_damage": 15.0}
		},
		{
			"desc": "Companion attacks 40% faster and inflicts vulnerable armor break.",
			"stat_arrow": "PET COMPANION ↑↑↑↑",
			"mods": {"pet": true, "pet_damage": 30.0, "bonus_atk": 10.0}
		},
		{
			"desc": "Mastery: Summons a twin spectral hellhound; companions heal you on strike.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"pet": true, "pet_damage": 50.0, "bonus_atk": 20.0}
		}
	]
	_register(s_pet)
	
	# 8. Death Perception (Legendary)
	var s_crit := RunSkillData.new()
	s_crit.id = "death_perception"
	s_crit.name = "Death Perception"
	s_crit.rarity = "legendary"
	s_crit.tier = 3
	s_crit.icon_symbol = "💀"
	s_crit.max_level = 3
	s_crit.stat_type = "crit"
	s_crit.ranks = [
		{
			"desc": "Increases Critical Chance by +15% and Critical Strike Damage by +40%.",
			"stat_arrow": "CRIT PWR ↑↑↑↑",
			"mods": {"bonus_crit": 0.15, "bonus_atk": 12.0}
		},
		{
			"desc": "Critical strikes cause enemies to bleed profusely for 50% extra damage.",
			"stat_arrow": "CRIT PWR ↑↑↑↑↑",
			"mods": {"bonus_crit": 0.28, "bonus_atk": 25.0}
		},
		{
			"desc": "Mastery: Consecutive critical hits grant unstoppable frenzy velocity.",
			"stat_arrow": "MAX MASTERY ★★★",
			"mods": {"bonus_crit": 0.40, "bonus_atk": 45.0, "bonus_atk_speed": 0.35}
		}
	]
	_register(s_crit)

static func _register(skill: RunSkillData) -> void:
	_skills[skill.id] = skill

static func get_skill(id: String) -> RunSkillData:
	init_database()
	if _skills.has(id):
		return _skills[id]
	return null

static func get_all_skills() -> Array[RunSkillData]:
	init_database()
	var list: Array[RunSkillData] = []
	for k in _skills:
		list.append(_skills[k])
	return list

# Generates 2 valid skill offers respecting max levels, learned progression,
# and deterministic seed (when testing).
static func generate_offers(learned_skills: Dictionary, count: int = 2, seed_val: int = -1) -> Array[Dictionary]:
	init_database()
	var candidates: Array[RunSkillData] = []
	
	for s_id in _skills:
		var skill: RunSkillData = _skills[s_id]
		var cur_lvl: int = learned_skills.get(s_id, 0)
		if cur_lvl < skill.max_level:
			candidates.append(skill)
			
	if candidates.is_empty():
		# Fallback boon if player has fully mastered all skills in the run
		return [
			{
				"skill": null,
				"id": "valkyrie_boon",
				"name": "Celestial Recovery",
				"rarity": "legendary",
				"tier": 3,
				"icon_symbol": "✨",
				"is_new": false,
				"is_fallback": true,
				"current_level": 3,
				"target_level": 3,
				"title": "Celestial Recovery",
				"desc": "Mastery Achieved! Restores 100% Player HP and grants +150 Run Gold.",
				"stat_arrow": "FULL RESTORE & +150🪙",
				"border_color": Color(1.0, 0.85, 0.25, 1.0)
			},
			{
				"skill": null,
				"id": "abyssal_tithe",
				"name": "Abyssal Tithe",
				"rarity": "legendary",
				"tier": 3,
				"icon_symbol": "💎",
				"is_new": false,
				"is_fallback": true,
				"current_level": 3,
				"target_level": 3,
				"title": "Abyssal Tithe",
				"desc": "Converts excess divine favor into +25 Permanent Run Shades.",
				"stat_arrow": "+25 SHADES 🔮",
				"border_color": Color(0.85, 0.45, 1.0, 1.0)
			}
		]
	
	# Deterministic or randomized shuffle
	var pool := candidates.duplicate()
	if seed_val >= 0:
		# Deterministic pseudo-random shuffle for test reproducibility
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		for i in range(pool.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = pool[i]
			pool[i] = pool[j]
			pool[j] = tmp
	else:
		pool.shuffle()
		
	var offers: Array[Dictionary] = []
	var selected_count := mini(count, pool.size())
	
	for i in range(selected_count):
		var skill: RunSkillData = pool[i]
		var cur_lvl: int = learned_skills.get(skill.id, 0)
		var target_lvl := cur_lvl + 1
		var rank_info := skill.get_rank_info(target_lvl)
		var is_new := (cur_lvl == 0)
		
		var title_str := skill.name
		if not is_new:
			title_str = "%s (Rank %d)" % [skill.name, target_lvl]
			
		offers.append({
			"skill": skill,
			"id": skill.id,
			"name": skill.name,
			"title": title_str,
			"rarity": skill.rarity,
			"tier": skill.tier,
			"icon_symbol": skill.icon_symbol,
			"is_new": is_new,
			"is_fallback": false,
			"current_level": cur_lvl,
			"target_level": target_lvl,
			"desc": rank_info.get("desc", ""),
			"stat_arrow": rank_info.get("stat_arrow", "ATK PWR ↑↑"),
			"mods": rank_info.get("mods", {}),
			"border_color": skill.get_border_color()
		})
		
	# If only 1 candidate remains, duplicate or add fallback to ensure exactly 2 cards
	if offers.size() == 1:
		offers.append({
			"skill": null,
			"id": "valkyrie_boon",
			"name": "Celestial Recovery",
			"rarity": "legendary",
			"tier": 3,
			"icon_symbol": "✨",
			"is_new": false,
			"is_fallback": true,
			"current_level": 1,
			"target_level": 1,
			"title": "Celestial Recovery",
			"desc": "Restores 100% Player HP and grants +100 Run Gold.",
			"stat_arrow": "HEAL & +100🪙",
			"border_color": Color(1.0, 0.85, 0.25, 1.0)
		})
		
	return offers
