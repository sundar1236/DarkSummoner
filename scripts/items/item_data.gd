class_name ItemData
extends Resource

# Definition resource for all weapons, runes, monster cores, and relics in Abyssal Altar.

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var tier: int = 1
@export var tags: Array[String] = []

# Footprint cells relative to top-left (0,0). E.g.:
# 1x1: [Vector2i(0,0)]
# 2x1: [Vector2i(0,0), Vector2i(1,0)]
# 1x2: [Vector2i(0,0), Vector2i(0,1)]
# 2x2: [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]
# L-shape: [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)]
@export var shape: Array[Vector2i] = [Vector2i(0, 0)]

@export var color: Color = Color(0.7, 0.4, 0.9)
@export var icon_symbol: String = "dagger"

# Passive & Combat Stats
@export var bonus_atk: float = 0.0
@export var bonus_hp: float = 0.0
@export var bonus_crit: float = 0.0
@export var bonus_speed: float = 0.0
@export var bonus_atk_speed: float = 0.0

# Passive ability type triggered by this item
# Options: "none", "pet", "auto_projectile", "burn_on_hit", "crit_burst", "chain_lightning", "life_steal"
@export var passive_type: String = "none"

# Target Item ID when 2 matching items are merged
@export var merge_into_id: String = ""

# Gold value in shops
@export var price: int = 30

func get_icon_texture() -> Texture2D:
	var path := "res://assets/art/items/item_%s.png" % id
	return TextureLoader.get_texture(path)
