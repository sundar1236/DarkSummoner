class_name BlacksmithModal
extends Control

signal gear_upgraded(slot_name: String, new_level: int)
signal gear_purchased(item_id: String)
signal closed()

@export var btn_upgrade_weapon: Button
@export var btn_upgrade_armor: Button
@export var btn_upgrade_ring: Button
@export var btn_upgrade_helmet: Button
@export var btn_upgrade_boots: Button
@export var btn_upgrade_amulet: Button
@export var btn_close: Button
@export var lbl_gold_balance: Label
@export var shop_items_container: VBoxContainer

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			visible = false
			closed.emit()
		)
	if btn_upgrade_weapon:
		btn_upgrade_weapon.pressed.connect(func(): _upgrade_slot("weapon"))
	if btn_upgrade_armor:
		btn_upgrade_armor.pressed.connect(func(): _upgrade_slot("armor"))
	if btn_upgrade_ring:
		btn_upgrade_ring.pressed.connect(func(): _upgrade_slot("ring"))
	if btn_upgrade_helmet:
		btn_upgrade_helmet.pressed.connect(func(): _upgrade_slot("helmet"))
	if btn_upgrade_boots:
		btn_upgrade_boots.pressed.connect(func(): _upgrade_slot("boots"))
	if btn_upgrade_amulet:
		btn_upgrade_amulet.pressed.connect(func(): _upgrade_slot("amulet"))
		
	refresh_modal()
	if SaveManager:
		SaveManager.gold_changed.connect(func(_g): refresh_modal())
		SaveManager.profile_changed.connect(refresh_modal)

func open_modal() -> void:
	visible = true
	refresh_modal()
	if AudioManager: AudioManager.play_sfx("ui_click")

func refresh_modal() -> void:
	if not SaveManager:
		return
	if lbl_gold_balance:
		lbl_gold_balance.text = "Available Gold: 🪙 %s" % _format_num(SaveManager.profile_gold)
	_refresh_upgrade_button(btn_upgrade_weapon, "weapon", "Forge Weapon")
	_refresh_upgrade_button(btn_upgrade_armor, "armor", "Reinforce Armor")
	_refresh_upgrade_button(btn_upgrade_ring, "ring", "Infuse Ring")
	_refresh_upgrade_button(btn_upgrade_helmet, "helmet", "Temper Helmet")
	_refresh_upgrade_button(btn_upgrade_boots, "boots", "Reinforce Boots")
	_refresh_upgrade_button(btn_upgrade_amulet, "amulet", "Enchant Amulet")
	_refresh_shop_items()

func _refresh_upgrade_button(button: Button, slot_name: String, action_name: String) -> void:
	if not button or not SaveManager:
		return
	var item: ItemInstance = SaveManager.get_equipped_gear(slot_name)
	if not item or not item.data:
		button.text = "No %s equipped" % slot_name
		button.disabled = true
		return
	var cost: int = SaveManager.get_gear_upgrade_cost(slot_name)
	button.text = "%s: %s Lv.%d → %d [🪙 %d]" % [
		action_name, item.data.name, item.upgrade_level, item.upgrade_level + 1, cost
	]
	button.disabled = SaveManager.profile_gold < cost

func _refresh_shop_items() -> void:
	if not shop_items_container:
		return
	for child in shop_items_container.get_children():
		shop_items_container.remove_child(child)
		child.queue_free()

	var available_items: Array[ItemData] = []
	for item_data in ItemDatabase.get_all_items():
		if item_data.equipment_slot.is_empty() or SaveManager.has_gear_item(item_data.id):
			continue
		available_items.append(item_data)
	available_items.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.tier == b.tier:
			return a.price < b.price
		return a.tier < b.tier
	)

	if available_items.is_empty():
		var empty_label := Label.new()
		empty_label.text = "All available forge designs collected."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shop_items_container.add_child(empty_label)
		return

	for item_data in available_items:
		var item_id := item_data.id
		var button := Button.new()
		button.custom_minimum_size = Vector2(420, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text = "%s · %s · T%d · 🪙 %d" % [
			item_data.name,
			item_data.equipment_slot.capitalize(),
			item_data.tier,
			item_data.price
		]
		button.tooltip_text = item_data.description
		button.add_theme_font_size_override("font_size", 15)
		button.disabled = SaveManager.profile_gold < item_data.price
		button.pressed.connect(func(): _purchase_gear(item_id))
		shop_items_container.add_child(button)


func _purchase_gear(item_id: String) -> void:
	if not SaveManager:
		return
	if SaveManager.buy_gear_item(item_id):
		refresh_modal()
		gear_purchased.emit(item_id)
	else:
		if AudioManager:
			AudioManager.play_sfx("ui_error")


func _upgrade_slot(slot: String) -> void:
	if not SaveManager:
		return
	if SaveManager.upgrade_equipped_gear(slot):
		var item: ItemInstance = SaveManager.get_equipped_gear(slot)
		refresh_modal()
		if item:
			gear_upgraded.emit(slot, item.upgrade_level)
	else:
		if AudioManager:
			AudioManager.play_sfx("ui_error")


func _format_num(val: int) -> String:
	var thousands := val / 1000
	var rem := val % 1000
	return "%d,%03d" % [thousands, rem]
