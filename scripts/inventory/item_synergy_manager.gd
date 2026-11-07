class_name ItemSynergyManager
extends RefCounted

# Evaluates all active stats, adjacency bonuses, and tag-set synergies on the Altar.
# Reserve backpack items are strictly excluded.

# Active synergy descriptions for UI display
# Each entry: { "id": String, "title": String, "desc": String, "active": bool, "reason": String }
static func evaluate_synergies(altar_items: Array[ItemInstance], grid_mgr: GridManager) -> Dictionary:
	var total_atk: float = 0.0
	var total_hp: float = 0.0
	var total_crit: float = 0.0
	var total_speed: float = 0.0
	var total_atk_speed: float = 0.0
	
	var tag_counts: Dictionary = {}
	var passive_types: Array[String] = []
	var active_synergies: Array[Dictionary] = []
	var pets: Array[Dictionary] = []
	
	# 1. Tally raw item stats & tags
	for item in altar_items:
		if not item.data:
			continue
		total_atk += item.data.bonus_atk
		total_hp += item.data.bonus_hp
		total_crit += item.data.bonus_crit
		total_speed += item.data.bonus_speed
		total_atk_speed += item.data.bonus_atk_speed
		
		if item.data.passive_type != "none":
			passive_types.append(item.data.passive_type)
			
		for t in item.data.tags:
			tag_counts[t] = tag_counts.get(t, 0) + 1
			
	# 2. Check Adjacency Synergies
	var has_hellhound: bool = false
	var has_flame_blade: bool = false
	var has_vampiric_aegis: bool = false
	
	for item in altar_items:
		if not item.data:
			continue
		var adjacents := grid_mgr.get_adjacent_items(item, altar_items)
		
		# Hellhound Evolution: Fire Rune adjacent to Wolf Core
		if item.data.id == "wolf_core":
			for adj in adjacents:
				if adj.data and (adj.data.id == "fire_rune" or adj.data.id == "inferno_rune"):
					has_hellhound = true
					
		# Flame Blade: Weapon adjacent to Fire/Inferno Rune
		if item.data.tags.has("weapon"):
			for adj in adjacents:
				if adj.data and adj.data.tags.has("fire"):
					has_flame_blade = true
					
		# Vampiric Aegis: Armor adjacent to Blood Chalice
		if item.data.tags.has("armor"):
			for adj in adjacents:
				if adj.data and adj.data.id == "blood_chalice":
					has_vampiric_aegis = true

	# Apply adjacency synergy effects
	if has_hellhound:
		active_synergies.append({
			"id": "hellhound_evolution",
			"title": "Hellhound Evolution",
			"desc": "Spectral wolf transforms into a blazing Hellhound dealing 2.5x damage with fiery explosions.",
			"reason": "Fire Rune adjacent to Wolf Core"
		})
		total_atk += 8.0
		
	if has_flame_blade:
		active_synergies.append({
			"id": "flame_blade",
			"title": "Flame-Infused Edge",
			"desc": "Weapon strikes ignite enemies, inflicting +12 bonus fire damage.",
			"reason": "Weapon adjacent to Fire Rune"
		})
		total_atk += 6.0
		
	if has_vampiric_aegis:
		active_synergies.append({
			"id": "vampiric_aegis",
			"title": "Vampiric Aegis",
			"desc": "Armor channels dark blood: +35 Max HP and recovers 5 HP per enemy slain.",
			"reason": "Armor adjacent to Blood Chalice"
		})
		total_hp += 35.0

	# 3. Check Tag-Set Synergies
	# Shadow Mastery: 2+ shadow items
	if tag_counts.get("shadow", 0) >= 2:
		active_synergies.append({
			"id": "shadow_mastery",
			"title": "Shadow Mastery (%d/2)" % tag_counts["shadow"],
			"desc": "Void alignment grants +15% Critical Chance and strikes summon shadow sparks.",
			"reason": "2+ Shadow items equipped"
		})
		total_crit += 0.15

	# Runic Resonance: 2+ rune items
	if tag_counts.get("rune", 0) >= 2:
		active_synergies.append({
			"id": "runic_resonance",
			"title": "Runic Resonance (%d/2)" % tag_counts["rune"],
			"desc": "Ancient symbols harmonize: +20% Attack Damage.",
			"reason": "2+ Runes equipped"
		})
		total_atk *= 1.20

	# Storm Conduit: 2+ lightning items
	if tag_counts.get("lightning", 0) >= 2:
		active_synergies.append({
			"id": "storm_conduit",
			"title": "Storm Conduit (%d/2)" % tag_counts["lightning"],
			"desc": "Constant electric aura discharges lightning arcs to surrounding enemies.",
			"reason": "2+ Lightning items equipped"
		})

	# Beast Master: 2+ beast/core items
	if tag_counts.get("beast", 0) >= 2 or tag_counts.get("core", 0) >= 2:
		var c: int = max(tag_counts.get("beast", 0), tag_counts.get("core", 0))
		active_synergies.append({
			"id": "beast_master",
			"title": "Beast Master (%d/2)" % c,
			"desc": "Companions attack 35% faster and gain +30% movement speed.",
			"reason": "2+ Cores equipped"
		})

	# 4. Determine Active Pets
	for item in altar_items:
		if not item.data:
			continue
		if item.data.id == "wolf_core":
			pets.append({
				"id": "hellhound" if has_hellhound else "wolf",
				"name": "Hellhound" if has_hellhound else "Spectral Wolf",
				"damage": 22.0 if has_hellhound else 10.0,
				"attack_rate": 1.4,
				"color": Color(1.0, 0.35, 0.1) if has_hellhound else Color(0.3, 0.8, 1.0)
			})
		elif item.data.id == "demon_core":
			pets.append({
				"id": "demon",
				"name": "Abyssal Fiend",
				"damage": 18.0,
				"attack_rate": 1.2,
				"color": Color(0.9, 0.2, 0.3)
			})

	# 5. Pack everything into summary dict
	return {
		"total_atk": total_atk,
		"total_hp": total_hp,
		"total_crit": total_crit,
		"total_speed": total_speed,
		"total_atk_speed": total_atk_speed,
		"pets": pets,
		"has_hellhound": has_hellhound,
		"has_flame_blade": has_flame_blade,
		"has_vampiric_aegis": has_vampiric_aegis,
		"has_shadow_mastery": tag_counts.get("shadow", 0) >= 2,
		"has_storm_conduit": tag_counts.get("lightning", 0) >= 2,
		"has_auto_projectile": passive_types.has("auto_projectile"),
		"has_chain_lightning": passive_types.has("chain_lightning") or tag_counts.get("lightning", 0) >= 2,
		"has_burn_on_hit": passive_types.has("burn_on_hit") or has_flame_blade,
		"has_life_steal": passive_types.has("life_steal") or has_vampiric_aegis,
		"active_synergies": active_synergies
	}
