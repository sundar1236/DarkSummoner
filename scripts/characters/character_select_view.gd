class_name CharacterSelectView
extends Control

# Dedicated Character Selection Screen for Abyssal Altar.
# Displays glowing gothic hero cards, stepped rune pedestal showcase,
# lore, combat identity, weapon, active/passive cards, and launch CTA.

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

var selected_character_id: String = "kael_varyn"
var is_initial_selection: bool = false
var _stage_backdrop: ShowcasePedestalBackdrop
var _info_crest: InfoCardCrest

const CARD_ART_PATHS: Dictionary = {
	"kael_varyn": "res://assets/art/ui_reference/card_full_kael_varyn.png",
	"shadow_hunter": "res://assets/art/ui_reference/card_full_shadow_hunter.png",
	"storm_reaper": "res://assets/art/ui_reference/card_full_storm_reaper.png",
	"soul_binder": "res://assets/art/ui_reference/card_full_soul_binder.png"
}

const PORTRAIT_PATHS: Dictionary = {
	"kael_varyn": "res://assets/art/characters/kael_varyn_portrait.png",
	"shadow_hunter": "res://assets/art/characters/shadow_hunter_portrait.png",
	"storm_reaper": "res://assets/art/characters/storm_reaper_portrait.png",
	"soul_binder": "res://assets/art/characters/soul_binder_portrait.png"
}


class ShowcasePedestalBackdrop extends Control:
	var accent_color: Color = Color(0.22, 0.88, 1.0, 1.0)
	var is_locked_hero: bool = false
	var _t: float = 0.0

	func _process(delta: float) -> void:
		if is_visible_in_tree():
			_t += delta
			queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 0.0 or h <= 0.0:
			return
		var col := accent_color if not is_locked_hero else Color(0.45, 0.45, 0.55, 1.0)
		var pulse := 0.5 + 0.5 * sin(_t * 2.8)

		# 1. Atmospheric radial aura & upward light mist behind hero
		var hero_center := Vector2(w * 0.5, h * 0.44)
		for i in range(6):
			var r := 60.0 + float(i) * 30.0
			var a := (0.14 - float(i) * 0.02) * (0.75 + 0.25 * pulse)
			draw_circle(hero_center, r, Color(col.r, col.g, col.b, maxf(0.0, a)))

		# 2. Stepped Gothic Stone Circular Pedestal at hero feet
		var ped := Vector2(w * 0.5, h - 34.0)
		# Floor shadow ellipse
		_draw_ellipse(ped + Vector2(0, 22), 132.0, 34.0, Color(0.01, 0.015, 0.03, 0.82))
		# Outer stone base cylinder
		_draw_ellipse(ped + Vector2(0, 12), 118.0, 30.0, Color(0.11, 0.13, 0.17, 0.98))
		_draw_ellipse_outline(ped + Vector2(0, 12), 118.0, 30.0, Color(0.32, 0.38, 0.46, 0.85), 2.0)
		# Middle stone rim
		_draw_ellipse(ped + Vector2(0, 3), 102.0, 25.0, Color(0.17, 0.20, 0.25, 0.98))
		_draw_ellipse_outline(ped + Vector2(0, 3), 102.0, 25.0, Color(0.45, 0.53, 0.62, 0.85), 1.8)
		# Top stone altar platform
		_draw_ellipse(ped + Vector2(0, -4), 86.0, 21.0, Color(0.13, 0.17, 0.22, 0.98))
		_draw_ellipse_outline(ped + Vector2(0, -4), 86.0, 21.0, Color(col.r, col.g, col.b, 0.72), 2.0)

		# Glowing arcane ring on pedestal top
		_draw_ellipse(ped + Vector2(0, -5), 62.0, 15.0, Color(col.r, col.g, col.b, 0.20 + 0.12 * pulse))
		_draw_ellipse_outline(ped + Vector2(0, -5), 62.0, 15.0, Color(col.r, col.g, col.b, 0.85), 2.2)
		_draw_ellipse_outline(ped + Vector2(0, -5), 40.0, 10.0, Color(1.0, 1.0, 1.0, 0.45 + 0.25 * pulse), 1.4)

		# Subtle carved stone tick notches along rim
		for step in range(8):
			var ang := (TAU / 8.0) * float(step) + 0.2
			var p_in := ped + Vector2(cos(ang) * 88.0, -4.0 + sin(ang) * 21.5)
			var p_out := ped + Vector2(cos(ang) * 101.0, 2.0 + sin(ang) * 24.5)
			draw_line(p_in, p_out, Color(0.07, 0.09, 0.12, 0.9), 2.5)

		# 3. Drifting cyan / elemental soul embers around stage
		for e in range(10):
			var phase := fmod(_t * (0.28 + float(e % 3) * 0.09) + float(e) * 0.17, 1.0)
			var ex := w * 0.5 + sin(_t * 1.4 + float(e) * 1.3) * (65.0 + float(e % 4) * 26.0)
			var ey := (ped.y - 12.0) - phase * (h * 0.72)
			var alpha := sin(phase * PI) * 0.65
			var rad := 2.0 + float(e % 3) * 1.1
			draw_circle(Vector2(ex, ey), rad * 2.2, Color(col.r, col.g, col.b, alpha * 0.28))
			draw_circle(Vector2(ex, ey), rad, Color(col.r, col.g, col.b, alpha))

	func _draw_ellipse(center: Vector2, rx: float, ry: float, col: Color) -> void:
		var pts := PackedVector2Array()
		for i in range(36):
			var a := (TAU / 36.0) * float(i)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_colored_polygon(pts, col)

	func _draw_ellipse_outline(center: Vector2, rx: float, ry: float, col: Color, width: float) -> void:
		var pts := PackedVector2Array()
		for i in range(37):
			var a := (TAU / 36.0) * float(i % 36)
			pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
		draw_polyline(pts, col, width, true)


class InfoCardCrest extends Control:
	var accent_color: Color = Color(0.22, 0.88, 1.0, 1.0)

	func _draw() -> void:
		var cx := size.x * 0.5
		var cy := -24.0
		var outer := PackedVector2Array([
			Vector2(cx, cy - 14), Vector2(cx + 18, cy), Vector2(cx, cy + 14), Vector2(cx - 18, cy)
		])
		draw_colored_polygon(outer, Color(0.09, 0.12, 0.17, 1.0))
		draw_polyline(PackedVector2Array([outer[0], outer[1], outer[2], outer[3], outer[0]]), Color(0.62, 0.74, 0.82, 0.95), 2.0, true)
		var inner := PackedVector2Array([
			Vector2(cx, cy - 8), Vector2(cx + 10, cy), Vector2(cx, cy + 8), Vector2(cx - 10, cy)
		])
		draw_colored_polygon(inner, accent_color)
		draw_circle(Vector2(cx, cy - 2), 2.0, Color(1.0, 1.0, 1.0, 0.85))


func _ready() -> void:
	CharacterDatabase.init_database()
	_install_stage_ornaments()
	if portrait_rect:
		portrait_rect.clip_contents = true
		portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_sync_selected_character()
	_setup_signals()
	_refresh_tabs()
	_update_view()
	
	visibility_changed.connect(func():
		if visible:
			_sync_selected_character()
			_update_shades_display()
			_refresh_tabs()
			_update_view()
	)

func _install_stage_ornaments() -> void:
	var stage_ctrl := get_node_or_null("VBoxMain/ShowcasePanel/StageControl") as Control
	if stage_ctrl and _stage_backdrop == null:
		_stage_backdrop = ShowcasePedestalBackdrop.new()
		_stage_backdrop.name = "ShowcasePedestalBackdrop"
		_stage_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_stage_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
		stage_ctrl.add_child(_stage_backdrop)
		stage_ctrl.move_child(_stage_backdrop, 0)

	var info_card := get_node_or_null("VBoxMain/InfoCard") as Control
	if info_card and _info_crest == null:
		_info_crest = InfoCardCrest.new()
		_info_crest.name = "InfoCardCrest"
		_info_crest.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
		_info_crest.custom_minimum_size = Vector2(0, 4)
		_info_crest.mouse_filter = Control.MOUSE_FILTER_IGNORE
		info_card.add_child(_info_crest)

func _sync_selected_character() -> void:
	if is_initial_selection:
		selected_character_id = "kael_varyn"
		return
	var preferred_id := ""
	if GameManager and GameManager.current_character:
		preferred_id = str(GameManager.current_character.id)
	elif SaveManager:
		preferred_id = str(SaveManager.active_character_id)
	if not preferred_id.is_empty() and CharacterDatabase.get_character(preferred_id):
		selected_character_id = preferred_id
	elif not CharacterDatabase.get_character(selected_character_id):
		selected_character_id = "kael_varyn"

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
		lbl_shades.text = "%d Shades" % SaveManager.shades

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
		card_button.custom_minimum_size = Vector2(0, 212)
		card_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card_button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_button.clip_contents = true
		card_button.focus_mode = Control.FOCUS_NONE
		var border_col: Color = ch.primary_color if is_selected else Color(0.32, 0.34, 0.44, 0.9)
		card_button.add_theme_stylebox_override("normal", _make_card_style(is_selected, border_col))
		card_button.add_theme_stylebox_override("hover", _make_card_style(true, ch.primary_color))
		card_button.add_theme_stylebox_override("pressed", _make_card_style(true, ch.primary_color))

		var art_clip := Control.new()
		art_clip.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		art_clip.offset_left = 4.0
		art_clip.offset_top = 4.0
		art_clip.offset_right = -4.0
		art_clip.offset_bottom = -4.0
		art_clip.clip_contents = true
		art_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_button.add_child(art_clip)

		var card_art := TextureRect.new()
		card_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if ch.id != "kael_varyn":
			card_art.offset_top = -36.0
			card_art.offset_bottom = 46.0
		var card_texture_path := str(CARD_ART_PATHS.get(ch.id, ""))
		card_art.texture = load(card_texture_path) as Texture2D if not card_texture_path.is_empty() else null
		if card_art.texture == null:
			card_art.texture = load(str(PORTRAIT_PATHS.get(ch.id, ""))) as Texture2D
		card_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		card_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		card_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_art.modulate = Color.WHITE if is_unlocked else Color(0.45, 0.44, 0.52, 0.95)
		art_clip.add_child(card_art)

		# Clean bottom nameplate covers baked sub-buttons without overlapping the card art
		var name_plate := PanelContainer.new()
		name_plate.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
		name_plate.offset_left = 5.0
		name_plate.offset_top = -52.0 if ch.id != "kael_varyn" else -40.0
		name_plate.offset_right = -5.0
		name_plate.offset_bottom = -5.0
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var plate_style := StyleBoxFlat.new()
		plate_style.bg_color = Color(0.03, 0.04, 0.07, 0.96)
		plate_style.border_width_top = 1
		plate_style.border_color = Color(border_col.r, border_col.g, border_col.b, 0.65)
		plate_style.set_corner_radius_all(6)
		name_plate.add_theme_stylebox_override("panel", plate_style)
		var name_label := Label.new()
		name_label.text = ch.name.to_upper() if is_unlocked else ch.name.to_upper() + " • LOCKED"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", Color.WHITE if is_selected else (ch.primary_color if is_unlocked else Color(0.75, 0.75, 0.82)))
		name_plate.add_child(name_label)
		card_button.add_child(name_plate)

		var card_id: String = ch.id
		card_button.pressed.connect(func(): _select_character(card_id))
		tabs_container.add_child(card_button)

func _make_card_style(selected: bool, border_col: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.035, 0.06, 1.0)
	style.set_border_width_all(3 if selected else 1)
	style.border_color = border_col if selected else Color(0.32, 0.34, 0.44, 0.9)
	style.set_corner_radius_all(10)
	if selected:
		style.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.45)
		style.shadow_size = 8
	return style

func _select_character(char_id: String) -> void:
	if CharacterDatabase.get_character(char_id) == null:
		push_warning("Character selection ignored unknown id: %s" % char_id)
		return
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
	
	var is_unlocked: bool = is_initial_selection or (SaveManager.is_character_unlocked(ch.id) if SaveManager else true)

	if _stage_backdrop:
		_stage_backdrop.accent_color = ch.primary_color
		_stage_backdrop.is_locked_hero = not is_unlocked
		_stage_backdrop.queue_redraw()
	if _info_crest:
		_info_crest.accent_color = ch.primary_color
		_info_crest.queue_redraw()

	# Show the clean 2D/3D-rendered character portrait cutout standing on the pedestal.
	var path: String = PORTRAIT_PATHS.get(ch.id, "res://assets/art/characters/kael_varyn_portrait.png")
	if portrait_rect:
		var tex := TextureLoader.get_texture(path)
		if tex == null:
			tex = load(str(CARD_ART_PATHS.get(ch.id, ""))) as Texture2D
		portrait_rect.texture = tex
	
	# Locked silhouette and overlay
	if locked_overlay:
		locked_overlay.visible = not is_unlocked
	if portrait_rect:
		portrait_rect.modulate = Color(0.35, 0.3, 0.45, 0.85) if not is_unlocked else Color(1.0, 1.0, 1.0, 1.0)
		
	# Text details
	if lbl_char_name:
		lbl_char_name.text = ch.name.to_upper()
		lbl_char_name.add_theme_color_override("font_color", ch.primary_color)
	if lbl_char_title:
		lbl_char_title.text = "— %s —" % ch.title
	if lbl_char_weapon:
		var weapon_name := "Dual Obsidian Daggers"
		var style_name := "Swift Critical Slashes"
		match ch.id:
			"kael_varyn":
				weapon_name = "Living Soulbound Grimoire"
				style_name = "Cyan Soulfire & Arcane Bindings"
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
		
	# Action button & Unlock status
	if lbl_unlock_requirement:
		if is_initial_selection:
			lbl_unlock_requirement.text = "FIRST DESCENT • CHOOSE ONE CHAMPION TO BEGIN"
			lbl_unlock_requirement.modulate = Color(1.0, 0.86, 0.45)
		elif is_unlocked:
			lbl_unlock_requirement.text = "CHAMPION UNLOCKED & READY"
			lbl_unlock_requirement.modulate = Color(0.35, 1.0, 0.58)
		else:
			lbl_unlock_requirement.text = "REQUIRES: REACH FLOOR %d OR SPEND %d SHADES" % [ch.unlock_floor_required, ch.unlock_cost_shades]
			lbl_unlock_requirement.modulate = Color(1.0, 0.75, 0.35)
			
	if btn_action:
		if is_initial_selection:
			btn_action.text = "BEGIN AS %s" % ch.name.to_upper()
			btn_action.disabled = false
			btn_action.modulate = Color.WHITE
		elif is_unlocked:
			btn_action.text = "ENTER THE TOWER AS %s" % ch.name.to_upper()
			btn_action.disabled = false
			btn_action.modulate = Color.WHITE
		else:
			var can_afford: bool = (SaveManager.shades >= ch.unlock_cost_shades) if SaveManager else false
			btn_action.text = "UNLOCK CHAMPION (%d SHADES)" % ch.unlock_cost_shades
			btn_action.disabled = not can_afford
			btn_action.modulate = Color(0.85, 0.78, 1.0) if can_afford else Color(0.7, 0.7, 0.75)

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
