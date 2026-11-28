class_name StoryIntro
extends Control

# 4-Act Lore Chronicle ("Chronicles of Aethelgard") for Dark Summoner: Abyssal Altar.
# Features segmented chapter indicator, framed dark-fantasy illustrations with gentle pan,
# narrative card, NEXT CHAPTER / ENTER THE TOWER CTA, and safe tween lifecycle management.

signal story_completed()

@export var scene_texture_rect: TextureRect
@export var act_num_label: Label
@export var title_label: Label
@export var subtitle_label: Label
@export var narrative_label: Label
@export var act_dots_container: HBoxContainer
@export var segments_container: HBoxContainer
@export var btn_skip: Button
@export var btn_next: Button
@export var progress_bar: ProgressBar

const ACT_DURATION: float = 10.0

var current_act_index: int = 0
var act_timer: float = 0.0
var is_active: bool = false
var has_finished: bool = false

var _transition_tween: Tween = null
var _pan_tween: Tween = null
var _fade_tween: Tween = null
var _texture_cache: Dictionary = {}

var acts: Array[Dictionary] = [
	{
		"act_num": "—  ACT I  —",
		"title": "THE FALL OF AETHELGARD",
		"subtitle": "When the heavens shattered, the kingdom fell.",
		"text": "When the ancient seals began to break, the sky turned black and the stars vanished. Abyssal creatures poured from beneath the kingdom, devouring cities, armies, and everything that stood in their path.\nThe Tower awakened. And with it, an ancient power that had been buried for centuries.\n\nOne hunter survived the fall. One soul was chosen to enter the abyss.",
		"cta": "NEXT CHAPTER ▸",
		"image_path": "res://assets/art/story/story_act_1_fall.png"
	},
	{
		"act_num": "—  ACT II  —",
		"title": "THE LAST HUNTER",
		"subtitle": "From the ashes, one soul remained.",
		"text": "The kingdom was gone. Its armies, its kings, and its people had vanished into the abyss. Among the ruins, one hunter still breathed. With no home left to defend and no hope of rescue, the survivor gathered what remained — a blade, a few supplies, and the will to keep moving.\n\nFar beyond the ashes, the Abyssal Tower stood untouched. The hunter turned toward it.",
		"cta": "NEXT CHAPTER ▸",
		"image_path": "res://assets/art/story/story_act_2_hunter.png"
	},
	{
		"act_num": "—  ACT III  —",
		"title": "THE AWAKENING",
		"subtitle": "The power within the seal answered his call.",
		"text": "Deep beneath the ruins, the hunter discovered a sanctuary untouched by the destruction above. At its center stood an ancient altar, bound by chains and covered in forgotten runes.\n\nWhen the hunter reached for the seal, the chamber trembled. Golden light erupted from the stone, and shadows twisted around the altar. Something ancient had recognized the hunter. The seal was no longer dormant.",
		"cta": "NEXT CHAPTER ▸",
		"image_path": "res://assets/art/story/story_act_3_awakening.png"
	},
	{
		"act_num": "—  ACT IV  —",
		"title": "INTO THE ABYSS",
		"subtitle": "Beyond this gate, survival is the only salvation.",
		"text": "The ancient tower stood before the hunter, its gates open for the first time in centuries. The seal had chosen its bearer. The power within was no longer sleeping. Beyond the threshold lay endless chambers filled with monsters, forgotten treasures, and the remnants of a world swallowed by darkness.\n\nThere would be no turning back. The descent begins.",
		"cta": "ENTER THE TOWER ▸",
		"image_path": "res://assets/art/story/story_act_4_abyss.png"
	}
]


func _ready() -> void:
	if btn_skip and not btn_skip.pressed.is_connected(_finish_story):
		btn_skip.pressed.connect(_finish_story)
	if btn_next and not btn_next.pressed.is_connected(_on_next_pressed):
		btn_next.pressed.connect(_on_next_pressed)


func _exit_tree() -> void:
	_kill_tweens()


func _get_act_texture(img_path: String) -> Texture2D:
	if _texture_cache.has(img_path) and _texture_cache[img_path] != null:
		return _texture_cache[img_path]
	var tex := TextureLoader.get_texture(img_path)
	if tex:
		_texture_cache[img_path] = tex
	return tex


func _kill_tweens() -> void:
	for tw in [_transition_tween, _pan_tween, _fade_tween]:
		if tw and is_instance_valid(tw):
			tw.kill()
	_transition_tween = null
	_pan_tween = null
	_fade_tween = null


func start_story() -> void:
	_kill_tweens()
	modulate.a = 1.0
	is_active = true
	has_finished = false
	current_act_index = 0
	act_timer = 0.0

	if AudioManager:
		AudioManager.play_music("horror_menu")
		AudioManager.play_ambience(true)

	_display_act(0, true)


func _process(delta: float) -> void:
	if not is_active or has_finished or not is_visible_in_tree():
		return

	act_timer += delta
	if progress_bar:
		var overall_progress := (float(current_act_index) + (act_timer / ACT_DURATION)) / float(acts.size())
		progress_bar.value = clampf(overall_progress, 0.0, 1.0)

	if act_timer >= ACT_DURATION:
		_advance_act()


func _on_next_pressed() -> void:
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_advance_act()


func _advance_act() -> void:
	if has_finished:
		return
	act_timer = 0.0
	current_act_index += 1
	if current_act_index >= acts.size():
		_finish_story()
	else:
		_display_act(current_act_index, false)


func _apply_act_content(index: int, tex: Texture2D) -> void:
	if index < 0 or index >= acts.size():
		return
	var data: Dictionary = acts[index]
	if is_instance_valid(scene_texture_rect) and tex:
		scene_texture_rect.texture = tex
	if is_instance_valid(act_num_label):
		act_num_label.text = str(data.get("act_num", ""))
	if is_instance_valid(title_label):
		title_label.text = str(data.get("title", ""))
	if is_instance_valid(subtitle_label):
		subtitle_label.text = str(data.get("subtitle", ""))
	if is_instance_valid(narrative_label):
		narrative_label.text = str(data.get("text", ""))
	if is_instance_valid(btn_next):
		btn_next.text = str(data.get("cta", "NEXT CHAPTER ▸"))
	_update_indicators(index)


func _display_act(index: int, instant: bool) -> void:
	if index < 0 or index >= acts.size():
		return

	var data: Dictionary = acts[index]
	var tex: Texture2D = _get_act_texture(str(data.get("image_path", "")))

	if _transition_tween and is_instance_valid(_transition_tween):
		_transition_tween.kill()
		_transition_tween = null

	if instant or not is_instance_valid(scene_texture_rect) or not is_inside_tree():
		if is_instance_valid(scene_texture_rect):
			scene_texture_rect.modulate.a = 1.0
		_apply_act_content(index, tex)
		_start_subtle_pan()
		return

	_transition_tween = create_tween()
	_transition_tween.tween_property(scene_texture_rect, "modulate:a", 0.15, 0.25).set_trans(Tween.TRANS_QUAD)
	_transition_tween.tween_callback(func():
		if not is_instance_valid(self) or has_finished:
			return
		_apply_act_content(index, tex)
		_start_subtle_pan()
	)
	_transition_tween.tween_property(scene_texture_rect, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_QUAD)


func _start_subtle_pan() -> void:
	if not is_instance_valid(scene_texture_rect) or not is_inside_tree():
		return
	if _pan_tween and is_instance_valid(_pan_tween):
		_pan_tween.kill()
		_pan_tween = null
	scene_texture_rect.pivot_offset = scene_texture_rect.size * 0.5
	scene_texture_rect.scale = Vector2(1.0, 1.0)
	_pan_tween = create_tween()
	_pan_tween.tween_property(scene_texture_rect, "scale", Vector2(1.05, 1.05), ACT_DURATION).set_trans(Tween.TRANS_SINE)


func _update_indicators(index: int) -> void:
	if is_instance_valid(act_dots_container):
		for i in range(act_dots_container.get_child_count()):
			var dot := act_dots_container.get_child(i) as Control
			if dot:
				dot.modulate = Color(1.0, 0.85, 0.35, 1.0) if i == index else Color(0.45, 0.45, 0.52, 0.55)

	if is_instance_valid(segments_container):
		for i in range(segments_container.get_child_count()):
			var seg := segments_container.get_child(i)
			var bar := seg.get_node_or_null("Bar") as ColorRect
			var lbl := seg.get_node_or_null("Lbl") as Label
			if bar:
				if i == index:
					bar.color = Color(0.95, 0.8, 0.44, 1.0)
				elif i < index:
					bar.color = Color(0.68, 0.55, 0.3, 0.9)
				else:
					bar.color = Color(0.24, 0.24, 0.29, 0.8)
			if lbl:
				lbl.add_theme_color_override(
					"font_color",
					Color(0.96, 0.85, 0.55, 1.0) if i <= index else Color(0.55, 0.54, 0.6, 0.85)
				)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_act()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_act()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_advance_act()


func skip_story() -> void:
	_finish_story()


func _finish_story() -> void:
	if has_finished:
		return
	has_finished = true
	is_active = false
	_kill_tweens()

	if AudioManager:
		AudioManager.play_sfx("ui_click")

	if not is_inside_tree():
		story_completed.emit()
		return

	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_fade_tween.tween_callback(func():
		if not is_instance_valid(self):
			return
		story_completed.emit()
	)
