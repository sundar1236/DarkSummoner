class_name ShopScreen
extends Control

# Daily Shop Screen (Screen D - Ref Image 3)
# Features scalloped market awning, Chapter Pack (600% Value),
# Daily Shop 3x2 grid with 20% off discount tags and countdown timer,
# and bottom sub-tabs (Daily Shop, Gear Chest, Wish, Limited Offer, Top Up).

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

var remaining_seconds: int = 24484 # 06:48:04
var _elapsed: float = 0.0
var _toast_label: Label = null

func _ready() -> void:
	_setup_buttons()
	_setup_toast_label()
	if SaveManager:
		if SaveManager.chapter_pack_purchased and btn_chapter_pack:
			btn_chapter_pack.text = "PURCHASED"
			btn_chapter_pack.disabled = true
		if SaveManager.daily_free_energy_claimed and btn_item5:
			btn_item5.text = "CLAIMED"
			btn_item5.disabled = true

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
		btn_item3.pressed.connect(func(): _buy_daily_item(btn_item3, "storm_shard", 50, true, "⚡ Storm Shard x5 Acquired!"))
	if btn_item4:
		btn_item4.pressed.connect(func(): _buy_daily_item(btn_item4, "gold_key", 120, true, "🗝 Gold Key Acquired!"))
	if btn_item5:
		btn_item5.pressed.connect(func(): _claim_free_energy(btn_item5))
	if btn_item6:
		btn_item6.pressed.connect(func(): _buy_daily_item(btn_item6, "healing_elixir", 45, false, "🧪 Healing Elixir x3 Acquired!"))

	# Subtabs
	var tabs := [btn_tab_daily, btn_tab_chest, btn_tab_wish, btn_tab_limited, btn_tab_topup]
	var names := ["Daily Deals", "Gear Chest", "Wish", "Limited Offer", "Top Up"]
	for i in range(tabs.size()):
		var b: Button = tabs[i]
		var t_name: String = names[i]
		if b:
			b.pressed.connect(func():
				if AudioManager: AudioManager.play_sfx("ui_click")
				show_toast("Switched to: %s" % t_name)
				subtab_changed.emit(t_name)
			)

func _on_buy_chapter_pack() -> void:
	if SaveManager:
		if SaveManager.chapter_pack_purchased:
			show_toast("Chapter 1 Pack already purchased!")
			return
		SaveManager.add_gems(500)
		SaveManager.add_energy(50)
		SaveManager.add_gold(1500)
		SaveManager.chapter_pack_purchased = true
		SaveManager.save_profile()
	else:
		var shell = get_parent().get_parent() if get_parent() else null
		if shell and "top_bar" in shell and shell.top_bar:
			shell.top_bar.add_gems(500)
			shell.top_bar.add_energy(50)
			shell.top_bar.add_gold(1500)
			
	if AudioManager: AudioManager.play_sfx("upgrade")
	if btn_chapter_pack:
		btn_chapter_pack.text = "PURCHASED"
		btn_chapter_pack.disabled = true
	show_toast("🎉 Chapter 1 Pack Claimed! (+500 💎, +50 ⚡, +1,500 🪙)")
	item_purchased.emit("chapter_pack_1")

func _buy_daily_item(btn: Button, item_id: String, cost: int, is_gems: bool, success_msg: String) -> void:
	var success := false
	if SaveManager:
		if is_gems:
			success = SaveManager.spend_gems(cost)
		else:
			success = SaveManager.spend_gold(cost)
	else:
		var shell = get_parent().get_parent() if get_parent() else null
		if shell and "top_bar" in shell and shell.top_bar:
			success = shell.top_bar.spend_gems(cost) if is_gems else shell.top_bar.spend_gold(cost)
		else:
			success = true # Offline fallback
		
	if success:
		if AudioManager: AudioManager.play_sfx("shop_buy")
		btn.text = "SOLD OUT"
		btn.disabled = true
		show_toast(success_msg)
		item_purchased.emit(item_id)
	else:
		if AudioManager: AudioManager.play_sfx("ui_error")
		show_toast("Not enough %s! (Need %d)" % ["Gems" if is_gems else "Gold", cost])

func _claim_free_energy(btn: Button) -> void:
	if SaveManager:
		if SaveManager.daily_free_energy_claimed:
			show_toast("Free energy already claimed today!")
			return
		SaveManager.add_energy(20)
		SaveManager.daily_free_energy_claimed = true
		SaveManager.save_profile()
	else:
		var shell = get_parent().get_parent() if get_parent() else null
		if shell and "top_bar" in shell and shell.top_bar:
			shell.top_bar.add_energy(20)
			
	if AudioManager: AudioManager.play_sfx("shop_buy")
	btn.text = "CLAIMED"
	btn.disabled = true
	show_toast("⚡ Claimed +20 Free Energy!")
	item_purchased.emit("free_energy")

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 1.0:
		_elapsed -= 1.0
		if remaining_seconds > 0:
			remaining_seconds -= 1
			_update_timer_text()

func _update_timer_text() -> void:
	var h := remaining_seconds / 3600
	var m := (remaining_seconds % 3600) / 60
	var s := remaining_seconds % 60
	if timer_label:
		timer_label.text = "Refresh in %02d:%02d:%02d" % [h, m, s]
