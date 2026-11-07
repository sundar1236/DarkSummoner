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

func _refresh_tabs() -> void:
	if not tabs_container:
		return
	for c in tabs_container.get_children():
		c.queue_free()
		
	var all_chars := CharacterDatabase.get_all_characters()
	for ch in all_chars:
		var is_unlocked: bool = SaveManager.is_character_unlocked(ch.id) if SaveManager else true
		var is_selected: bool = (ch.id == selected_character_id)
		
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(180, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var icon_prefix := "✓ " if is_selected else ""
		var lock_suffix := " 🔒" if not is_unlocked else ""
		btn.text = "%s%s%s" % [icon_prefix, ch.name, lock_suffix]
		
		if is_selected:
			btn.modulate = Color(1.0, 0.92, 0.5)
		elif not is_unlocked:
			btn.modulate = Color(0.7, 0.7, 0.75)
		else:
			btn.modulate = Color(0.92, 0.92, 0.98)
			
		var cap_id := ch.id
		btn.pressed.connect(func():
			_select_character(cap_id)
		)
		tabs_container.add_child(btn)

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
		
	var is_unlocked: bool = SaveManager.is_character_unlocked(ch.id) if SaveManager else true
	
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
		if is_unlocked:
			lbl_unlock_requirement.text = "CHAMPION UNLOCKED & READY"
			lbl_unlock_requirement.modulate = Color(0.4, 1.0, 0.6)
		else:
			lbl_unlock_requirement.text = "REQUIRES: REACH FLOOR %d OR SPEND %d SHADES" % [ch.unlock_floor_required, ch.unlock_cost_shades]
			lbl_unlock_requirement.modulate = Color(1.0, 0.75, 0.35)
			
	if btn_action:
		if is_unlocked:
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
