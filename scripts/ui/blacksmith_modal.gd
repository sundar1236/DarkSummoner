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
	if not SaveManager: return
	if lbl_gold_balance:
		lbl_gold_balance.text = "Available Gold: 🪙 %s" % _format_num(SaveManager.profile_gold)
	if btn_upgrade_weapon:
		var lvl: int = SaveManager.equipment_levels.get("weapon", 60)
		btn_upgrade_weapon.text = "Forge Weapon (Lv.%d -> %d) [🪙 300]" % [lvl, lvl + 1]
	if btn_upgrade_armor:
		var lvl: int = SaveManager.equipment_levels.get("armor", 60)
		btn_upgrade_armor.text = "Reinforce Armor (Lv.%d -> %d) [🪙 250]" % [lvl, lvl + 1]
	if btn_upgrade_ring:
		var lvl: int = SaveManager.equipment_levels.get("ring", 58)
		btn_upgrade_ring.text = "Infuse Ring (Lv.%d -> %d) [🪙 200]" % [lvl, lvl + 1]

func _upgrade_slot(slot: String) -> void:
	if not SaveManager: return
	if SaveManager.upgrade_equipment_slot(slot):
		var n_lvl: int = SaveManager.equipment_levels.get(slot, 1)
		refresh_modal()
		gear_upgraded.emit(slot, n_lvl)
	else:
		if AudioManager: AudioManager.play_sfx("ui_error")

func _format_num(val: int) -> String:
	var thousands := val / 1000
	var rem := val % 1000
	return "%d,%03d" % [thousands, rem]
