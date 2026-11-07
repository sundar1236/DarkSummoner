class_name StoryIntro
extends Control

# 30-40s Lore Prologue & Narrative Story Intro for Abyssal Altar.
# 4 cinematic acts detailing The Black Tower, The Cursed Altar, Lord Malakar,
# and The Hunter's Descent, with smooth pan-and-zoom and dark gothic audio.

signal story_completed()

@export var scene_texture_rect: TextureRect
@export var title_label: Label
@export var subtitle_label: Label
@export var narrative_label: Label
@export var act_dots_container: HBoxContainer
@export var btn_skip: Button
@export var progress_bar: ProgressBar

const ACT_DURATION: float = 8.5 # 4 acts * 8.5s = 34 seconds total

var current_act_index: int = 0
var act_timer: float = 0.0
var is_active: bool = false
var has_finished: bool = false

var acts: Array[Dictionary] = [
	{
		"title": "ACT I : THE BLACK TOWER",
		"subtitle": "The Cursed Spire of Aethelgard",
		"text": "In the forgotten ages of Aethelgard, the Black Tower pierced the shattered heavens. An obsidian monolith built of condemned souls, rising from the void where sunlight dared not fall.",
		"image_path": "res://assets/art/story/story_scene_1_tower.png"
	},
	{
		"title": "ACT II : THE CURSED ENGINE",
		"subtitle": "The Abyssal Altar",
		"text": "Deep within its core lies the Abyssal Altar—an ancient stone engine of forbidden transmutations. By arranging relics of power and binding spectral runes, mortals can wield the very void that seeks to consume them.",
		"image_path": "res://assets/art/story/story_scene_2_altar.png"
	},
	{
		"title": "ACT III : SOVEREIGN OF THE VOID",
		"subtitle": "Lord Malakar's Domain",
		"text": "High upon the throne of shadows ruled Lord Malakar. Consumed by immortal greed, he bound the five tower realms into an eternal trial of death, harvesting the essences of all who entered.",
		"image_path": "res://assets/art/story/story_scene_3_malakar.png"
	},
	{
		"title": "ACT IV : THE HUNTER'S DESCENT",
		"subtitle": "Reclaim the Fallen Kingdom",
		"text": "Armed with runic steel, storm magic, and bloodcraft, you step beyond the threshold. Master the Altar's synergies, destroy the abyssal lords, and break the Black Tower's eternal curse.",
		"image_path": "res://assets/art/story/story_scene_4_hunter.png"
	}
]

func _ready() -> void:
	if btn_skip:
		btn_skip.pressed.connect(_finish_story)

func start_story() -> void:
	is_active = true
	has_finished = false
	current_act_index = 0
	act_timer = 0.0
	
	if AudioManager:
		AudioManager.play_music("horror_menu")
		AudioManager.play_ambience(true)
		
	_display_act(0, true)

func _process(delta: float) -> void:
	if not is_active or has_finished:
		return
		
	act_timer += delta
	if progress_bar:
		var overall_progress := (float(current_act_index) + (act_timer / ACT_DURATION)) / float(acts.size())
		progress_bar.value = clampf(overall_progress, 0.0, 1.0)
		
	if act_timer >= ACT_DURATION:
		_advance_act()

func _advance_act() -> void:
	act_timer = 0.0
	current_act_index += 1
	if current_act_index >= acts.size():
		_finish_story()
	else:
		_display_act(current_act_index, false)

func _display_act(index: int, instant: bool) -> void:
	if index < 0 or index >= acts.size():
		return
		
	var data: Dictionary = acts[index]
	var tex: Texture2D = load(data["image_path"]) as Texture2D
	
	if instant:
		if scene_texture_rect and tex:
			scene_texture_rect.texture = tex
			scene_texture_rect.modulate.a = 1.0
			_start_subtle_pan()
		if title_label: title_label.text = data["title"]
		if subtitle_label: subtitle_label.text = data["subtitle"]
		if narrative_label: narrative_label.text = data["text"]
		_update_dots(index)
	else:
		var tween := create_tween()
		if scene_texture_rect:
			tween.tween_property(scene_texture_rect, "modulate:a", 0.15, 0.35).set_trans(Tween.TRANS_QUAD)
			tween.tween_callback(func():
				if tex: scene_texture_rect.texture = tex
				if title_label: title_label.text = data["title"]
				if subtitle_label: subtitle_label.text = data["subtitle"]
				if narrative_label: narrative_label.text = data["text"]
				_start_subtle_pan()
				_update_dots(index)
			)
			tween.tween_property(scene_texture_rect, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD)
		else:
			if title_label: title_label.text = data["title"]
			if subtitle_label: subtitle_label.text = data["subtitle"]
			if narrative_label: narrative_label.text = data["text"]
			_update_dots(index)

func _start_subtle_pan() -> void:
	if not scene_texture_rect: return
	scene_texture_rect.scale = Vector2(1.0, 1.0)
	scene_texture_rect.position = Vector2.ZERO
	var pan := create_tween()
	pan.tween_property(scene_texture_rect, "scale", Vector2(1.06, 1.06), ACT_DURATION).set_trans(Tween.TRANS_SINE)

func _update_dots(index: int) -> void:
	if not act_dots_container: return
	for i in range(act_dots_container.get_child_count()):
		var dot: Control = act_dots_container.get_child(i) as Control
		if dot:
			dot.modulate = Color(1.0, 0.82, 0.2, 1.0) if i == index else Color(0.4, 0.4, 0.5, 0.5)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_advance_act()
	elif event is InputEventScreenTouch and event.pressed:
		_advance_act()
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER):
		_advance_act()

func _finish_story() -> void:
	if has_finished:
		return
	has_finished = true
	is_active = false
	
	if AudioManager:
		AudioManager.play_sfx("ui_click")
		
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.tween_callback(func():
		story_completed.emit()
	)
