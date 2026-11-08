class_name RunSkillData
extends Resource

# Definition resource for an in-run blessing skill offered during Valkyrie drafts.
# Supports 1-3 upgrade ranks, distinct dark-fantasy rarities, real stat modifications,
# and visual card presentation details.

@export var id: String = ""
@export var name: String = ""
@export var rarity: String = "rare" # "rare", "epic", "legendary"
@export var tier: int = 1 # 1: Rare, 2: Epic, 3: Legendary
@export var icon_symbol: String = "🗡"
@export var max_level: int = 3
@export var stat_type: String = "atk" # "atk", "chain_lightning", "burn", "hp", "life_steal", "speed", "pet", "crit"

# Array of dictionaries, one per rank (index 0 = Rank 1, index 1 = Rank 2, index 2 = Rank 3)
# Keys: "desc", "stat_arrow", "mods" (Dictionary of stat multipliers or additions)
@export var ranks: Array[Dictionary] = []

func get_rank_info(level: int) -> Dictionary:
	var idx := clampi(level - 1, 0, ranks.size() - 1)
	if ranks.is_empty():
		return {
			"desc": "Empowers combat prowess.",
			"stat_arrow": "ATK PWR ↑↑",
			"mods": {"bonus_atk": 10.0}
		}
	return ranks[idx]

func get_border_color() -> Color:
	match rarity:
		"legendary": return Color(1.0, 0.85, 0.25, 1.0) # Gold
		"epic": return Color(0.82, 0.38, 1.0, 1.0) # Purple
		_: return Color(0.28, 0.78, 1.0, 1.0) # Cyan
