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
var gear_sort_index: int = 0
var runes_sort_index: int = 0
var _toast_label: Label = null
var _info_modal: PanelContainer = null
var _gear_detail_modal: PanelContainer = null
var _gear_detail_title: Label = null
var _gear_detail_summary: Label = null
var _gear_detail_stats: Label = null
var _gear_detail_comparison: Label = null
var _gear_detail_equip_button: Button = null
var _gear_detail_unequip_button: Button = null
var _selected_gear_uid: String = ""

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
		
	# Keep unfinished cosmetic/workshop actions out of the live navigation until they have real gameplay effects.
	var btn_workshop := $ContentContainer/ViewRunes/MiddleBar/WorkshopBtn as Button
	if btn_workshop:
		btn_workshop.visible = false
	var btn_rune_sort := $ContentContainer/ViewRunes/MiddleBar.get_node_or_null("SortBtn") as Button
	if btn_rune_sort:
		btn_rune_sort.visible = false

	var btn_outfit := $ContentContainer/ViewCharacters/TopHalf/PedestalContainer.get_node_or_null("OutfitBtn") as Button
	if btn_outfit:
		btn_outfit.visible = false
	var btn_sacred := $ContentContainer/ViewCharacters/TopHalf/PedestalContainer.get_node_or_null("SacredHallBtn") as Button
	if btn_sacred:
		btn_sacred.visible = false

	# Stat Pill Info Button
	var btn_info := $ContentContainer/ViewGear/TopHalf/StatPill/HBox.get_node_or_null("InfoBtn") as Button
	if btn_info:
		btn_info.pressed.connect(_toggle_combat_power_modal)

	# Sort Buttons on Gear and Runes subtabs
	var btn_gear_sort := $ContentContainer/ViewGear/MiddleBar.get_node_or_null("SortBtn") as Button
	if btn_gear_sort:
		var sort_names := ["▼ By Quality", "▼ By Upgrade", "▼ By Slot"]
		btn_gear_sort.text = sort_names[gear_sort_index]
		btn_gear_sort.pressed.connect(func():
			gear_sort_index = (gear_sort_index + 1) % sort_names.size()
			btn_gear_sort.text = sort_names[gear_sort_index]
			if AudioManager: AudioManager.play_sfx("ui_click")
			_refresh_gear_inventory_grid()
			show_toast("Gear sorted: %s" % sort_names[gear_sort_index])
		)

		
	_setup_character_roster_wiring()
	_setup_gear_slots_wiring()
	_setup_runes_dock_wiring()
	_setup_toast_label()
	_setup_info_modal()
	_setup_gear_detail_modal()
	
	if SaveManager and not SaveManager.active_character_id.is_empty():
		current_char_id = SaveManager.active_character_id
	refresh_loadout()
	_switch_subtab(active_subtab)

func _setup_runes_dock_wiring() -> void:
	# The displayed rune tiles were static placeholders, not owned inventory.
	# Hide them until the profile-backed ritual collection is implemented.
	var rune_inventory := $ContentContainer/ViewRunes/BottomInventory as Control
	if rune_inventory:
		rune_inventory.visible = false

func refresh_loadout() -> void:
	if not SaveManager:
		return

	var slots := {
		"weapon": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotWeapon,
		"amulet": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotAmulet,
		"ring": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotRing,
		"helmet": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotHelmet,
		"armor": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotArmor,
		"boots": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotBoots
	}
	var slot_icons := {
		"weapon": "🗡", "amulet": "📿", "ring": "💍",
		"helmet": "👑", "armor": "🥋", "boots": "👢"
	}
	for slot_name in slots:
		var slot: Control = slots[slot_name]
		var item: ItemInstance = SaveManager.get_equipped_gear(slot_name)
		var icon_lbl := slot.get_node_or_null("VBox/Icon") as Label
		var level_lbl := slot.get_node_or_null("VBox/Level") as Label
		if icon_lbl:
			icon_lbl.text = slot_icons[slot_name] if not item else slot_icons[slot_name]
		if level_lbl:
			if item and item.data:
				level_lbl.text = "%s\n+%d" % [item.data.name, item.upgrade_level]
			else:
				level_lbl.text = "Empty"
				
	_update_character_ui()
	_refresh_gear_inventory_grid()

func _refresh_gear_inventory_grid() -> void:
	var gear_grid := $ContentContainer/ViewGear/BottomInventory/Grid as GridContainer
	if not gear_grid or not SaveManager:
		return
	for child in gear_grid.get_children():
		gear_grid.remove_child(child)
		child.queue_free()

	var slot_icons := {
		"weapon": "🗡", "amulet": "📿", "ring": "💍",
		"helmet": "👑", "armor": "🥋", "boots": "👢"
	}
	var items: Array[ItemInstance] = _get_sorted_gear_items(SaveManager.get_gear_items(), gear_sort_index)
	for item in items:
		if not item or not item.data:
			continue
		var slot_name := item.data.equipment_slot
		var button := Button.new()
		button.custom_minimum_size = Vector2(104, 104)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var equipped := str(SaveManager.equipped_gear.get(slot_name, "")) == item.uid
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.1, 0.12, 0.18, 0.95) if equipped else Color(0.06, 0.08, 0.13, 0.92)
		style.border_color = Color(0.95, 0.78, 0.25, 1.0) if equipped else Color(0.32, 0.4, 0.55, 0.75)
		style.set_border_width_all(2 if equipped else 1)
		style.set_corner_radius_all(10)
		
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_stylebox_override("hover", style)
		button.add_theme_stylebox_override("pressed", style)
		
		var title_col := Color(1.0, 0.9, 0.45, 1.0) if equipped else Color(0.85, 0.88, 0.95, 1.0)
		button.add_theme_color_override("font_color", title_col)
		button.text = "%s\n%s\n%s" % [
			slot_icons.get(slot_name, "◆"),
			item.data.name,
			"★ Equipped" if equipped else item.rarity.capitalize()
		]
		button.add_theme_font_size_override("font_size", 12)
		var item_uid := item.uid
		if item.uid == _selected_gear_uid:
			button.text += "\n[Selected]"
		button.pressed.connect(func():
			_show_gear_details(item_uid)
		)
		gear_grid.add_child(button)

	# Fill remaining slots up to at least 25 (5 full rows of 5) with clean gothic empty backpack slots
	var total_slots := maxi(25, ((items.size() + 4) / 5) * 5)
	for i in range(items.size(), total_slots):
		var empty_panel := PanelContainer.new()
		empty_panel.custom_minimum_size = Vector2(104, 104)
		empty_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var empty_style := StyleBoxFlat.new()
		empty_style.bg_color = Color(0.04, 0.05, 0.08, 0.55)
		empty_style.border_color = Color(0.18, 0.22, 0.32, 0.5)
		empty_style.set_border_width_all(1)
		empty_style.set_corner_radius_all(8)
		empty_panel.add_theme_stylebox_override("panel", empty_style)
		
		var empty_lbl := Label.new()
		empty_lbl.text = "✦"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 16)
		empty_lbl.add_theme_color_override("font_color", Color(0.25, 0.3, 0.4, 0.45))
		empty_panel.add_child(empty_lbl)
		gear_grid.add_child(empty_panel)


func _get_sorted_gear_items(items: Array[ItemInstance], sort_index: int) -> Array[ItemInstance]:
	var sorted_items: Array[ItemInstance] = []
	for item in items:
		if item and item.data:
			sorted_items.append(item)

	var rarity_order := {
		"common": 0,
		"uncommon": 1,
		"rare": 2,
		"epic": 3,
		"legendary": 4,
		"mythic": 5
	}
	var slot_order: Array[String] = SaveManager.EQUIPMENT_SLOTS if SaveManager else [
		"weapon", "helmet", "armor", "boots", "amulet", "ring"
	]
	sorted_items.sort_custom(func(a: ItemInstance, b: ItemInstance) -> bool:
		match sort_index:
			1:
				if a.upgrade_level != b.upgrade_level:
					return a.upgrade_level > b.upgrade_level
				if a.data.tier != b.data.tier:
					return a.data.tier > b.data.tier
			2:
				var a_slot := slot_order.find(a.data.equipment_slot)
				var b_slot := slot_order.find(b.data.equipment_slot)
				if a_slot != b_slot:
					return a_slot < b_slot
				return a.data.name.nocasecmp_to(b.data.name) < 0
			_:
				if a.data.tier != b.data.tier:
					return a.data.tier > b.data.tier
				var a_rarity: int = rarity_order.get(a.rarity.to_lower(), 0)
				var b_rarity: int = rarity_order.get(b.rarity.to_lower(), 0)
				if a_rarity != b_rarity:
					return a_rarity > b_rarity
		return a.data.name.nocasecmp_to(b.data.name) < 0
	)
	return sorted_items

func _setup_gear_detail_modal() -> void:
	_gear_detail_modal = PanelContainer.new()
	_gear_detail_modal.name = "GearDetailModal"
	_gear_detail_modal.anchor_left = 0.5
	_gear_detail_modal.anchor_top = 0.5
	_gear_detail_modal.anchor_right = 0.5
	_gear_detail_modal.anchor_bottom = 0.5
	_gear_detail_modal.offset_left = -250.0
	_gear_detail_modal.offset_top = -230.0
	_gear_detail_modal.offset_right = 250.0
	_gear_detail_modal.offset_bottom = 230.0
	_gear_detail_modal.custom_minimum_size = Vector2(500, 460)
	_gear_detail_modal.z_index = 70

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.045, 0.055, 0.09, 0.98)
	panel_style.border_color = Color(0.86, 0.69, 0.28, 1.0)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(14)
	_gear_detail_modal.add_theme_stylebox_override("panel", panel_style)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	_gear_detail_modal.add_child(content)

	_gear_detail_title = Label.new()
	_gear_detail_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gear_detail_title.add_theme_font_size_override("font_size", 22)
	_gear_detail_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.38, 1.0))
	content.add_child(_gear_detail_title)

	_gear_detail_summary = Label.new()
	_gear_detail_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gear_detail_summary.add_theme_font_size_override("font_size", 15)
	content.add_child(_gear_detail_summary)

	_gear_detail_stats = Label.new()
	_gear_detail_stats.add_theme_font_size_override("font_size", 16)
	_gear_detail_stats.add_theme_color_override("font_color", Color(0.82, 0.9, 1.0, 1.0))
	content.add_child(_gear_detail_stats)

	_gear_detail_comparison = Label.new()
	_gear_detail_comparison.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gear_detail_comparison.add_theme_font_size_override("font_size", 14)
	_gear_detail_comparison.add_theme_color_override("font_color", Color(0.78, 0.86, 0.78, 1.0))
	content.add_child(_gear_detail_comparison)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)

	_gear_detail_equip_button = Button.new()
	_gear_detail_equip_button.text = "EQUIP"
	_gear_detail_equip_button.custom_minimum_size = Vector2(130, 46)
	_gear_detail_equip_button.pressed.connect(_on_gear_detail_equip_pressed)
	actions.add_child(_gear_detail_equip_button)

	_gear_detail_unequip_button = Button.new()
	_gear_detail_unequip_button.text = "UNEQUIP"
	_gear_detail_unequip_button.custom_minimum_size = Vector2(130, 46)
	_gear_detail_unequip_button.pressed.connect(_on_gear_detail_unequip_pressed)
	actions.add_child(_gear_detail_unequip_button)

	var close_button := Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(100, 46)
	close_button.pressed.connect(func(): _gear_detail_modal.visible = false)
	actions.add_child(close_button)

	_gear_detail_modal.visible = false
	add_child(_gear_detail_modal)

func _show_gear_details(uid: String) -> bool:
	if not SaveManager or not _gear_detail_modal:
		return false
	var item: ItemInstance = SaveManager.get_gear_item(uid)
	if not item or not item.data:
		return false

	_selected_gear_uid = uid
	var slot_name := item.data.equipment_slot
	var equipped: ItemInstance = SaveManager.get_equipped_gear(slot_name)
	var is_equipped := equipped != null and equipped.uid == item.uid
	_gear_detail_title.text = item.data.name
	_gear_detail_summary.text = "%s  •  %s  •  Tier %d  •  Upgrade +%d\n%s" % [
		slot_name.capitalize(), item.rarity.capitalize(), item.data.tier, item.upgrade_level, item.data.description
	]
	var stats := _get_gear_item_stats(item)
	_gear_detail_stats.text = "ATK  +%s     HP  +%s\nCRIT  +%.1f%%     MOVE SPD  +%s\nATK SPD  +%.1f%%" % [
		_format_gear_stat(stats["bonus_atk"]),
		_format_gear_stat(stats["bonus_hp"]),
		stats["bonus_crit"] * 100.0,
		_format_gear_stat(stats["bonus_speed"]),
		stats["bonus_atk_speed"] * 100.0
	]
	_gear_detail_comparison.text = _build_gear_comparison_text(item, equipped)
	_gear_detail_equip_button.text = "EQUIPPED" if is_equipped else "EQUIP"
	_gear_detail_equip_button.disabled = is_equipped
	_gear_detail_unequip_button.visible = is_equipped
	_gear_detail_modal.visible = true
	_refresh_gear_inventory_grid()
	return true

func _get_gear_item_stats(item: ItemInstance) -> Dictionary:
	if not item or not item.data:
		return {}
	var level := maxi(0, item.upgrade_level)
	return {
		"bonus_atk": item.data.bonus_atk + level,
		"bonus_hp": item.data.bonus_hp + (level * 5.0),
		"bonus_crit": item.data.bonus_crit + (level * 0.001),
		"bonus_speed": item.data.bonus_speed + level,
		"bonus_atk_speed": item.data.bonus_atk_speed + (level * 0.005)
	}

func _build_gear_comparison_text(item: ItemInstance, equipped: ItemInstance) -> String:
	if not equipped or not equipped.data:
		return "Comparison: This slot is empty. Equipping this item will add its full bonuses."
	if equipped.uid == item.uid:
		return "Currently equipped in this slot."
	var candidate_stats := _get_gear_item_stats(item)
	var current_stats := _get_gear_item_stats(equipped)
	return "Compared with %s:\nATK %s  •  HP %s\nCRIT %s  •  MOVE SPD %s  •  ATK SPD %s" % [
		equipped.data.name,
		_format_gear_delta(candidate_stats["bonus_atk"] - current_stats["bonus_atk"], false),
		_format_gear_delta(candidate_stats["bonus_hp"] - current_stats["bonus_hp"], false),
		_format_gear_delta(candidate_stats["bonus_crit"] - current_stats["bonus_crit"], true),
		_format_gear_delta(candidate_stats["bonus_speed"] - current_stats["bonus_speed"], false),
		_format_gear_delta(candidate_stats["bonus_atk_speed"] - current_stats["bonus_atk_speed"], true)
	]

func _format_gear_set_bonus(bonus: Dictionary) -> String:
	var labels: Array[String] = []
	var names := {"bonus_atk": "ATK", "bonus_hp": "HP", "bonus_crit": "CRIT", "bonus_speed": "MOVE SPD", "bonus_atk_speed": "ATK SPD"}
	for stat_name in bonus:
		var value := float(bonus[stat_name])
		var percent: bool = stat_name in ["bonus_crit", "bonus_atk_speed"]
		var display_value := value * 100.0 if percent else value
		labels.append("%s +%s%s" % [names.get(stat_name, stat_name), _format_gear_stat(display_value), "%" if percent else ""])
	return ", ".join(labels)

func _format_gear_stat(value: float) -> String:
	return "%d" % roundi(value) if is_equal_approx(value, roundf(value)) else "%.2f" % value

func _format_gear_delta(value: float, as_percent: bool) -> String:
	var display_value := value * 100.0 if as_percent else value
	var sign := "+" if display_value >= 0.0 else ""
	return "%s%.1f%s" % [sign, display_value, "%" if as_percent else ""]

func _on_gear_detail_equip_pressed() -> void:
	if not SaveManager or _selected_gear_uid.is_empty():
		return
	var uid := _selected_gear_uid
	if SaveManager.equip_gear_item(uid):
		if AudioManager: AudioManager.play_sfx("item_place")
		refresh_loadout()
		_show_gear_details(uid)
		show_toast("Equipment updated")
	else:
		show_toast("This item cannot be equipped")

func _on_gear_detail_unequip_pressed() -> void:
	if not SaveManager or _selected_gear_uid.is_empty():
		return
	var item: ItemInstance = SaveManager.get_gear_item(_selected_gear_uid)
	if item and SaveManager.unequip_gear_slot(item.data.equipment_slot):
		if AudioManager: AudioManager.play_sfx("item_place")
		refresh_loadout()
		_show_gear_details(item.uid)
		show_toast("Equipment removed")


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

func _setup_info_modal() -> void:
	_info_modal = PanelContainer.new()
	_info_modal.anchors_preset = PRESET_CENTER
	_info_modal.custom_minimum_size = Vector2(500, 430)
	_info_modal.anchor_left = 0.5
	_info_modal.anchor_top = 0.5
	_info_modal.anchor_right = 0.5
	_info_modal.anchor_bottom = 0.5
	_info_modal.offset_left = -250.0
	_info_modal.offset_top = -215.0
	_info_modal.offset_right = 250.0
	_info_modal.offset_bottom = 215.0

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.07, 0.12, 0.98)
	sb.border_color = Color(0.9, 0.75, 0.3, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(14)
	_info_modal.add_theme_stylebox_override("panel", sb)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	vb.offset_left = 16
	vb.offset_top = 16
	vb.offset_right = -16
	vb.offset_bottom = -16
	_info_modal.add_child(vb)

	var title := Label.new()
	title.text = "⚔ COMBAT ATTRIBUTES BREAKDOWN ⚔"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1.0, 0.88, 0.4, 1.0))
	vb.add_child(title)

	var desc := Label.new()
	desc.name = "StatDescLabel"
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", Color(0.85, 0.88, 0.95, 1.0))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc)

	var btn_close := Button.new()
	btn_close.text = "CLOSE"
	btn_close.custom_minimum_size = Vector2(120, 38)
	btn_close.size_flags_horizontal = SIZE_SHRINK_CENTER
	btn_close.pressed.connect(func():
		if AudioManager: AudioManager.play_sfx("ui_click")
		_info_modal.visible = false
	)
	vb.add_child(btn_close)

	_info_modal.visible = false
	_info_modal.z_index = 60
	add_child(_info_modal)

func _toggle_combat_power_modal() -> void:
	if not _info_modal:
		return
	if _info_modal.visible:
		_info_modal.visible = false
		return

	var breakdown: Dictionary = SaveManager.get_combat_power_breakdown() if SaveManager else {}
	var gear_stats: Dictionary = breakdown.get("gear_stats", {})
	var equipped_count := 0
	if SaveManager:
		for slot_name in SaveManager.EQUIPMENT_SLOTS:
			if SaveManager.get_equipped_gear(slot_name):
				equipped_count += 1
	var set_lines := PackedStringArray()
	for set_info in breakdown.get("active_gear_sets", []):
		var count: int = int(set_info.get("count", 0))
		var threshold: int = int(set_info.get("active_threshold", 0))
		var next_threshold: int = int(set_info.get("next_threshold", 0))
		var status := "ACTIVE %d-PIECE" % threshold if threshold > 0 else "INCOMPLETE"
		var progress := "%d/%d" % [count, int(set_info.get("required", 0))]
		if next_threshold > 0:
			progress += "  · next bonus at %d" % next_threshold
		set_lines.append("%s  %s  [%s]" % [str(set_info.get("name", "Gear Set")), progress, status])
		var bonus: Dictionary = set_info.get("bonus", {})
		if not bonus.is_empty():
			set_lines.append("  Active: %s" % _format_gear_set_bonus(bonus))
	var set_text := "\\n".join(set_lines) if not set_lines.is_empty() else "No gear sets equipped."
	var desc_lbl := _info_modal.find_child("StatDescLabel", true, false) as Label
	if desc_lbl:
		desc_lbl.text = "TOTAL COMBAT POWER  %s\\n\\nPOWER SOURCES\\nHunter level       %s\\nEquipment (legacy)  %s\\nEquipped gear       %s\\nGear set bonuses    %s\\nCharacter stars     %s\\nTalent cards        %s\\n\\nTOTAL EQUIPPED BONUSES\\nATK  +%s     HP  +%s\\nCRIT  +%.1f%%     MOVE SPD  +%s\\nATK SPD  +%.1f%%\\n\\nGEAR SET PROGRESS\\n%s\\n\\nEquipment slots: %d/6\\nRune resonance is calculated separately during runs." % [
			_format_num(int(breakdown.get("total", 0))),
			_format_num(int(breakdown.get("base", 0))),
			_format_num(int(breakdown.get("legacy_gear", 0))),
			_format_num(int(breakdown.get("equipped_gear", 0))),
			_format_num(int(breakdown.get("set_bonus", 0))),
			_format_num(int(breakdown.get("character", 0))),
			_format_num(int(breakdown.get("talents", 0))),
			_format_gear_stat(gear_stats.get("bonus_atk", 0.0)),
			_format_gear_stat(gear_stats.get("bonus_hp", 0.0)),
			float(gear_stats.get("bonus_crit", 0.0)) * 100.0,
			_format_gear_stat(gear_stats.get("bonus_speed", 0.0)),
			float(gear_stats.get("bonus_atk_speed", 0.0)) * 100.0,
			set_text,
			equipped_count
		]
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_info_modal.visible = true

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

	_refresh_gear_stat_labels()

func _refresh_gear_stat_labels() -> void:
	if not SaveManager:
		return
	var gear_stats: Dictionary = SaveManager.get_equipped_gear_stats()
	if stat_atk_label:
		stat_atk_label.text = "⚔ Gear ATK: +%d" % int(gear_stats.get("bonus_atk", 0.0))
	if stat_hp_label:
		stat_hp_label.text = "❤ Gear HP: +%d" % int(gear_stats.get("bonus_hp", 0.0))

func _setup_gear_slots_wiring() -> void:
	var slots := {
		"weapon": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotWeapon,
		"amulet": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotAmulet,
		"ring": $ContentContainer/ViewGear/TopHalf/LeftSlots/SlotRing,
		"helmet": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotHelmet,
		"armor": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotArmor,
		"boots": $ContentContainer/ViewGear/TopHalf/RightSlots/SlotBoots
	}
	for slot_name in slots:
		var slot: Control = slots[slot_name]
		slot.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_on_gear_slot_pressed(slot_name)
		)

func _on_gear_slot_pressed(slot_name: String) -> void:
	if not SaveManager:
		return
	var item: ItemInstance = SaveManager.get_equipped_gear(slot_name)
	if item:
		_show_gear_details(item.uid)
	else:
		show_toast("No %s equipped" % slot_name.capitalize())


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
	
	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color(0.14, 0.1, 0.24, 0.95)
	active_style.border_color = Color(0.95, 0.8, 0.35, 1.0)
	active_style.set_border_width_all(1)
	active_style.border_width_bottom = 2
	active_style.set_corner_radius_all(8)
	
	var empty_style := StyleBoxEmpty.new()
	
	var subtab_buttons := [btn_sub_characters, btn_sub_gear, btn_sub_runes]
	for i in range(subtab_buttons.size()):
		var btn = subtab_buttons[i]
		if btn:
			var is_cur := (i == idx)
			btn.add_theme_color_override("font_color", active_color if is_cur else inactive_color)
			btn.add_theme_stylebox_override("normal", active_style if is_cur else empty_style)
			btn.add_theme_stylebox_override("hover", active_style if is_cur else empty_style)
			btn.add_theme_stylebox_override("pressed", active_style if is_cur else empty_style)
