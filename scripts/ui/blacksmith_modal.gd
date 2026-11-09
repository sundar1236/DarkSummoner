class_name BlacksmithModal
extends Control

signal gear_upgraded(slot_name: String, new_level: int)
signal closed()

@export var btn_upgrade_weapon: Button
@export var btn_upgrade_armor: Button
@export var btn_upgrade_ring: Button
@export var btn_close: Button
@export var lbl_gold_balance: Label

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
