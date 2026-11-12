class_name SkillDraftModal
extends Control

# Valkyrie Blessing Draft Modal (Phase 5 & Ref Image 8)
# Presents full-screen dimmed overlay with gold winged banner ("You've encountered Valkyrie"),
# 3 compact ornate Legendary/Epic/Rare skill cards side-by-side,
# rank progression badges (New Skill / Upgrade Lv.1 -> Lv.2), stat preview arrows (ATK PWR ↑↑↑↑),
# Learned Skills slide-out drawer, and dynamic Refresh mechanic with deterministic testing support.

signal skill_chosen(skill_offer: Dictionary)
signal learned_skills_requested()

const SafeAreaHelper = preload("res://scripts/ui/safe_area_helper.gd")
const RunSkillDatabaseClass = preload("res://scripts/combat/run_skill_database.gd")

@export var is_modal_active: bool = false
var refreshes_left: int = 1
var is_choice_locked: bool = false

@onready var content_box: VBoxContainer = $Content
@onready var refresh_btn: Button = $Content/BottomBar/CenterRefresh/RefreshButton
@onready var refresh_count_lbl: Label = $Content/BottomBar/CenterRefresh/RefreshCountLabel
@onready var learned_btn: Button = $Content/BottomBar/LearnedSkillsBtn
@onready var card_1_panel: PanelContainer = $Content/CardsHBox/SkillCard1
@onready var card_2_panel: PanelContainer = $Content/CardsHBox/SkillCard2
@onready var card_1_btn: Button = $Content/CardsHBox/SkillCard1/CardButton
@onready var card_2_btn: Button = $Content/CardsHBox/SkillCard2/CardButton
@onready var card_3_panel: PanelContainer = $Content/CardsHBox/SkillCard3
@onready var card_3_btn: Button = $Content/CardsHBox/SkillCard3/CardButton

@onready var learned_drawer: PanelContainer = $LearnedDrawer
@onready var learned_list: VBoxContainer = $LearnedDrawer/VBox/ScrollContainer/LearnedList
@onready var close_drawer_btn: Button = $LearnedDrawer/VBox/CloseDrawerBtn

var card_1_offer: Dictionary = {}
var card_2_offer: Dictionary = {}
var card_3_offer: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_apply_safe_area()
	if not get_tree().root.size_changed.is_connected(_apply_safe_area):
		get_tree().root.size_changed.connect(_apply_safe_area)
		
	var cards_row := $Content/CardsHBox as HBoxContainer
	cards_row.custom_minimum_size = Vector2(0, 480)
	cards_row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	cards_row.add_theme_constant_override("separation", 10)
	for panel in [card_1_panel, card_2_panel, card_3_panel]:
		panel.custom_minimum_size = Vector2(0, 480)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var card_vbox := panel.get_node("VBox") as VBoxContainer
		card_vbox.add_theme_constant_override("separation", 6)
		var icon_box := panel.get_node("VBox/IconBox") as PanelContainer
		icon_box.custom_minimum_size = Vector2(64, 64)

	if refresh_btn:
		refresh_btn.pressed.connect(_on_refresh_pressed)
	if learned_btn:
		learned_btn.pressed.connect(_on_learned_pressed)
	if close_drawer_btn:
		close_drawer_btn.pressed.connect(func(): if learned_drawer: learned_drawer.visible = false)
	if card_1_btn:
		card_1_btn.pressed.connect(func(): _choose_card(1))
	if card_2_btn:
		card_2_btn.pressed.connect(func(): _choose_card(2))
	if card_3_btn:
		card_3_btn.pressed.connect(func(): _choose_card(3))
		
	_update_refresh_label()

func show_draft(seed_val: int = -1) -> void:
	is_modal_active = true
	is_choice_locked = false
	visible = true
	refreshes_left = 1
	if learned_drawer:
		learned_drawer.visible = false
	if card_1_btn: card_1_btn.disabled = false
	if card_2_btn: card_2_btn.disabled = false
	if card_3_btn: card_3_btn.disabled = false
	
	_generate_cards(seed_val)
	_update_refresh_label()
	
	# Pause scene tree during draft
	get_tree().paused = true

func _update_refresh_label() -> void:
	if refresh_count_lbl:
		refresh_count_lbl.text = "Skill refreshes left: %d" % refreshes_left
	if refresh_btn:
		refresh_btn.disabled = (refreshes_left <= 0 or is_choice_locked)
		refresh_btn.modulate = Color(1.0, 1.0, 1.0) if refreshes_left > 0 else Color(0.6, 0.6, 0.6)

func _on_refresh_pressed() -> void:
	if refreshes_left <= 0 or is_choice_locked:
		return
	refreshes_left -= 1
	_update_refresh_label()
	if AudioManager:
		AudioManager.play_sfx("item_rotate")
	_generate_cards()

func _generate_cards(seed_val: int = -1) -> void:
	var offers := RunSkillDatabaseClass.generate_offers(GameManager.run_learned_skills, 3, seed_val)
	card_1_offer = offers[0] if offers.size() > 0 else {}
	card_2_offer = offers[1] if offers.size() > 1 else {}
	card_3_offer = offers[2] if offers.size() > 2 else {}
	_update_cards_ui()

func _update_cards_ui() -> void:
	_update_single_card(1, card_1_offer, card_1_panel)
	_update_single_card(2, card_2_offer, card_2_panel)
	_update_single_card(3, card_3_offer, card_3_panel)

func _update_single_card(slot_idx: int, offer: Dictionary, panel: PanelContainer) -> void:
	if offer.is_empty() or not panel:
		return
		
	var path_prefix := "Content/CardsHBox/SkillCard%d/VBox/" % slot_idx
	var lbl_rarity := get_node_or_null(path_prefix + "RarityHeader") as Label
	var lbl_rank := get_node_or_null(path_prefix + "RankBadge") as Label
	var lbl_icon := get_node_or_null(path_prefix + "IconBox/Icon") as Label
	var lbl_title := get_node_or_null(path_prefix + "Title") as Label
	var lbl_arrow := get_node_or_null(path_prefix + "StatArrow") as Label
	var lbl_desc := get_node_or_null(path_prefix + "Desc") as Label
	var icon_box := get_node_or_null(path_prefix + "IconBox") as PanelContainer
	
	var rarity: String = offer.get("rarity", "rare")
	var is_leg: bool = (rarity == "legendary")
	var is_epic: bool = (rarity == "epic")
	var border_col: Color = offer.get("border_color", Color(0.3, 0.8, 1.0))
	
	# Apply distinctive rarity theme to card container
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color(0.10, 0.09, 0.16, 0.97)
	card_style.border_color = border_col
	card_style.set_border_width_all(3 if is_leg else 2)
	card_style.set_corner_radius_all(14)
	card_style.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.4 if is_leg else 0.25)
	card_style.shadow_size = 12 if is_leg else 8
	panel.add_theme_stylebox_override("panel", card_style)
	
	if icon_box:
		var ib_style := StyleBoxFlat.new()
		ib_style.bg_color = Color(0.06, 0.06, 0.12, 0.92)
		ib_style.border_color = border_col
		ib_style.set_border_width_all(2)
		ib_style.set_corner_radius_all(12)
		icon_box.add_theme_stylebox_override("panel", ib_style)
		
	if lbl_rarity:
		lbl_rarity.add_theme_font_size_override("font_size", 12)
		if is_leg:
			lbl_rarity.text = "⚔ LEGENDARY BLESSING ⚔"
			lbl_rarity.modulate = Color(1.0, 0.85, 0.25, 1.0)
		elif is_epic:
			lbl_rarity.text = "⭐ EPIC BLESSING ⭐"
			lbl_rarity.modulate = Color(0.85, 0.45, 1.0, 1.0)
		else:
			lbl_rarity.text = "✦ RARE BLESSING ✦"
			lbl_rarity.modulate = Color(0.35, 0.85, 1.0, 1.0)
			
	if lbl_rank:
		lbl_rank.add_theme_font_size_override("font_size", 11)
		if offer.get("is_fallback", false):
			lbl_rank.text = "★ DIVINE BOON ★"
			lbl_rank.modulate = Color(1.0, 0.9, 0.3)
		elif offer.get("is_new", true):
			lbl_rank.text = "✦ NEW SKILL ✦"
			lbl_rank.modulate = Color(0.4, 1.0, 0.6)
		else:
			var cur_l: int = offer.get("current_level", 1)
			var tgt_l: int = offer.get("target_level", 2)
			lbl_rank.text = "⬆ UPGRADE: Lv.%d ➔ Lv.%d" % [cur_l, tgt_l]
			lbl_rank.modulate = Color(1.0, 0.85, 0.35)
			
	if lbl_icon:
		lbl_icon.add_theme_font_size_override("font_size", 36)
		lbl_icon.text = offer.get("icon_symbol", "🗡")
	if lbl_title:
		lbl_title.add_theme_font_size_override("font_size", 16)
		lbl_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_title.text = offer.get("title", "Blessing")
	if lbl_arrow:
		lbl_arrow.add_theme_font_size_override("font_size", 12)
		lbl_arrow.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl_arrow.text = offer.get("stat_arrow", "ATK PWR ↑↑")
	if lbl_desc:
		lbl_desc.add_theme_font_size_override("font_size", 12)
		lbl_desc.text = offer.get("desc", "")

func _choose_card(slot: int) -> void:
	if is_choice_locked:
		return
	is_choice_locked = true
	
	var chosen: Dictionary = card_1_offer if slot == 1 else (card_2_offer if slot == 2 else card_3_offer)
	if chosen.is_empty():
		return
		
	# Disable buttons immediately to prevent duplicate application
	if card_1_btn: card_1_btn.disabled = true
	if card_2_btn: card_2_btn.disabled = true
	if card_3_btn: card_3_btn.disabled = true
	if refresh_btn: refresh_btn.disabled = true
	
	# Apply skill or upgrade atomically in GameManager
	var skill_id: String = chosen.get("id", "")
	GameManager.apply_run_skill(skill_id)
	
	if AudioManager:
		AudioManager.play_sfx("item_place")
		
	is_modal_active = false
	visible = false
	get_tree().paused = false
	skill_chosen.emit(chosen)

func _on_learned_pressed() -> void:
	if not learned_drawer:
		return
	learned_drawer.visible = true
	learned_skills_requested.emit()
	_populate_learned_drawer()

func _populate_learned_drawer() -> void:
	if not learned_list:
		return
	for c in learned_list.get_children():
		c.queue_free()
		
	var summary := GameManager.get_learned_skills_summary()
	if summary.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No blessings acquired yet this run.\nLevel up in battle to draft skills!"
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.modulate = Color(0.7, 0.75, 0.85, 1)
		learned_list.add_child(empty_lbl)
		return
		
	for item in summary:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 68)
		
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.12, 0.20, 0.95)
		style.set_border_width_all(1)
		var is_leg: bool = (item.get("rarity", "") == "legendary")
		style.border_color = Color(1.0, 0.85, 0.25, 0.8) if is_leg else Color(0.4, 0.6, 0.9, 0.7)
		style.set_corner_radius_all(10)
		card.add_theme_stylebox_override("panel", style)
		
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 14)
		
		var icon_lbl := Label.new()
		icon_lbl.text = item.get("icon_symbol", "✦")
		icon_lbl.add_theme_font_size_override("font_size", 32)
		hbox.add_child(icon_lbl)
		
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var top_row := HBoxContainer.new()
		var name_lbl := Label.new()
		name_lbl.text = item.get("name", "Skill")
		name_lbl.add_theme_font_size_override("font_size", 18)
		name_lbl.modulate = Color(1.0, 0.9, 0.45, 1)
		top_row.add_child(name_lbl)
		
		var stars_str := ""
		var cur_l: int = item.get("level", 1)
		var max_l: int = item.get("max_level", 3)
		for s in range(max_l):
			stars_str += "★ " if s < cur_l else "☆ "
		var star_lbl := Label.new()
		star_lbl.text = "  [%s (Lv.%d)]" % [stars_str.strip_edges(), cur_l]
		star_lbl.modulate = Color(0.4, 0.85, 1.0, 1)
		star_lbl.add_theme_font_size_override("font_size", 15)
		top_row.add_child(star_lbl)
		vbox.add_child(top_row)
		
		var desc_lbl := Label.new()
		desc_lbl.text = item.get("desc", "")
		desc_lbl.add_theme_font_size_override("font_size", 14)
		desc_lbl.modulate = Color(0.85, 0.9, 0.98, 1)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(desc_lbl)
		
		hbox.add_child(vbox)
		card.add_child(hbox)
		learned_list.add_child(card)

func _apply_safe_area() -> void:
	var safe: Dictionary = SafeAreaHelper.get_safe_margins()
	var top_inset: float = safe.get("top", 46.0)
	var bot_inset: float = safe.get("bottom", 28.0)
	var right_inset: float = safe.get("right", 14.0)
	var left_inset: float = safe.get("left", 14.0)
	
	if content_box:
		content_box.offset_top = top_inset + 10.0
		content_box.offset_bottom = -(bot_inset + 10.0)
		content_box.offset_left = left_inset + 10.0
		content_box.offset_right = -(right_inset + 10.0)
