class_name EventsScreen
extends Control

signal campaign_requested()
signal missions_requested()

@onready var patrol_status: Label = $Content/PatrolCard/PatrolStatus
@onready var patrol_button: Button = $Content/PatrolCard/PatrolButton

func _ready() -> void:
	_refresh_patrol()
	$Content/TowerCard/VBox/TowerButton.pressed.connect(func(): campaign_requested.emit())
	$Content/MissionsCard/VBox/MissionsButton.pressed.connect(func(): missions_requested.emit())
	patrol_button.pressed.connect(_claim_patrol)

func _refresh_patrol() -> void:
	if not SaveManager:
		patrol_status.text = "Rewards are unavailable."
		patrol_button.disabled = true
		return
	var status: Dictionary = SaveManager.get_patrol_reward_status()
	if bool(status.get("ready", false)):
		patrol_status.text = "Your patrol reward is ready to claim."
		patrol_button.text = "CLAIM GOLD"
		patrol_button.disabled = false
	else:
		var remaining: int = int(status.get("seconds_remaining", 0))
		patrol_status.text = "Next reward in %02d:%02d" % [remaining / 3600, (remaining % 3600) / 60]
		patrol_button.text = "COOLDOWN"
		patrol_button.disabled = true

func _claim_patrol() -> void:
	if not SaveManager:
		return
	var result: Dictionary = SaveManager.claim_patrol_rewards()
	if bool(result.get("ready", false)):
		patrol_status.text = "Claimed +%d Gold. Return after the patrol cooldown." % int(result.get("gold", 0))
		patrol_button.text = "CLAIMED"
		patrol_button.disabled = true
	else:
		_refresh_patrol()
