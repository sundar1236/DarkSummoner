class_name CharacterData
extends Resource

# Definition resource for playable dark-fantasy characters in Abyssal Altar.

@export var id: String = "shadow_hunter"
@export var name: String = "Shadow Hunter"
@export var title: String = "The Veiled Blade"
@export_multiline var description: String = "A nimble slayer who strikes from the shadows, building deadly combo velocity."
@export var passive_desc: String = "Consecutive hits increase Attack Speed and Critical Damage."
@export var active_desc: String = "Shadow Flurry: Unleashes a 360-degree radial ring of shadowy blades."

@export var unlocked_by_default: bool = true
@export var unlock_cost_shades: int = 0
@export var unlock_floor_required: int = 1

# Base Stats
@export var base_hp: float = 120.0
@export var base_speed: float = 240.0
@export var base_atk: float = 18.0
@export var base_crit_chance: float = 0.15
@export var base_attack_rate: float = 2.2 # Attacks per second

@export var attack_type: String = "slashes"
@export var primary_color: Color = Color(0.7, 0.2, 0.9)
@export var accent_color: Color = Color(0.95, 0.3, 0.5)

# Active Skill
@export var active_skill_name: String = "Shadow Flurry"
@export var active_skill_cooldown: float = 7.0

# Starter item IDs placed on Altar at run start
@export var starter_item_ids: Array[String] = ["shadow_dagger", "iron_shield"]
