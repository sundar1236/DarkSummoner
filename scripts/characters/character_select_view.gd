class_name CharacterSelectView
extends Control

# Dedicated Character Selection Screen for Abyssal Altar.
# Displays high-detail character portraits, lore, combat identity, weapon,
# active/passive abilities, unlock status/costs, and starts gameplay runs.

signal start_run_requested(character_id: String)
signal back_requested()

@export var btn_back: Button
@export var lbl_shades: Label
@export var tabs_container: HBoxContainer
@export var portrait_rect: TextureRect
@export var locked_overlay: Control
@export var lbl_char_name: Label
@export var lbl_char_title: Label
@export var lbl_char_weapon: Label
@export var lbl_char_passive: Label
@export var lbl_char_active: Label
@export var lbl_char_stats: Label
@export var lbl_unlock_requirement: Label
@export var btn_action: Button

var selected_character_id: String = "shadow_hunter"
var is_initial_selection: bool = false

const CARD_ART_PATHS: Dictionary = {
	"shadow_hunter": "res://assets/art/ui_reference/card_full_shadow_hunter.png",
	"storm_reaper": "res://assets/art/ui_reference/card_full_storm_reaper.png",
	"soul_binder": "res://assets/art/ui_reference/card_full_soul_binder.png"
}

const PORTRAIT_PATHS: Dictionary = {
	"shadow_hunter": "res://assets/art/characters/shadow_hunter_portrait.png",
	"storm_reaper": "res://assets/art/characters/storm_reaper_portrait.png",
	"soul_binder": "res://assets/art/characters/soul_binder_portrait.png"
}

func _ready() -> void:
	CharacterDatabase.init_database()
	_setup_signals()
	_refresh_tabs()
	_select_character("shadow_hunter")
	
	visibility_changed.connect(func():
		if visible:
			_update_shades_display()
			_refresh_tabs()
			_update_view()
	)

func _setup_signals() -> void:
	if btn_back:
		btn_back.pressed.connect(func():
			if AudioManager: AudioManager.play_sfx("ui_click")
			back_requested.emit()
		)
	if btn_action:
		btn_action.pressed.connect(_on_action_pressed)
		
	if SaveManager:
		SaveManager.shades_changed.connect(func(_s: int):
			_update_shades_display()
			_refresh_tabs()
			_update_view()
		)

func _update_shades_display() -> void:
	if lbl_shades and SaveManager:
		lbl_shades.text = "◆ %d Shades" % SaveManager.shades

func set_initial_selection_mode(enabled: bool) -> void:
	is_initial_selection = enabled
	if btn_back:
		btn_back.visible = not enabled
	_refresh_tabs()
	_update_view()

func _refresh_tabs() -> void:
	if not tabs_container:
		return
	for child in tabs_container.get_children():
		tabs_container.remove_child(child)
		child.queue_free()

	for ch in CharacterDatabase.get_all_characters():
		var is_unlocked: bool = is_initial_selection or (SaveManager.is_character_unlocked(ch.id) if SaveManager else true)
		var is_selected: bool = ch.id == selected_character_id
		var card_button := Button.new()
		card_button.name = "Card_" + ch.id
		card_button.custom_minimum_size = Vector2(0, 236)
		card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_button.clip_contents = true
		card_button.focus_mode = Control.FOCUS_NONE
		card_button.add_theme_stylebox_override("normal", _make_card_style(is_selected))
		card_button.add_theme_stylebox_override("hover", _make_card_style(true))
		card_button.add_theme_stylebox_override("pressed", _make_card_style(true))

		var card_art := TextureRect.new()
		card_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		card_art.offset_left = 5.0
		card_art.offset_top = 5.0
		card_art.offset_right = -5.0
		card_art.offset_bottom = -5.0
		card_art.texture = load(str(CARD_ART_PATHS.get(ch.id, ""))) as Texture2D
		card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_art.modulate = Color.WHITE if is_unlocked else Color(0.45, 0.42, 0.52, 0.95)
		card_button.add_child(card_art)

		var name_plate := PanelContainer.new()
		name_plate.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		name_plate.offset_left = 7.0
		name_plate.offset_top = -48.0
		name_plate.offset_right = -7.0
		name_plate.offset_bottom = -7.0
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plate_style := StyleBoxFlat.new()
		plate_style.bg_color = Color(0.035, 0.025, 0.07, 0.92)
		plate_style.set_corner_radius_all(7)
		name_plate.add_theme_stylebox_override("panel", plate_style)
		var name_label := Label.new()
		name_label.text = ch.name.to_upper() if is_unlocked else ch.name.to_upper() + "  •  LOCKED"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 15)
		name_label.add_theme_color_override("font_color", ch.primary_color if is_unlocked else Color(0.75, 0.72, 0.8))
		name_plate.add_child(name_label)
		card_button.add_child(name_plate)

		var card_id: String = ch.id
		card_button.pressed.connect(func(): _select_character(card_id))
		tabs_container.add_child(card_button)

func _make_card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.02, 0.045, 1.0)
	style.set_border_width_all(4 if selected else 1)
	style.border_color = Color(1.0, 0.82, 0.38, 1.0) if selected else Color(0.32, 0.28, 0.42, 1.0)
	style.set_corner_radius_all(10)
	return style

func _select_character(char_id: String) -> void:
	selected_character_id = char_id
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_refresh_tabs()
	_update_view()

func _update_view() -> void:
	var ch := CharacterDatabase.get_character(selected_character_id)
	if not ch:
		return
		
	_update_shades_display()
	
	# 1. Portrait loading
	var path: String = PORTRAIT_PATHS.get(ch.id, "res://assets/art/characters/shadow_hunter_portrait.png")
	if portrait_rect:
		var tex := TextureLoader.get_texture(path)
		portrait_rect.texture = tex
		
	var is_unlocked: bool = is_initial_selection or (SaveManager.is_character_unlocked(ch.id) if SaveManager else true)
	
	# 2. Locked silhouette and overlay
	if locked_overlay:
		locked_overlay.visible = not is_unlocked
	if portrait_rect:
		portrait_rect.modulate = Color(0.35, 0.3, 0.45, 0.85) if not is_unlocked else Color(1.0, 1.0, 1.0, 1.0)
		
	# 3. Text details
	if lbl_char_name:
		lbl_char_name.text = ch.name.to_upper()
		lbl_char_name.modulate = ch.primary_color
	if lbl_char_title:
		lbl_char_title.text = "— %s —" % ch.title
	if lbl_char_weapon:
		var weapon_name := "Dual Obsidian Daggers"
		var style_name := "Swift Critical Slashes"
		match ch.id:
			"storm_reaper":
				weapon_name = "Lightning War-Scythe"
				style_name = "Area Shockwaves & High Burst"
			"soul_binder":
				weapon_name = "Spectral Soul Phylactery"
				style_name = "Companion Necromancy & Homing Wisps"
		lbl_char_weapon.text = "WEAPON: %s   •   STYLE: %s" % [weapon_name, style_name]
		
	if lbl_char_passive:
		lbl_char_passive.text = "PASSIVE: " + ch.passive_desc
	if lbl_char_active:
		lbl_char_active.text = "ULTIMATE: " + ch.active_desc
	if lbl_char_stats:
		lbl_char_stats.text = "HEALTH: %.0f   |   DAMAGE: %.0f   |   SPEED: %.0f   |   CRIT: %.0f%%" % [
			ch.base_hp, ch.base_atk, ch.base_speed, ch.base_crit_chance * 100.0
		]
		
	# 4. Action button & Unlock status
	if lbl_unlock_requirement:
		if is_initial_selection:
			lbl_unlock_requirement.text = "FIRST DESCENT • CHOOSE ONE CHAMPION TO BEGIN"
			lbl_unlock_requirement.modulate = Color(1.0, 0.86, 0.45)
		elif is_unlocked:
			lbl_unlock_requirement.text = "CHAMPION UNLOCKED & READY"
			lbl_unlock_requirement.modulate = Color(0.4, 1.0, 0.6)
		else:
			lbl_unlock_requirement.text = "REQUIRES: REACH FLOOR %d OR SPEND %d SHADES" % [ch.unlock_floor_required, ch.unlock_cost_shades]
			lbl_unlock_requirement.modulate = Color(1.0, 0.75, 0.35)
			
	if btn_action:
		if is_initial_selection:
			btn_action.text = "BEGIN AS %s" % ch.name.to_upper()
			btn_action.disabled = false
			btn_action.modulate = Color(1.0, 0.95, 0.6)
		elif is_unlocked:
			btn_action.text = "ENTER THE TOWER AS %s" % ch.name.to_upper()
			btn_action.disabled = false
			btn_action.modulate = Color(1.0, 0.95, 0.6)
		else:
			var can_afford: bool = (SaveManager.shades >= ch.unlock_cost_shades) if SaveManager else false
			btn_action.text = "UNLOCK CHAMPION (%d SHADES)" % ch.unlock_cost_shades
			btn_action.disabled = not can_afford
			btn_action.modulate = Color(0.9, 0.7, 1.0) if can_afford else Color(0.55, 0.55, 0.55)

func _on_action_pressed() -> void:
	var ch := CharacterDatabase.get_character(selected_character_id)
	if not ch: return
	
	if is_initial_selection:
		if SaveManager and SaveManager.complete_initial_character_selection(ch.id):
			GameManager.current_character = ch
			if AudioManager: AudioManager.play_sfx("ui_click")
			start_run_requested.emit(ch.id)
		else:
			if AudioManager: AudioManager.play_sfx("ui_error")
		return

	var is_unlocked: bool = SaveManager.is_character_unlocked(ch.id) if SaveManager else true
	if is_unlocked:
		if AudioManager: AudioManager.play_sfx("ui_click")
		start_run_requested.emit(ch.id)
	else:
		if SaveManager.unlock_character(ch.id, ch.unlock_cost_shades):
			if AudioManager: AudioManager.play_sfx("upgrade")
			_refresh_tabs()
			_update_view()
		else:
			if AudioManager: AudioManager.play_sfx("ui_error")
