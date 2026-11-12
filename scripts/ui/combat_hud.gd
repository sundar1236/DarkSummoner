class_name CombatHUD
extends Control

# Coordinates the Combat HUD elements:
# - Clean, responsive single directional movement pad with inner floating thumbstick ring
# - Ergonomic action buttons (Dodge, Skill, Potion) with cooldown overlays
# - Reactive Top Bar (Smooth XP bar with Tween, Level badge, HP bar, Game speed 1x/2x, Pause, Currencies)
# - Right-Side Objective Column (Stage timer, Wave progress, Revive counter)
# - In-run Valkyrie Skill Draft Modal integration
# - Full-screen Combat Feedback toast announcements (Level Up, Skill Acquired, Boss Spawn, Boss Cleared)
# - Hardware Safe Area insets handling

signal pause_requested()

const SafeAreaHelper = preload("res://scripts/ui/safe_area_helper.gd")

@export var move_joystick: VirtualJoystick
@export var skill_draft_modal: SkillDraftModal = null
@export var feedback_banner: PanelContainer = null
@export var feedback_label: Label = null

@export var player_hp_bar: ProgressBar
@export var player_hp_label: Label
@export var floor_level_label: Label
@export var floor_theme_label: Label
@export var gold_label: Label
@export var shades_label: Label

@export var boss_bar: ProgressBar
@export var boss_label: Label

@export var btn_dodge: Button
@export var btn_skill: Button
@export var btn_potion: Button
@export var potion_count_label: Label
@export var btn_pause: Button
@export var btn_speed: Button = null
@export var xp_bar: ProgressBar = null
@export var xp_label: Label = null
@export var timer_label: Label = null
@export var wave_objective_label: Label = null
@export var revive_objective_label: Label = null

var player_ref: PlayerController
var battle_seconds: float = 0.0
var current_speed_scale: float = 1.0
var feedback_tween: Tween = null

func _process(delta: float) -> void:
	battle_seconds += delta
	if timer_label:
		var mins := int(battle_seconds) / 60
		var secs := int(battle_seconds) % 60
		timer_label.text = "%02d:%02d" % [mins, secs]

func _ready() -> void:
	_apply_safe_area()
	if not get_tree().root.size_changed.is_connected(_apply_safe_area):
		get_tree().root.size_changed.connect(_apply_safe_area)
		
	if btn_dodge:
		btn_dodge.icon = TextureLoader.get_texture("res://assets/art/ui/btn_dash.png")
		btn_dodge.expand_icon = true
	if btn_skill:
		btn_skill.icon = TextureLoader.get_texture("res://assets/art/ui/btn_skill.png")
		btn_skill.expand_icon = true
	if btn_potion:
		btn_potion.icon = TextureLoader.get_texture("res://assets/art/ui/btn_potion.png")
		btn_potion.expand_icon = true
		
	_connect_signals()
	_update_displays()

func setup(player: PlayerController) -> void:
	player_ref = player
	if is_instance_valid(player_ref):
		player_ref.move_joystick = move_joystick
		player_ref.dodge_cooldown_updated.connect(_on_dodge_cooldown)
		player_ref.skill_cooldown_updated.connect(_on_skill_cooldown)

func _connect_signals() -> void:
	if btn_dodge:
		btn_dodge.pressed.connect(_on_dodge_pressed)
	if btn_skill:
		btn_skill.pressed.connect(_on_skill_pressed)
	if btn_potion:
		btn_potion.pressed.connect(_on_potion_pressed)
	if btn_pause:
		btn_pause.pressed.connect(func():
			hide_announcement()
			pause_requested.emit()
		)
	if btn_speed:
		btn_speed.pressed.connect(_on_speed_toggle)
		
	GameManager.player_hp_changed.connect(_on_hp_changed)
	GameManager.gold_changed.connect(func(g: int): if gold_label: gold_label.text = str(g))
	GameManager.run_shades_changed.connect(func(s: int): if shades_label: shades_label.text = str(s))
	GameManager.potion_count_changed.connect(func(p: int): if potion_count_label: potion_count_label.text = "x%d" % p)
	
	# XP and Level Progression signals
	GameManager.run_xp_changed.connect(_on_xp_changed)
	GameManager.run_level_up.connect(_on_level_up)
	GameManager.run_skill_applied.connect(_on_skill_applied)
	GameManager.run_skill_evolved.connect(_on_skill_evolved)

func _update_displays() -> void:
	if floor_level_label:
		var lvl_str := "BOSS" if GameManager.level_number == 5 else ("Level %d" % GameManager.level_number)
		floor_level_label.text = "FLOOR %d — %s" % [GameManager.floor_number, lvl_str]
	if gold_label:
		gold_label.text = str(GameManager.run_gold)
	if shades_label:
		shades_label.text = str(GameManager.run_shades)
	if potion_count_label:
		potion_count_label.text = "x%d" % GameManager.potions
	_on_hp_changed(GameManager.player_hp, GameManager.player_max_hp)
	_on_xp_changed(GameManager.run_xp, GameManager.run_xp_to_next)
	update_revives_display()


func set_floor_theme_name(theme_name: String) -> void:
	if floor_theme_label:
		floor_theme_label.text = theme_name.to_upper()


func _on_speed_toggle() -> void:
	current_speed_scale = 2.0 if current_speed_scale == 1.0 else 1.0
	Engine.time_scale = current_speed_scale
	if btn_speed:
		btn_speed.text = "x%d" % int(current_speed_scale)
	if AudioManager:
		AudioManager.play_sfx("ui_click")

func _exit_tree() -> void:
	Engine.time_scale = 1.0

func _on_hp_changed(curr: float, max_v: float) -> void:
	if player_hp_bar:
		player_hp_bar.max_value = max_v
		var tween := create_tween()
		tween.tween_property(player_hp_bar, "value", curr, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if player_hp_label:
		player_hp_label.text = "%d / %d" % [int(curr), int(max_v)]

func _on_xp_changed(curr_xp: float, max_xp: float) -> void:
	if xp_bar:
		xp_bar.max_value = max_xp
		var tween := create_tween()
		tween.tween_property(xp_bar, "value", curr_xp, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if xp_label:
		xp_label.text = "XP %d / %d (Lv.%d)" % [int(curr_xp), int(max_xp), GameManager.run_player_level]

func _on_level_up(new_lvl: int) -> void:
	show_announcement("✦ LEVEL UP! (Lv.%d) Choose a Blessing ✦" % new_lvl, 2.2, Color(1.0, 0.88, 0.3))
	if skill_draft_modal:
		# Brief delay to allow level-up chime, then present draft modal
		get_tree().create_timer(0.35, true, false, true).timeout.connect(func():
			if is_instance_valid(skill_draft_modal):
				skill_draft_modal.show_draft()
		)

func _on_skill_applied(skill_id: String, new_lvl: int) -> void:
	var skill_data := RunSkillDatabase.get_skill(skill_id)
	var s_name := skill_data.name if skill_data else skill_id.capitalize()
	show_announcement("✦ Blessing Acquired: %s (Rank %d) ✦" % [s_name, new_lvl], 2.4, Color(0.4, 1.0, 0.6))
	update_revives_display()


func _on_skill_evolved(_evolution_id: String, evolution_name: String) -> void:
	show_announcement("✦ SKILL EVOLVED: %s ✦" % evolution_name, 3.0, Color(1.0, 0.72, 0.25))

func update_wave_progress(current_w: int, total_w: int, enemies_left: int = -1) -> void:
	if wave_objective_label:
		if enemies_left >= 0:
			wave_objective_label.text = "Enemies: %d" % enemies_left
		else:
			wave_objective_label.text = "Wave %d/%d" % [current_w, total_w]

func update_revives_display() -> void:
	if revive_objective_label:
		var revs: int = GameManager.get_available_revives()
		revive_objective_label.text = "Revives: %d" % revs
		revive_objective_label.modulate = Color(0.4, 1.0, 0.6) if revs > 0 else Color(0.9, 0.5, 0.5)

func show_announcement(msg: String, duration: float = 2.0, col: Color = Color.WHITE) -> void:
	if not feedback_banner or not feedback_label:
		return
	if get_tree().paused:
		return
		
	feedback_label.text = msg
	feedback_label.modulate = col
	feedback_banner.visible = true
	feedback_banner.scale = Vector2(0.85, 0.85)
	feedback_banner.modulate.a = 0.0
	
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()
		
	feedback_tween = create_tween()
	# Pop in
	feedback_tween.tween_property(feedback_banner, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	feedback_tween.parallel().tween_property(feedback_banner, "modulate:a", 1.0, 0.15)
	# Linger
	feedback_tween.tween_interval(duration)
	# Fade out
	feedback_tween.tween_property(feedback_banner, "modulate:a", 0.0, 0.3)
	feedback_tween.tween_callback(func(): feedback_banner.visible = false)

func hide_announcement() -> void:
	if feedback_tween and feedback_tween.is_valid():
		feedback_tween.kill()
	if feedback_banner:
		feedback_banner.visible = false
		feedback_banner.modulate.a = 0.0

func _on_dodge_pressed() -> void:
	if is_instance_valid(player_ref):
		player_ref.trigger_dodge()

func _on_skill_pressed() -> void:
	if is_instance_valid(player_ref):
		player_ref.trigger_active_skill()

func _on_potion_pressed() -> void:
	GameManager.use_potion()

func _on_dodge_cooldown(current: float, _max_v: float) -> void:
	if btn_dodge:
		if current > 0.0:
			btn_dodge.text = "%.1f" % current
			btn_dodge.disabled = true
		else:
			btn_dodge.text = ""
			btn_dodge.disabled = false

func _on_skill_cooldown(current: float, _max_v: float) -> void:
	if btn_skill:
		if current > 0.0:
			btn_skill.text = "%.1f" % current
			btn_skill.disabled = true
		else:
			btn_skill.text = ""
			btn_skill.disabled = false

func _apply_safe_area() -> void:
	var safe: Dictionary = SafeAreaHelper.get_safe_margins()
	var top_inset: float = safe.get("top", 46.0)
	var bot_inset: float = safe.get("bottom", 28.0)
	var right_inset: float = safe.get("right", 14.0)
	var left_inset: float = safe.get("left", 14.0)
	
	var top_container := get_node_or_null("TopContainer") as Control
	if top_container:
		top_container.offset_top = top_inset + 4.0
		top_container.offset_bottom = top_inset + 150.0
		top_container.offset_left = left_inset + 6.0
		top_container.offset_right = -(right_inset + 6.0)
		
	var right_col := get_node_or_null("RightObjectiveColumn") as Control
	if right_col:
		right_col.offset_top = top_inset + 160.0
		right_col.offset_right = -(right_inset + 6.0)
		right_col.offset_left = -(right_inset + 86.0)
		
	var action_btns := get_node_or_null("ActionButtons") as Control
	if action_btns:
		action_btns.offset_bottom = -(bot_inset + 6.0)
		action_btns.offset_top = -(bot_inset + 290.0)
		action_btns.offset_right = -(right_inset + 6.0)
