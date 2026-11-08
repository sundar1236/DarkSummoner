class_name GameOverView
extends Control

# Defeat / Floor Retry modal.
# Preserves permanent Shades and restarts the player at Level 1 of the same floor.
# Offers Revive when available via divine blessings or talent perks.

signal retry_requested()
signal sanctuary_requested()
signal revive_requested()

@export var lbl_title: Label
@export var lbl_floor_info: Label
@export var lbl_shades_saved: Label
@export var btn_revive: Button = null
@export var btn_retry: Button
@export var btn_sanctuary: Button

func _ready() -> void:
	if btn_revive:
		btn_revive.pressed.connect(func():
			if GameManager.use_revive():
				revive_requested.emit()
		)
	if btn_retry:
		btn_retry.pressed.connect(func(): retry_requested.emit())
	if btn_sanctuary:
		btn_sanctuary.pressed.connect(func(): sanctuary_requested.emit())

func setup(floor_num: int, level_num: int) -> void:
	if lbl_title:
		if level_num == 5:
			lbl_title.text = "SLAIN BY LORD MALAKAR"
		else:
			lbl_title.text = "FALLEN IN THE ABYSS"
			
	if lbl_floor_info:
		lbl_floor_info.text = "Floor %d — Level %d\nRetrying restarts at Floor %d, Level 1." % [floor_num, level_num, floor_num]
		
	if lbl_shades_saved:
		lbl_shades_saved.text = "Permanent Shades Balance: %d\n(All shades earned are preserved)" % SaveManager.shades
		
	var revs: int = GameManager.get_available_revives()
	if btn_revive:
		btn_revive.visible = (revs > 0)
		btn_revive.text = "✦ REVIVE HERO (%d Remaining) ✦" % revs
