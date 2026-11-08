class_name EnergyReplenishModal
extends Control

signal energy_purchased(amount: int)
signal closed()

@export var lbl_current_energy: Label
@export var lbl_timer: Label
@export var btn_free: Button
@export var btn_gems: Button
@export var btn_ad: Button
@export var btn_close: Button

var _timer_secs: int = 245
var _t: float = 0.0

func _ready() -> void:
	if btn_close:
		btn_close.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			visible = false
			closed.emit()
		)
	if btn_free:
		btn_free.pressed.connect(_on_claim_free)
	if btn_gems:
		btn_gems.pressed.connect(_on_buy_gems)
	if btn_ad:
		btn_ad.pressed.connect(_on_watch_ad)
		
	refresh_modal()
	if SaveManager:
		SaveManager.energy_changed.connect(func(_c, _m): refresh_modal())

func open_modal() -> void:
	visible = true
	refresh_modal()
	if AudioManager: AudioManager.play_sfx("ui_click")

func refresh_modal() -> void:
	var cur := SaveManager.energy if SaveManager else 45
	var max_e := SaveManager.max_energy if SaveManager else 50
	if lbl_current_energy:
		lbl_current_energy.text = "Current Energy: %d / %d ⚡" % [cur, max_e]
		
	if btn_free and SaveManager:
		if SaveManager.daily_free_energy_claimed:
			btn_free.text = "CLAIMED TODAY"
			btn_free.disabled = true
		else:
			btn_free.text = "CLAIM +20 FREE ⚡"
			btn_free.disabled = false

func _on_claim_free() -> void:
	if SaveManager and not SaveManager.daily_free_energy_claimed:
		SaveManager.add_energy(20)
		SaveManager.daily_free_energy_claimed = true
		SaveManager.save_profile()
		if AudioManager: AudioManager.play_sfx("upgrade")
		refresh_modal()
		energy_purchased.emit(20)

func _on_buy_gems() -> void:
	if SaveManager:
		if SaveManager.spend_gems(50):
			SaveManager.add_energy(30)
			if AudioManager: AudioManager.play_sfx("shop_buy")
			refresh_modal()
			energy_purchased.emit(30)
		else:
			if AudioManager: AudioManager.play_sfx("ui_error")

func _on_watch_ad() -> void:
	if SaveManager:
		SaveManager.add_energy(15)
		if AudioManager: AudioManager.play_sfx("upgrade")
		refresh_modal()
		energy_purchased.emit(15)

func _process(delta: float) -> void:
	if not visible: return
	_t += delta
	if _t >= 1.0:
		_t -= 1.0
		if _timer_secs > 0:
			_timer_secs -= 1
		else:
			_timer_secs = 300
			if SaveManager and SaveManager.energy < SaveManager.max_energy:
				SaveManager.add_energy(1)
		if lbl_timer:
			lbl_timer.text = "Next +1 Energy in: %02d:%02d" % [_timer_secs / 60, _timer_secs % 60]
