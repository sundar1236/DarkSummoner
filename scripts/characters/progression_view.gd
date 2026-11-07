class_name ProgressionView
extends Control

# Character Selection and Permanent Meta-Progression Sanctuary.
# Allows selecting/unlocking characters, upgrading permanent stats with Shades,
# and starting runs.

signal start_run_requested(character_id: String)
signal back_requested()

@export var lbl_shades_balance: Label
@export var btn_tab_chars: Button
@export var btn_tab_upgrades: Button

# Character View
@export var chars_container: Control
@export var char_buttons_row: HBoxContainer
@export var lbl_char_name: Label
@export var lbl_char_title: Label
@export var lbl_char_desc: Label
@export var lbl_char_passive: Label
@export var lbl_char_active: Label
@export var lbl_char_stats: Label
@export var btn_select_or_unlock_char: Button

# Upgrades View
@export var upgrades_container: Control
@export var upgrades_list: VBoxContainer
@export var btn_back: Button

var selected_character_id: String = "shadow_hunter"

func _ready() -> void:
	_setup_signals()
	_update_shades_display()
	_init_characters_ui()
	_init_upgrades_ui()
	_select_character("shadow_hunter")
	_switch_tab("chars")

func _setup_signals() -> void:
	if btn_tab_chars:
		btn_tab_chars.pressed.connect(func(): _switch_tab("chars"))
	if btn_tab_upgrades:
		btn_tab_upgrades.pressed.connect(func(): _switch_tab("upgrades"))
	if btn_back:
		btn_back.pressed.connect(func(): back_requested.emit())
	if btn_select_or_unlock_char:
		btn_select_or_unlock_char.pressed.connect(_on_char_action_pressed)
		
	SaveManager.shades_changed.connect(func(_s: int):
		_update_shades_display()
		_init_upgrades_ui()
		_update_char_details()
	)

func _switch_tab(tab: String) -> void:
	if chars_container:
		chars_container.visible = (tab == "chars")
	if upgrades_container:
		upgrades_container.visible = (tab == "upgrades")
	if tab == "upgrades":
		_init_upgrades_ui()

func _update_shades_display() -> void:
	if lbl_shades_balance:
		lbl_shades_balance.text = "Permanent Shades: %d" % SaveManager.shades

func _init_characters_ui() -> void:
	if not char_buttons_row:
		return
	for c in char_buttons_row.get_children():
		c.queue_free()
		
	var chars := CharacterDatabase.get_all_characters()
	for ch in chars:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 50)
		btn.text = ch.name
		var cap_id := ch.id
		btn.pressed.connect(func(): _select_character(cap_id))
		char_buttons_row.add_child(btn)

func _select_character(char_id: String) -> void:
	selected_character_id = char_id
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_update_char_details()

func _update_char_details() -> void:
	var ch := CharacterDatabase.get_character(selected_character_id)
	if not ch: return
	
	if lbl_char_name:
		lbl_char_name.text = ch.name
		lbl_char_name.modulate = ch.primary_color
	if lbl_char_title:
		lbl_char_title.text = ch.title
	if lbl_char_desc:
		lbl_char_desc.text = ch.description
	if lbl_char_passive:
		lbl_char_passive.text = "Passive: " + ch.passive_desc
	if lbl_char_active:
		lbl_char_active.text = "Active Skill: " + ch.active_desc
	if lbl_char_stats:
		lbl_char_stats.text = "Base HP: %.0f | Base ATK: %.0f | Speed: %.0f | Crit: %.0f%%" % [
			ch.base_hp, ch.base_atk, ch.base_speed, ch.base_crit_chance * 100.0
		]
		
	var is_unlocked: bool = SaveManager.is_character_unlocked(ch.id)
	if btn_select_or_unlock_char:
		if is_unlocked:
			btn_select_or_unlock_char.text = "ENTER TOWER WITH " + ch.name.to_upper()
			btn_select_or_unlock_char.disabled = false
		else:
			var can_afford: bool = (SaveManager.shades >= ch.unlock_cost_shades)
			btn_select_or_unlock_char.text = "UNLOCK (%d SHADES)" % ch.unlock_cost_shades
			btn_select_or_unlock_char.disabled = not can_afford

func _on_char_action_pressed() -> void:
	var ch := CharacterDatabase.get_character(selected_character_id)
	if not ch: return
	
	if SaveManager.is_character_unlocked(ch.id):
		# Start run!
		start_run_requested.emit(ch.id)
	else:
		if SaveManager.unlock_character(ch.id, ch.unlock_cost_shades):
			_update_char_details()
		else:
			if AudioManager: AudioManager.play_sfx("ui_error")

func _init_upgrades_ui() -> void:
	if not upgrades_list:
		return
	for c in upgrades_list.get_children():
		c.queue_free()
		
	var upgrade_defs := [
		{ "id": "max_hp", "name": "Abyssal Vitality", "desc": "+15 Max Health per tier" },
		{ "id": "atk", "name": "Obsidian Might", "desc": "+8% Attack Damage per tier" },
		{ "id": "speed", "name": "Shadow Stride", "desc": "+6% Movement Speed per tier" },
		{ "id": "crit", "name": "Lethal Precision", "desc": "+4% Critical Chance per tier" },
		{ "id": "altar_expand", "name": "Altar Expansion", "desc": "Expands Altar grid (4x4 -> 5x4 -> 5x5 -> 6x5 -> 6x6)" },
		{ "id": "start_gold", "name": "Greed of the Depths", "desc": "+25 Starting Gold per run" },
		{ "id": "potion_potency", "name": "Crimson Nectar", "desc": "+12 HP restored per potion" }
	]
	
	for u in upgrade_defs:
		var card := PanelContainer.new()
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 12)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var title := Label.new()
		var lvl: int = SaveManager.permanent_upgrades.get(u["id"], 0)
		var ticks: String = ""
		for t in range(5):
			ticks += ("◆ " if t < lvl else "◇ ")
		title.text = "%s   %s [Tier %d/5]" % [u["name"], ticks.strip_edges(), lvl]
		title.modulate = Color(1.0, 0.85, 0.4)
		
		var desc := Label.new()
		desc.text = u["desc"]
		desc.add_theme_font_size_override("font_size", 12)
		desc.modulate = Color(0.8, 0.8, 0.85)
		
		vbox.add_child(title)
		vbox.add_child(desc)
		
		var btn_upg := Button.new()
		btn_upg.custom_minimum_size = Vector2(130, 42)
		if lvl >= 5:
			btn_upg.text = "MAXED"
			btn_upg.disabled = true
		else:
			var cost: int = SaveManager.get_upgrade_cost(u["id"])
			btn_upg.text = "UPGRADE\n(%d Shades)" % cost
			btn_upg.disabled = (SaveManager.shades < cost)
			var cap_id: String = u["id"]
			btn_upg.pressed.connect(func():
				SaveManager.upgrade_stat(cap_id)
			)
			
		hbox.add_child(vbox)
		hbox.add_child(btn_upg)
		card.add_child(hbox)
		upgrades_list.add_child(card)
