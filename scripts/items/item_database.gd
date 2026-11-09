class_name ItemDatabase
extends RefCounted

# Central registry for all item definitions in Abyssal Altar.

static var _items: Dictionary = {}
static var _initialized: bool = false

static func init_database() -> void:
	if _initialized:
		return
	_initialized = true
	
	# 1. Shadow Dagger (Tier 1 Weapon, 1x1)
	var dagger := ItemData.new()
	dagger.id = "shadow_dagger"
	dagger.name = "Shadow Dagger"
	dagger.description = "A curved obsidian dagger dripping with void essence. Fast and deadly."
	dagger.tier = 1
	dagger.tags = ["weapon", "shadow"]
	dagger.equipment_slot = "weapon"
	dagger.shape = [Vector2i(0, 0)]
	dagger.color = Color(0.7, 0.25, 0.95)
	dagger.icon_symbol = "dagger"
	dagger.bonus_atk = 6.0
	dagger.bonus_crit = 0.08
	dagger.bonus_atk_speed = 0.15
	dagger.merge_into_id = "shadow_blade"
	dagger.price = 25
	_register(dagger)
	
	# 2. Shadow Blade (Tier 2 Weapon, 1x2)
	var blade := ItemData.new()
	blade.id = "shadow_blade"
	blade.name = "Shadow Blade"
	blade.description = "Reforged shadow weapon. Strikes with double sharpness."
	blade.tier = 2
	blade.tags = ["weapon", "shadow"]
	blade.equipment_slot = "weapon"
	blade.shape = [Vector2i(0, 0), Vector2i(0, 1)]
	blade.color = Color(0.85, 0.35, 1.0)
	blade.icon_symbol = "blade"
	blade.bonus_atk = 16.0
	blade.bonus_crit = 0.16
	blade.bonus_atk_speed = 0.25
	blade.merge_into_id = "abyssal_scythe"
	blade.price = 55
	_register(blade)

	# 3. Abyssal Scythe (Tier 3 Weapon, 2x2)
	var scythe := ItemData.new()
	scythe.id = "abyssal_scythe"
	scythe.name = "Abyssal Scythe"
	scythe.description = "Legendary reaper weapon. Slices through souls and drains life."
	scythe.tier = 3
	scythe.tags = ["weapon", "shadow", "relic"]
	scythe.equipment_slot = "weapon"
	scythe.shape = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]
	scythe.color = Color(1.0, 0.2, 0.6)
	scythe.icon_symbol = "scythe"
	scythe.bonus_atk = 35.0
	scythe.bonus_crit = 0.25
	scythe.bonus_atk_speed = 0.3
	scythe.passive_type = "life_steal"
	scythe.price = 120
	_register(scythe)

	# 4. Fire Rune (Tier 1 Rune, 1x1)
	var fire_rune := ItemData.new()
	fire_rune.id = "fire_rune"
	fire_rune.name = "Fire Rune"
	fire_rune.description = "Ancient sigil glowing with hellfire. Causes attacks to burn foes."
	fire_rune.tier = 1
	fire_rune.tags = ["rune", "fire"]
	fire_rune.shape = [Vector2i(0, 0)]
	fire_rune.color = Color(1.0, 0.4, 0.1)
	fire_rune.icon_symbol = "rune_fire"
	fire_rune.bonus_atk = 4.0
	fire_rune.passive_type = "burn_on_hit"
	fire_rune.merge_into_id = "inferno_rune"
	fire_rune.price = 30
	_register(fire_rune)

	# 5. Inferno Rune (Tier 2 Rune, 1x2)
	var inferno_rune := ItemData.new()
	inferno_rune.id = "inferno_rune"
	inferno_rune.name = "Inferno Rune"
	inferno_rune.description = "Twin runes ablaze. Greatly amplifies burn damage and attack power."
	inferno_rune.tier = 2
	inferno_rune.tags = ["rune", "fire"]
	inferno_rune.shape = [Vector2i(0, 0), Vector2i(0, 1)]
	inferno_rune.color = Color(1.0, 0.2, 0.05)
	inferno_rune.icon_symbol = "rune_inferno"
	inferno_rune.bonus_atk = 14.0
	inferno_rune.passive_type = "burn_on_hit"
	inferno_rune.price = 70
	_register(inferno_rune)

	# 6. Wolf Core (Tier 1 Core, 1x1)
	var wolf_core := ItemData.new()
	wolf_core.id = "wolf_core"
	wolf_core.name = "Wolf Core"
	wolf_core.description = "Heart of a shadow beast. Summons a spectral wolf companion."
	wolf_core.tier = 1
	wolf_core.tags = ["core", "beast"]
	wolf_core.shape = [Vector2i(0, 0)]
	wolf_core.color = Color(0.2, 0.8, 0.9)
	wolf_core.icon_symbol = "core_beast"
	wolf_core.bonus_speed = 20.0
	wolf_core.passive_type = "pet"
	wolf_core.merge_into_id = "demon_core"
	wolf_core.price = 40
	_register(wolf_core)

	# 7. Demon Core (Tier 2 Core, 2x1)
	var demon_core := ItemData.new()
	demon_core.id = "demon_core"
	demon_core.name = "Demon Core"
	demon_core.description = "Fiendish powerhouse. Summons a fierce abyssal gargoyle pet."
	demon_core.tier = 2
	demon_core.tags = ["core", "beast", "shadow"]
	demon_core.shape = [Vector2i(0, 0), Vector2i(1, 0)]
	demon_core.color = Color(0.9, 0.1, 0.3)
	demon_core.icon_symbol = "core_demon"
	demon_core.bonus_hp = 30.0
	demon_core.bonus_atk = 10.0
	demon_core.passive_type = "pet"
	demon_core.price = 85
	_register(demon_core)

	# 8. Iron Shield (Tier 1 Armor, 2x1)
	var shield := ItemData.new()
	shield.id = "iron_shield"
	shield.name = "Iron Shield"
	shield.description = "Heavy reinforced guard. Bolsters player maximum health."
	shield.tier = 1
	shield.tags = ["armor", "defense"]
	shield.equipment_slot = "armor"
	shield.shape = [Vector2i(0, 0), Vector2i(1, 0)]
	shield.color = Color(0.5, 0.6, 0.7)
	shield.icon_symbol = "shield"
	shield.bonus_hp = 40.0
	shield.merge_into_id = "void_shield"
	shield.price = 30
	_register(shield)

	# 9. Void Shield (Tier 2 Armor, 2x1)
	var v_shield := ItemData.new()
	v_shield.id = "void_shield"
	v_shield.name = "Void Shield"
	v_shield.description = "Shield laced with null-matter. Massive health and passive ward."
	v_shield.tier = 2
	v_shield.tags = ["armor", "defense", "shadow"]
	v_shield.equipment_slot = "armor"
	v_shield.shape = [Vector2i(0, 0), Vector2i(1, 0)]
	v_shield.color = Color(0.3, 0.35, 0.7)
	v_shield.icon_symbol = "shield_void"
	v_shield.bonus_hp = 90.0
	v_shield.bonus_atk = 5.0
	v_shield.price = 75
	_register(v_shield)

	# 10. Lightning Orb (Tier 1 Relic, 1x1)
	var orb := ItemData.new()
	orb.id = "lightning_orb"
	orb.name = "Lightning Orb"
	orb.description = "Crackling relic. Triggers chain lightning arcs when attacking."
	orb.tier = 1
	orb.tags = ["relic", "lightning"]
	orb.shape = [Vector2i(0, 0)]
	orb.color = Color(0.3, 0.9, 1.0)
	orb.icon_symbol = "orb_lightning"
	orb.bonus_atk_speed = 0.2
	orb.passive_type = "chain_lightning"
	orb.price = 45
	_register(orb)

	# 11. Soul Urn (Tier 1 Relic, 1x1)
	var urn := ItemData.new()
	urn.id = "soul_urn"
	urn.name = "Soul Urn"
	urn.description = "Captures stray souls. Automatically shoots seeking soul missiles."
	urn.tier = 1
	urn.tags = ["relic", "soul"]
	urn.shape = [Vector2i(0, 0)]
	urn.color = Color(0.2, 0.9, 0.6)
	urn.icon_symbol = "urn"
	urn.bonus_crit = 0.1
	urn.passive_type = "auto_projectile"
	urn.price = 40
	_register(urn)

	# 12. Blood Chalice (Tier 1 Relic, 1x1)
	var chalice := ItemData.new()
	chalice.id = "blood_chalice"
	chalice.name = "Blood Chalice"
	chalice.description = "Filled with crimson vitality. Heals HP when enemies are defeated."
	chalice.tier = 1
	chalice.tags = ["relic", "blood"]
	chalice.shape = [Vector2i(0, 0)]
	chalice.color = Color(0.85, 0.1, 0.2)
	chalice.icon_symbol = "chalice"
	chalice.bonus_hp = 25.0
	chalice.passive_type = "life_steal"
	chalice.price = 35
	_register(chalice)

	# Persistent hunter equipment. These are profile gear, separate from run relics.
	var helm := ItemData.new()
	helm.id = "void_helm"
	helm.name = "Void Helm"
	helm.description = "A light helm forged from hardened voidsteel."
	helm.tags = ["gear", "helmet"]
	helm.equipment_slot = "helmet"
	helm.icon_symbol = "helmet"
	helm.bonus_hp = 18.0
	helm.price = 45
	_register(helm)

	var boots := ItemData.new()
	boots.id = "ranger_boots"
	boots.name = "Ranger Boots"
	boots.description = "Flexible boots that improve hunter movement."
	boots.tags = ["gear", "boots"]
	boots.equipment_slot = "boots"
	boots.icon_symbol = "boots"
	boots.bonus_speed = 12.0
	boots.price = 45
	_register(boots)

	var amulet := ItemData.new()
	amulet.id = "ember_amulet"
	amulet.name = "Ember Amulet"
	amulet.description = "An ember-bound charm that sharpens every strike."
	amulet.tags = ["gear", "amulet"]
	amulet.equipment_slot = "amulet"
	amulet.icon_symbol = "amulet"
	amulet.bonus_atk = 5.0
	amulet.bonus_crit = 0.02
	amulet.price = 50
	_register(amulet)

	var ring := ItemData.new()
	ring.id = "wraith_ring"
	ring.name = "Wraith Ring"
	ring.description = "A spectral ring that quickens attacks and critical strikes."
	ring.tags = ["gear", "ring"]
	ring.equipment_slot = "ring"
	ring.icon_symbol = "ring"
	ring.bonus_crit = 0.05
	ring.bonus_atk_speed = 0.05
	ring.price = 50
	_register(ring)

static func _register(data: ItemData) -> void:
	_items[data.id] = data

static func get_item(id: String) -> ItemData:
	init_database()
	if _items.has(id):
		return _items[id]
	return null

static func get_random_item_by_category(category: String, max_tier: int = 1) -> ItemData:
	init_database()
	var candidates: Array[ItemData] = []
	for id in _items:
		var item: ItemData = _items[id]
		if item.tier > max_tier:
			continue
		match category:
			"blacksmith":
				if item.tags.has("weapon") or item.tags.has("armor"):
					candidates.append(item)
			"potion_merchant":
				# merchant category
				if item.tags.has("blood") or item.tags.has("relic"):
					candidates.append(item)
			"relic_merchant":
				if item.tags.has("rune") or item.tags.has("core") or item.tags.has("relic"):
					candidates.append(item)
			_:
				candidates.append(item)
	
	if candidates.is_empty():
		return get_item("shadow_dagger")
	return candidates.pick_random()

static func get_all_items() -> Array[ItemData]:
	init_database()
	var list: Array[ItemData] = []
	for k in _items:
		list.append(_items[k])
	return list
