class_name SkillDraftModal
extends Control

# Valkyrie Blessing Draft Modal (Ref Image 8)
# Full-screen dimmed overlay with gold winged banner ("You've encountered Valkyrie"),
# 2 tall ornate vertical Legendary skill cards side-by-side,
# stat rating arrows, Learned Skills button, and yellow Refresh button.

signal skill_chosen(skill_data: ItemData)
signal learned_skills_requested()

@export var is_modal_active: bool = false
var refreshes_left: int = 1

@onready var refresh_btn: Button = $Content/BottomBar/CenterRefresh/RefreshButton
@onready var refresh_count_lbl: Label = $Content/BottomBar/CenterRefresh/RefreshCountLabel
@onready var learned_btn: Button = $Content/BottomBar/LearnedSkillsBtn
@onready var card_1_btn: Button = $Content/CardsHBox/SkillCard1/CardButton
@onready var card_2_btn: Button = $Content/CardsHBox/SkillCard2/CardButton

var card_1_item: ItemData
var card_2_item: ItemData

func _ready() -> void:
	if refresh_btn:
		refresh_btn.pressed.connect(_on_refresh_pressed)
	if learned_btn:
		learned_btn.pressed.connect(func(): learned_skills_requested.emit())
	if card_1_btn:
		card_1_btn.pressed.connect(func(): _choose_card(1))
	if card_2_btn:
		card_2_btn.pressed.connect(func(): _choose_card(2))
	_update_refresh_label()

func show_draft() -> void:
	is_modal_active = true
	visible = true
	refreshes_left = 1
	_generate_cards()
	_update_refresh_label()

func _update_refresh_label() -> void:
	if refresh_count_lbl:
		refresh_count_lbl.text = "Skill refreshes left: %d" % refreshes_left
	if refresh_btn:
		refresh_btn.disabled = (refreshes_left <= 0)

func _on_refresh_pressed() -> void:
	if refreshes_left <= 0:
		return
	refreshes_left -= 1
	_update_refresh_label()
	if AudioManager:
		AudioManager.play_sfx("item_rotate")
	_generate_cards()

func _generate_cards() -> void:
	var pool := ItemDatabase.get_all_items()
	pool.shuffle()
	if pool.size() >= 2:
		card_1_item = pool[0]
		card_2_item = pool[1]
	elif pool.size() == 1:
		card_1_item = pool[0]
		card_2_item = pool[0]
	_update_card_ui()

func _update_card_ui() -> void:
	if card_1_item:
		var lbl_title1 := $Content/CardsHBox/SkillCard1/VBox/Title as Label
		var lbl_desc1 := $Content/CardsHBox/SkillCard1/VBox/Desc as Label
		var lbl_icon1 := $Content/CardsHBox/SkillCard1/VBox/IconBox/Icon as Label
		if lbl_title1: lbl_title1.text = card_1_item.name
		if lbl_desc1: lbl_desc1.text = "%s\n\nATK PWR ↑↑↑↑" % card_1_item.description
		if lbl_icon1: lbl_icon1.text = "🗡" if card_1_item.tags.has("weapon") else "🔥"
		
	if card_2_item:
		var lbl_title2 := $Content/CardsHBox/SkillCard2/VBox/Title as Label
		var lbl_desc2 := $Content/CardsHBox/SkillCard2/VBox/Desc as Label
		var lbl_icon2 := $Content/CardsHBox/SkillCard2/VBox/IconBox/Icon as Label
		if lbl_title2: lbl_title2.text = card_2_item.name
		if lbl_desc2: lbl_desc2.text = "%s\n\nATK PWR ↑↑↑↑" % card_2_item.description
		if lbl_icon2: lbl_icon2.text = "⚡" if card_2_item.tags.has("lightning") else "🐺"

func _choose_card(slot: int) -> void:
	var chosen := card_1_item if slot == 1 else card_2_item
	if AudioManager:
		AudioManager.play_sfx("item_place")
	is_modal_active = false
	visible = false
	if chosen:
		skill_chosen.emit(chosen)
