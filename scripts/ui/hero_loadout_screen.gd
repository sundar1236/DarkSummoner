class_name HeroLoadoutScreen
extends Control

# Hero Loadout Screen (Screen B - Ref Images 4, 5, 6)
# Houses the 3 sub-tabs: Characters (0), Gear (1), Runes / Summoning Circle (2).

signal back_requested()
signal character_changed(char_id: String)
signal star_up_requested(char_id: String)
signal blacksmith_requested()
signal rune_workshop_requested()

@export var active_subtab: int = 1 # Default to Gear or Runes

# Subtab Buttons
@onready var btn_sub_characters: Button = $SubTabHeader/HBox/BtnCharacters
@onready var btn_sub_gear: Button = $SubTabHeader/HBox/BtnGear
@onready var btn_sub_runes: Button = $SubTabHeader/HBox/BtnRunes

# View containers for top half
@onready var view_characters: Control = $ContentContainer/ViewCharacters
@onready var view_gear: Control = $ContentContainer/ViewGear
@onready var view_runes: Control = $ContentContainer/ViewRunes

# Pedestals
@onready var char_pedestal: HeroPedestalView = $ContentContainer/ViewCharacters/TopHalf/PedestalContainer/HeroPedestal
@onready var gear_pedestal: HeroPedestalView = $ContentContainer/ViewGear/TopHalf/CenterHero/HeroPedestal
@onready var char_name_badge: Label = $ContentContainer/ViewCharacters/TopHalf/PedestalContainer/HeroNameBadge
@onready var star_rating_row: Label = $ContentContainer/ViewCharacters/TopHalf/PedestalContainer/StarRatingRow

# Stat Pill
@onready var stat_atk_label: Label = $ContentContainer/ViewGear/TopHalf/StatPill/HBox/Atk
@onready var stat_hp_label: Label = $ContentContainer/ViewGear/TopHalf/StatPill/HBox/Hp

# Skill List Labels
@onready var skill_lbl_1: Label = $ContentContainer/ViewCharacters/TopHalf/SkillCardContainer/VBox/Scroll/SkillList/Skill1
@onready var skill_lbl_2: Label = $ContentContainer/ViewCharacters/TopHalf/SkillCardContainer/VBox/Scroll/SkillList/Skill2
@onready var skill_lbl_3: Label = $ContentContainer/ViewCharacters/TopHalf/SkillCardContainer/VBox/Scroll/SkillList/Skill3
@onready var skill_lbl_4: Label = $ContentContainer/ViewCharacters/TopHalf/SkillCardContainer/VBox/Scroll/SkillList/Skill4

# Character Roster Cards
@onready var ribbon_hunter: Label = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardHunter/VBox/Ribbon
@onready var ribbon_reaper: Label = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardReaper/VBox/Ribbon
@onready var ribbon_binder: Label = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardBinder/VBox/Ribbon
@onready var ribbon_valkyrie: Label = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardValkyrie/VBox/Ribbon

@onready var btn_star_up_hunter: Button = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardHunter/VBox/StarUpBtn
@onready var btn_select_reaper: Button = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardReaper/VBox/SelectBtn
@onready var btn_select_binder: Button = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardBinder/VBox/SelectBtn
@onready var btn_unlock_valkyrie: Button = $ContentContainer/ViewCharacters/BottomRoster/Grid/CardValkyrie/VBox/UnlockBtn

var current_char_id: String = "shadow_hunter"
var hunter_stars: int = 2
var base_display_atk: int = 4280
var base_display_hp: int = 18920
var _toast_label: Label = null

func _ready() -> void:
	if btn_sub_characters:
		btn_sub_characters.pressed.connect(func(): _switch_subtab(0))
	if btn_sub_gear:
		btn_sub_gear.pressed.connect(func(): _switch_subtab(1))
	if btn_sub_runes:
		btn_sub_runes.pressed.connect(func(): _switch_subtab(2))
		
	var btn_blacksmith := $ContentContainer/ViewGear/MiddleBar/BlacksmithBtn as Button
	if btn_blacksmith:
		btn_blacksmith.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("🔨 Blacksmith: Equipment Forge ready!")
			blacksmith_requested.emit()
		)
		
	var btn_workshop := $ContentContainer/ViewRunes/MiddleBar/WorkshopBtn as Button
	if btn_workshop:
		btn_workshop.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			show_toast("✨ Rune Workshop: Arcane Transmutation ready!")
			rune_workshop_requested.emit()
		)
		
	_setup_character_roster_wiring()
	_setup_gear_slots_wiring()
	_setup_runes_dock_wiring()
	_setup_toast_label()
	
	if SaveManager and not SaveManager.active_character_id.is_empty():
		current_char_id = SaveManager.active_character_id
	refresh_loadout()
	_switch_subtab(active_subtab)

func _setup_runes_dock_wiring() -> void:
	var rune_grid := $ContentContainer/ViewRunes/BottomInventory/Grid as Control
	if not rune_grid: return
	var runes_info := [
		{"name": "Fire Rune", "icon": "🔥", "tier": 1},
		{"name": "Wolf Core", "icon": "🐺", "tier": 1},
		{"name": "Storm Shard", "icon": "⚡", "tier": 2},
		{"name": "Frost Rune", "icon": "❄", "tier": 1},
		{"name": "Void Crystal", "icon": "🔮", "tier": 2}
	]
	for i in range(mini(rune_grid.get_child_count(), runes_info.size())):
		var r_slot := rune_grid.get_child(i) as Control
		var info: Dictionary = runes_info[i]
		if r_slot:
			r_slot.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed:
					if AudioManager: AudioManager.play_sfx("item_place")
					show_toast("✨ %s (T%d) ready for ritual placement!" % [info.name, info.tier])
			)

func refresh_loadout() -> void:
	if not SaveManager: return
	var eq: Dictionary = SaveManager.equipment_levels
	var slots := [
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotWeapon,
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotAmulet,
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotRing,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotHelmet,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotArmor,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotBoots
	]
	var keys := ["weapon", "amulet", "ring", "helmet", "armor", "boots"]
	var total_lvl := 0
	for i in range(slots.size()):
		var slot: Control = slots[i]
		var k: String = keys[i]
		var lvl: int = eq.get(k, 60)
		total_lvl += lvl
		if slot:
			var lvl_lbl := slot.get_node_or_null("VBox/Level") as Label
			if lvl_lbl:
				lvl_lbl.text = "Lv.%d S" % lvl
				
	base_display_atk = 3200 + total_lvl * 8
	base_display_hp = 14000 + total_lvl * 25
	if stat_atk_label: stat_atk_label.text = "⚔ ATK: %s" % _format_num(base_display_atk)
	if stat_hp_label: stat_hp_label.text = "❤ HP: %s" % _format_num(base_display_hp)
	_update_character_ui()

func _setup_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(420, 48)
	_toast_label.anchors_preset = PRESET_CENTER
	_toast_label.position = Vector2(150, 460)
	_toast_label.add_theme_font_size_override("font_size", 16)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.45, 1.0))
	_toast_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.08, 0.14, 0.94)
	sb.border_color = Color(0.85, 0.72, 0.25, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(12)
	_toast_label.add_theme_stylebox_override("normal", sb)
	_toast_label.visible = false
	_toast_label.z_index = 50
	add_child(_toast_label)

func show_toast(text: String) -> void:
	if not _toast_label: return
	_toast_label.text = text
	_toast_label.visible = true
	_toast_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.8)
	tw.tween_property(_toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func(): _toast_label.visible = false)

func _setup_character_roster_wiring() -> void:
	if btn_star_up_hunter:
		btn_star_up_hunter.pressed.connect(_on_star_up_hunter)
	if btn_select_reaper:
		btn_select_reaper.pressed.connect(func(): _select_character("storm_reaper"))
	if btn_select_binder:
		btn_select_binder.pressed.connect(func(): _select_character("soul_binder"))
	if btn_unlock_valkyrie:
		btn_unlock_valkyrie.pressed.connect(_on_unlock_valkyrie)

func _select_character(char_id: String) -> void:
	current_char_id = char_id
	if GameManager:
		GameManager.set_character(char_id)
	if SaveManager:
		SaveManager.active_character_id = char_id
		SaveManager.save_profile()
	if AudioManager:
		AudioManager.play_sfx("ui_click")
		
	if char_pedestal: char_pedestal.character_id = char_id
	if gear_pedestal: gear_pedestal.character_id = char_id
	
	_update_character_ui()
	character_changed.emit(char_id)
	show_toast("Switched Active Hero: %s" % char_name_badge.text)

func _on_star_up_hunter() -> void:
	if SaveManager:
		if SaveManager.star_up_character("shadow_hunter"):
			hunter_stars = SaveManager.character_stars.get("shadow_hunter", hunter_stars + 1)
			base_display_atk += 280
			base_display_hp += 950
			_update_character_ui()
			show_toast("★ Shadow Hunter Star Up (%d★)! +280 ATK, +950 HP" % hunter_stars)
			star_up_requested.emit("shadow_hunter")
		else:
			var cur_s: int = SaveManager.character_stars.get("shadow_hunter", 1)
			var cost_shards: int = cur_s * 15
			var cost_gold: int = cur_s * 800
			var cur_shards: int = SaveManager.character_shards.get("shadow_hunter", 0)
			if cur_shards < cost_shards:
				if AudioManager: AudioManager.play_sfx("ui_error")
				show_toast("Need %d Shadow Shards! (Have %d)" % [cost_shards, cur_shards])
			else:
				if AudioManager: AudioManager.play_sfx("ui_error")
				show_toast("Need 🪙 %d Gold!" % cost_gold)
	else:
		if hunter_stars < 6:
			hunter_stars += 1
			base_display_atk += 280
			base_display_hp += 950
			if AudioManager: AudioManager.play_sfx("upgrade")
			_update_character_ui()
			show_toast("★ Shadow Hunter Star Up (%d★)!" % hunter_stars)
			star_up_requested.emit("shadow_hunter")

func _on_unlock_valkyrie() -> void:
	var shell = get_parent().get_parent() if get_parent() else null
	var can_afford := true
	if shell and "top_bar" in shell and shell.top_bar:
		can_afford = shell.top_bar.spend_gems(100)
	
	if can_afford:
		if AudioManager: AudioManager.play_sfx("upgrade")
		if ribbon_valkyrie:
			ribbon_valkyrie.text = "Lv.1"
			ribbon_valkyrie.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0, 1.0))
		if btn_unlock_valkyrie:
			btn_unlock_valkyrie.text = "Switch Hero"
			btn_unlock_valkyrie.pressed.disconnect(_on_unlock_valkyrie)
			btn_unlock_valkyrie.pressed.connect(func(): _select_character("frost_valkyrie"))
		show_toast("❄ Frost Valkyrie Unlocked!")
	else:
		if AudioManager: AudioManager.play_sfx("ui_error")
		show_toast("Not enough Gems! (Need 100 💎)")

func _update_character_ui() -> void:
	match current_char_id:
		"storm_reaper":
			if char_name_badge: char_name_badge.text = "Storm Reaper"
			if star_rating_row: star_rating_row.text = "★ ★ ★ ★ ☆ ☆"
			if ribbon_hunter: ribbon_hunter.text = "Select"
			if ribbon_reaper: ribbon_reaper.text = "● IN USE"
			if ribbon_binder: ribbon_binder.text = "Select"
			if skill_lbl_1: skill_lbl_1.text = "✦ Lv.1 Chain Surge [Unlocked]\nLightning jumps to 2 extra nearby targets."
			if skill_lbl_2: skill_lbl_2.text = "✦ Lv.2 Tempest Strike [Unlocked]\nEvery 4th hit calls down a thunderbolt."
			if skill_lbl_3: skill_lbl_3.text = "✦ Lv.3 Static Overload [Unlocked]\nShocked enemies explode on defeat."
			if skill_lbl_4: skill_lbl_4.text = "✧ Lv.4 Eye of the Maelstrom [Locked - 5★]\nStorm aura zaps surrounding foes."
			if stat_atk_label: stat_atk_label.text = "⚔ ATK: 5,140"
			if stat_hp_label: stat_hp_label.text = "❤ HP: 16,800"
		"soul_binder":
			if char_name_badge: char_name_badge.text = "Soul Binder"
			if star_rating_row: star_rating_row.text = "★ ★ ☆ ☆ ☆ ☆"
			if ribbon_hunter: ribbon_hunter.text = "Select"
			if ribbon_reaper: ribbon_reaper.text = "Select"
			if ribbon_binder: ribbon_binder.text = "● IN USE"
			if skill_lbl_1: skill_lbl_1.text = "✦ Lv.1 Soul Tether [Unlocked]\nAttacks leach life and slow enemy movespeed."
			if skill_lbl_2: skill_lbl_2.text = "✦ Lv.2 Spectral Harvest [Unlocked]\nDefeated enemies spawn orbiting wisps."
			if skill_lbl_3: skill_lbl_3.text = "✧ Lv.3 Void Absorption [Locked - 3★]\nAbsorb enemy projectiles into healing."
			if skill_lbl_4: skill_lbl_4.text = "✧ Lv.4 Soul Rebirth [Locked - 5★]\nFatal damage triggers 3s invulnerability."
			if stat_atk_label: stat_atk_label.text = "⚔ ATK: 4,680"
			if stat_hp_label: stat_hp_label.text = "❤ HP: 21,400"
		_:
			if char_name_badge: char_name_badge.text = "Shadow Hunter"
			if star_rating_row:
				var stars_str := ""
				for i in range(6):
					stars_str += "★ " if i < hunter_stars else "☆ "
				star_rating_row.text = stars_str.strip_edges()
			if ribbon_hunter: ribbon_hunter.text = "● IN USE"
			if ribbon_reaper: ribbon_reaper.text = "Lv.14"
			if ribbon_binder: ribbon_binder.text = "Lv.10"
			if skill_lbl_1: skill_lbl_1.text = "✦ Lv.1 Shadow Veil [Unlocked]\n+15% Dodge, shadow dash leaves decoy."
			if skill_lbl_2: skill_lbl_2.text = "✦ Lv.2 Abyssal Surge [Unlocked]\nConsecutive hits gain +5% ATK SPD (up to 25%)."
			if skill_lbl_3: skill_lbl_3.text = "✧ Lv.3 Soul Harvester [Locked - 3★]" if hunter_stars < 3 else "✦ Lv.3 Soul Harvester [Unlocked]\nDefeating an elite restores 10% max HP."
			if skill_lbl_4: skill_lbl_4.text = "✧ Lv.4 Void Singularity [Locked - 5★]\nCrits unleash shockwave dealing 180% damage."
			if stat_atk_label: stat_atk_label.text = "⚔ ATK: %s" % _format_num(base_display_atk)
			if stat_hp_label: stat_hp_label.text = "❤ HP: %s" % _format_num(base_display_hp)

func _setup_gear_slots_wiring() -> void:
	var slots := [
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotWeapon,
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotAmulet,
		$ContentContainer/ViewGear/TopHalf/LeftSlots/SlotRing,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotHelmet,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotArmor,
		$ContentContainer/ViewGear/TopHalf/RightSlots/SlotBoots
	]
	var names := ["Weapon", "Amulet", "Ring", "Helmet", "Armor", "Boots"]
	for i in range(slots.size()):
		var slot: Control = slots[i]
		var s_name: String = names[i]
		if slot:
			slot.gui_input.connect(func(ev: InputEvent):
				if ev is InputEventMouseButton and ev.pressed:
					_upgrade_gear_slot(slot, s_name)
			)

func _upgrade_gear_slot(slot: Control, slot_name: String) -> void:
	var k := slot_name.to_lower()
	if SaveManager:
		if SaveManager.upgrade_equipment_slot(k):
			var new_lvl: int = SaveManager.equipment_levels.get(k, 60)
			refresh_loadout()
			show_toast("✦ %s Upgraded to Lv.%d! (+45 ATK, +120 HP)" % [slot_name, new_lvl])
		else:
			var cur_l: int = SaveManager.equipment_levels.get(k, 60)
			var cost: int = cur_l * 50
			if AudioManager: AudioManager.play_sfx("ui_error")
			show_toast("Need 🪙 %d Gold to upgrade %s!" % [cost, slot_name])
	else:
		var lvl_lbl := slot.get_node_or_null("VBox/Level") as Label
		if lvl_lbl:
			base_display_atk += 45
			base_display_hp += 120
			if AudioManager: AudioManager.play_sfx("upgrade")
			lvl_lbl.text = "Lv.61 S"
			if stat_atk_label: stat_atk_label.text = "⚔ ATK: %s" % _format_num(base_display_atk)
			if stat_hp_label: stat_hp_label.text = "❤ HP: %s" % _format_num(base_display_hp)
			show_toast("✦ %s Upgraded to Lv.61!" % slot_name)

func _format_num(val: int) -> String:
	var thousands := val / 1000
	var rem := val % 1000
	return "%d,%03d" % [thousands, rem]

func _switch_subtab(idx: int) -> void:
	active_subtab = idx
	if AudioManager:
		AudioManager.play_sfx("ui_click")
		
	if view_characters: view_characters.visible = (idx == 0)
	if view_gear: view_gear.visible = (idx == 1)
	if view_runes: view_runes.visible = (idx == 2)
	
	# Update subtab button styling
	var active_color := Color(1.0, 0.88, 0.35, 1.0)
	var inactive_color := Color(0.65, 0.7, 0.8, 0.8)
	
	if btn_sub_characters:
		btn_sub_characters.add_theme_color_override("font_color", active_color if idx == 0 else inactive_color)
	if btn_sub_gear:
		btn_sub_gear.add_theme_color_override("font_color", active_color if idx == 1 else inactive_color)
	if btn_sub_runes:
		btn_sub_runes.add_theme_color_override("font_color", active_color if idx == 2 else inactive_color)
