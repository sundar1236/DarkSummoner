class_name ShopScreen
extends Control

# Daily Shop Screen (Screen D - Ref Image 3)
# Daily rewards and purchasable run supplies. Real-money purchases remain disabled until billing is integrated.

signal item_purchased(item_id: String)
signal subtab_changed(tab_name: String)

@onready var timer_label: Label = $ScrollContainer/VBox/DailyShopSection/DailyHeader/TimerLabel
@onready var btn_chapter_pack: Button = $ScrollContainer/VBox/ChapterPackCard/Content/BuyBtn

# Daily Items
@onready var btn_item1: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item1/VBox/Btn
@onready var btn_item2: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item2/VBox/Btn
@onready var btn_item3: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item3/VBox/Btn
@onready var btn_item4: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item4/VBox/Btn
@onready var btn_item5: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item5/VBox/Btn
@onready var btn_item6: Button = $ScrollContainer/VBox/DailyShopSection/Grid3x2/Item6/VBox/Btn

# Bottom Subtabs
@onready var btn_tab_daily: Button = $BottomSubTabs/HBox/Tab1
@onready var btn_tab_chest: Button = $BottomSubTabs/HBox/Tab2
@onready var btn_tab_wish: Button = $BottomSubTabs/HBox/Tab3
@onready var btn_tab_limited: Button = $BottomSubTabs/HBox/Tab4
@onready var btn_tab_topup: Button = $BottomSubTabs/HBox/Tab5

var remaining_seconds: int = 86400
var _elapsed: float = 0.0
var _toast_label: Label = null

func _ready() -> void:
	_setup_buttons()
	_setup_toast_label()
	if SaveManager:
		SaveManager.refresh_daily_shop_state()
		remaining_seconds = SaveManager.get_seconds_until_daily_reset()
		if btn_chapter_pack:
			btn_chapter_pack.text = "STORE UNAVAILABLE"
			btn_chapter_pack.disabled = true
		_refresh_daily_offer_buttons()
	_update_timer_text()

func _setup_toast_label() -> void:
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.custom_minimum_size = Vector2(400, 48)
	_toast_label.anchors_preset = PRESET_CENTER
	_toast_label.position = Vector2(160, 460)
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

func _setup_buttons() -> void:
	if btn_chapter_pack:
		btn_chapter_pack.pressed.connect(_on_buy_chapter_pack)
		
	if btn_item1:
		btn_item1.pressed.connect(func(): _buy_daily_item(btn_item1, "fire_rune", 80, false, "🔥 Fire Rune Acquired!"))
	if btn_item2:
		btn_item2.pressed.connect(func(): _buy_daily_item(btn_item2, "wolf_core", 100, false, "🐺 Wolf Core Acquired!"))
	if btn_item3:
		btn_item3.pressed.connect(func(): _buy_daily_item(btn_item3, "storm_shard", 50, true, "⚡ +5 Storm Reaper Shards"))
	if btn_item4:
		btn_item4.pressed.connect(func(): _buy_daily_item(btn_item4, "gold_cache", 120, true, "🪙 +300 Profile Gold"))
	if btn_item5:
		btn_item5.pressed.connect(func(): _claim_free_energy(btn_item5))
	if btn_item6:
		btn_item6.pressed.connect(func(): _buy_daily_item(btn_item6, "healing_elixir", 45, false, "🧪 +2 Healing Potions next run"))

	# Tabs without implemented backing systems are visibly unavailable, not fake navigation.
	var unavailable_tabs: Array[Button] = [btn_tab_chest, btn_tab_wish, btn_tab_limited, btn_tab_topup]
	for tab in unavailable_tabs:
		if tab:
			tab.disabled = true
			tab.tooltip_text = "Not available in this build"
	if btn_tab_daily:
		btn_tab_daily.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			subtab_changed.emit("Daily Deals")
		)

func _on_buy_chapter_pack() -> void:
	# Do not grant paid currency until a platform billing provider confirms a purchase.
	if btn_chapter_pack:
		btn_chapter_pack.disabled = true
		btn_chapter_pack.text = "STORE UNAVAILABLE"
	show_toast("Real-money purchases are not enabled in this build.")

func _buy_daily_item(btn: Button, item_id: String, cost: int, is_gems: bool, success_msg: String) -> void:
	if not SaveManager:
		show_toast("Shop inventory is unavailable.")
		return
	if SaveManager.is_daily_offer_purchased(item_id):
		btn.text = "SOLD OUT"
		btn.disabled = true
		return

	var valid_offer := item_id in ["fire_rune", "wolf_core", "storm_shard", "gold_cache", "healing_elixir"]
	if not valid_offer:
		show_toast("This offer is unavailable.")
		return
	var paid := SaveManager.spend_gems(cost) if is_gems else SaveManager.spend_gold(cost)
	if not paid:
		if AudioManager: AudioManager.play_sfx("ui_error")
		show_toast("Not enough %s! (Need %d)" % ["Gems" if is_gems else "Gold", cost])
		return

	match item_id:
		"fire_rune", "wolf_core":
			SaveManager.add_shop_item(item_id, 1)
		"healing_elixir":
			SaveManager.add_shop_item(item_id, 2)
		"storm_shard":
			SaveManager.add_character_shards("storm_reaper", 5)
		"gold_cache":
			SaveManager.add_gold(300)
	SaveManager.mark_daily_offer_purchased(item_id)
	if AudioManager: AudioManager.play_sfx("shop_buy")
	btn.text = "SOLD OUT"
	btn.disabled = true
	show_toast(success_msg)
	item_purchased.emit(item_id)

func _claim_free_energy(btn: Button) -> void:
	if not SaveManager or not SaveManager.claim_daily_free_energy(20):
		btn.text = "CLAIMED"
		btn.disabled = true
		show_toast("Free energy has already been claimed today.")
		return
	if AudioManager: AudioManager.play_sfx("shop_buy")
	btn.text = "CLAIMED"
	btn.disabled = true
	show_toast("⚡ Claimed +20 Free Energy!")
	item_purchased.emit("free_energy")

func _refresh_daily_offer_buttons() -> void:
	if not SaveManager:
		return
	var offers: Array[Dictionary] = [
		{"button": btn_item1, "id": "fire_rune"},
		{"button": btn_item2, "id": "wolf_core"},
		{"button": btn_item3, "id": "storm_shard"},
		{"button": btn_item4, "id": "gold_cache"},
		{"button": btn_item6, "id": "healing_elixir"}
	]
	for offer in offers:
		var offer_button: Button = offer["button"]
		if SaveManager.is_daily_offer_purchased(str(offer["id"])):
			offer_button.text = "SOLD OUT"
			offer_button.disabled = true
	if SaveManager.daily_free_energy_claimed and btn_item5:
		btn_item5.text = "CLAIMED"
		btn_item5.disabled = true

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.0:
		_elapsed -= 1.0
		remaining_seconds = SaveManager.get_seconds_until_daily_reset() if SaveManager else maxi(0, remaining_seconds - 1)
		if remaining_seconds <= 1 and SaveManager:
			SaveManager.refresh_daily_shop_state()
			_refresh_daily_offer_buttons()
		_update_timer_text()

func _update_timer_text() -> void:
	var h := remaining_seconds / 3600
	var m := (remaining_seconds % 3600) / 60
	var s := remaining_seconds % 60
	if timer_label:
		timer_label.text = "Refresh in %02d:%02d:%02d" % [h, m, s]
