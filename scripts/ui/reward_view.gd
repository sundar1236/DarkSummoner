class_name RewardView
extends Control

# Valkyrie & Altar Blessing screen (Archero 2 style)
# Presents legendary / epic blessing cards with winged rarity banners,
# bold ability icons, stat arrow ratings (ATK PWR ↑↑↑), refresh rolls, and run spoils.

signal reward_claimed_and_continue()

@export var lbl_title: Label
@export var lbl_gold_earned: Label
@export var lbl_shades_earned: Label
@export var choices_container: HBoxContainer
@export var btn_refresh: Button
@export var lbl_refresh_left: Label
@export var btn_continue: Button

var selected_item_choice: ItemData = null
var is_claimed: bool = false
var is_boss_reward: bool = false
var refreshes_left: int = 1

func _ready() -> void:
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)
	if btn_refresh:
		btn_refresh.pressed.connect(_on_refresh_pressed)

func setup(is_boss: bool) -> void:
	is_claimed = false
	is_boss_reward = is_boss
	selected_item_choice = null
	refreshes_left = 1
	_update_refresh_ui()
	
	var gold_gain := 50 if is_boss else 20
	var shades_gain := 12 if is_boss else 2
	
	GameManager.add_gold(gold_gain)
	GameManager.add_run_shades(shades_gain)
	
	if lbl_title:
		lbl_title.text = "✦ VALKYRIE OF THE ABYSS ✦\nChoose a blessing to empower your descent" if not is_boss else "✦ ABYSSAL DEFEATED! CLAIM CELESTIAL BLESSING ✦"
	if lbl_gold_earned:
		lbl_gold_earned.text = "+%d Gold" % gold_gain
	if lbl_shades_earned:
		lbl_shades_earned.text = "+%d Shades" % shades_gain
		
	_generate_item_choices(is_boss)

func _update_refresh_ui() -> void:
	if lbl_refresh_left:
		lbl_refresh_left.text = "Skill refreshes left: %d" % refreshes_left
	if btn_refresh:
		btn_refresh.disabled = (refreshes_left <= 0)
		btn_refresh.modulate = Color(1.0, 1.0, 1.0) if refreshes_left > 0 else Color(0.6, 0.6, 0.6)

func _on_refresh_pressed() -> void:
	if refreshes_left <= 0:
		return
	refreshes_left -= 1
	_update_refresh_ui()
	if AudioManager:
		AudioManager.play_sfx("item_rotate")
	_generate_item_choices(is_boss_reward)

func _generate_item_choices(is_boss: bool) -> void:
	if not choices_container:
		return
	for c in choices_container.get_children():
		c.queue_free()
		
	var pool: Array[ItemData] = ItemDatabase.get_all_items()
	pool.shuffle()
	
	var count: int = mini(3, pool.size())
	for i in range(count):
		var item_data: ItemData = pool[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(200, 390)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Custom Rarity Border & Styling (Archero 2 Valkyrie style)
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.09, 0.07, 0.14, 0.96)
		style.set_border_width_all(2)
		
		var banner_title := "✦ RARE ✦"
		var banner_color := Color(0.35, 0.8, 1.0) # Tier 1
		if item_data.tier == 2:
			banner_title = "⭐ EPIC ⭐"
			banner_color = Color(0.8, 0.4, 1.0) # Tier 2
		elif item_data.tier >= 3:
			banner_title = "👑 LEGENDARY 👑"
			banner_color = Color(1.0, 0.85, 0.25) # Tier 3
			
		style.border_color = banner_color
		style.set_corner_radius_all(12)
		style.shadow_color = Color(0, 0, 0, 0.65)
		style.shadow_size = 6
		style.content_margin_left = 12
		style.content_margin_right = 12
		style.content_margin_top = 10
		style.content_margin_bottom = 12
		card.add_theme_stylebox_override("panel", style)
		
		var vbox := VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 8)
		
		# 1. Crown / Winged Rarity Banner Pill
		var banner_panel := PanelContainer.new()
		var b_style := StyleBoxFlat.new()
		b_style.bg_color = Color(banner_color.r * 0.25, banner_color.g * 0.25, banner_color.b * 0.25, 0.9)
		b_style.set_border_width_all(1)
		b_style.border_color = banner_color
		b_style.set_corner_radius_all(6)
		b_style.content_margin_left = 6
		b_style.content_margin_right = 6
		b_style.content_margin_top = 2
		b_style.content_margin_bottom = 2
		banner_panel.add_theme_stylebox_override("panel", b_style)
		
		var banner_lbl := Label.new()
		banner_lbl.text = banner_title
		banner_lbl.modulate = banner_color
		banner_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_lbl.add_theme_font_size_override("font_size", 12)
		banner_panel.add_child(banner_lbl)
		
		# 2. Blessing Title
		var name_lbl := Label.new()
		name_lbl.text = item_data.name
		name_lbl.modulate = Color(1.0, 1.0, 1.0)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 16)
		
		# 3. High-Contrast Icon Panel
		var icon_panel := PanelContainer.new()
		icon_panel.custom_minimum_size = Vector2(80, 80)
		icon_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var icon_style := StyleBoxFlat.new()
		icon_style.bg_color = Color(0.05, 0.04, 0.08, 0.92)
		icon_style.set_border_width_all(2)
		icon_style.border_color = banner_color
		icon_style.set_corner_radius_all(10)
		icon_panel.add_theme_stylebox_override("panel", icon_style)
		
		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(72, 72)
		icon_rect.texture = item_data.get_icon_texture()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_panel.add_child(icon_rect)
		
		# 4. Stat Arrows & Ratings (Archero 2 style)
		var stats_lbl := Label.new()
		var stat_lines: Array[String] = []
		if item_data.bonus_atk > 0:
			var arrows := "↑↑" if item_data.bonus_atk < 10 else "↑↑↑↑"
			stat_lines.append("ATK PWR %s (+%.0f)" % [arrows, item_data.bonus_atk])
		if item_data.bonus_hp > 0:
			stat_lines.append("MAX HP ↑↑↑ (+%.0f)" % item_data.bonus_hp)
		if item_data.bonus_crit > 0:
			stat_lines.append("CRIT RATE ↑↑ (+%.0f%%)" % (item_data.bonus_crit * 100.0))
		if item_data.bonus_speed > 0:
			stat_lines.append("SPEED ↑↑ (+%.0f)" % item_data.bonus_speed)
		if item_data.bonus_atk_speed > 0:
			stat_lines.append("ATK SPD ↑↑↑ (+%.0f%%)" % (item_data.bonus_atk_speed * 100.0))
		if item_data.passive_type != "none":
			stat_lines.append(item_data.passive_type.capitalize() + " Infusion")
			
		stats_lbl.text = "\n".join(stat_lines) if not stat_lines.is_empty() else "Special Relic"
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_lbl.add_theme_font_size_override("font_size", 12)
		stats_lbl.modulate = Color(0.3, 1.0, 0.6)
		
		# 5. Lore / Ability Description
		var desc_lbl := Label.new()
		desc_lbl.text = item_data.description
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 11)
		desc_lbl.modulate = Color(0.85, 0.85, 0.95, 0.9)
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		
		# 6. Select Button
		var btn_pick := Button.new()
		btn_pick.custom_minimum_size = Vector2(0, 42)
		btn_pick.text = "SELECT BLESSING"
		btn_pick.add_theme_font_size_override("font_size", 13)
		var cap_data := item_data
		var cap_card := card
		btn_pick.pressed.connect(func():
			_select_item(cap_data, cap_card)
		)
		
		# Card click fallback
		card.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_select_item(cap_data, cap_card)
			elif ev is InputEventScreenTouch and ev.pressed:
				_select_item(cap_data, cap_card)
		)
		
		vbox.add_child(banner_panel)
		vbox.add_child(name_lbl)
		vbox.add_child(icon_panel)
		vbox.add_child(stats_lbl)
		vbox.add_child(desc_lbl)
		vbox.add_child(btn_pick)
		card.add_child(vbox)
		choices_container.add_child(card)

func _select_item(data: ItemData, card_node: PanelContainer) -> void:
	selected_item_choice = data
	for c in choices_container.get_children():
		c.modulate = Color(0.6, 0.6, 0.65)
	card_node.modulate = Color(1.25, 1.2, 0.6)
	if AudioManager:
		AudioManager.play_sfx("item_pickup")

func _on_continue_pressed() -> void:
	if is_claimed:
		return
	is_claimed = true
	
	if selected_item_choice:
		var inst := ItemInstance.new(selected_item_choice)
		if GameManager.backpack_items.size() < GameManager.BACKPACK_CAPACITY:
			GameManager.add_item_to_backpack(inst)
		else:
			for y in range(GameManager.grid_manager.height):
				for x in range(GameManager.grid_manager.width):
					if GameManager.move_item_to_altar(inst, Vector2i(x, y)):
						break
						
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	reward_claimed_and_continue.emit()
