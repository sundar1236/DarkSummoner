class_name InventoryView
extends Control

# Visual interface for the Altar Grid and Reserve Backpack.
# Handles touch/mouse item selection, drag-and-drop, 90-degree rotation,
# transactional movement on altar, placement validation, merging,
# item details, and active synergy displays.

signal close_requested()

# Grid rendering constants
const CELL_SIZE: float = 68.0
const CELL_GAP: float = 6.0

var selected_item: ItemInstance = null
var selected_source: String = "" # "altar" or "backpack"
var is_move_mode: bool = false
var move_orig_pos: Vector2i = Vector2i.ZERO
var move_orig_rot: int = 0
var preview_cell: Vector2i = Vector2i(-999, -999)

# UI References
@export var altar_board: Control
@export var backpack_container: HFlowContainer
@export var item_details_panel: PanelContainer
@export var item_icon_rect: TextureRect
@export var lbl_item_name: Label
@export var lbl_item_tags: Label
@export var lbl_item_desc: Label
@export var lbl_item_stats: Label
@export var btn_rotate: Button
@export var btn_move: Button
@export var btn_backpack: Button
@export var btn_merge: Button
@export var btn_recycle: Button
@export var toast_panel: PanelContainer
@export var toast_label: Label
@export var synergy_list_container: VBoxContainer
@export var btn_close: Button
@export var lbl_grid_size: Label
@export var lbl_backpack_cap: Label

var _toast_tween: Tween

func _ready() -> void:
	_setup_signals()
	refresh_inventory_ui()

func _setup_signals() -> void:
	if btn_rotate:
		btn_rotate.pressed.connect(_on_rotate_pressed)
	if btn_move:
		btn_move.pressed.connect(_on_move_pressed)
	if btn_backpack:
		btn_backpack.pressed.connect(_on_backpack_pressed)
	if btn_merge:
		btn_merge.pressed.connect(_on_merge_pressed)
	if btn_recycle:
		btn_recycle.pressed.connect(_on_recycle_pressed)
	if btn_close:
		btn_close.pressed.connect(func():
			if is_move_mode:
				cancel_move_mode()
			close_requested.emit()
		)
		
	GameManager.inventory_changed.connect(refresh_inventory_ui)

func refresh_inventory_ui() -> void:
	if altar_board:
		altar_board.queue_redraw()
	_refresh_backpack_ui()
	_refresh_synergies_ui()
	_update_details_panel()
	
	if lbl_grid_size and GameManager.grid_manager:
		lbl_grid_size.text = "Altar Dimensions: %dx%d" % [GameManager.grid_manager.width, GameManager.grid_manager.height]
	if lbl_backpack_cap:
		lbl_backpack_cap.text = "Backpack: %d/%d" % [GameManager.backpack_items.size(), GameManager.BACKPACK_CAPACITY]

func show_toast(message: String) -> void:
	if not toast_panel or not toast_label:
		return
	toast_label.text = message
	toast_panel.visible = true
	toast_panel.modulate.a = 1.0
	if _toast_tween and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(toast_panel, "modulate:a", 0.0, 0.4)
	_toast_tween.tween_callback(func(): toast_panel.visible = false)

func _refresh_backpack_ui() -> void:
	if not backpack_container:
		return
	for c in backpack_container.get_children():
		c.queue_free()
		
	for item in GameManager.backpack_items:
		var slot_btn := Button.new()
		slot_btn.custom_minimum_size = Vector2(78, 78)
		if item.data:
			var tex: Texture2D = item.data.get_icon_texture()
			if tex:
				slot_btn.icon = tex
				slot_btn.expand_icon = true
				
		var stars: String = ""
		for s in range(item.data.tier if item.data else 1):
			stars += "★"
		slot_btn.text = stars
		slot_btn.add_theme_font_size_override("font_size", 12)
		slot_btn.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
		
		var r_col := Color(0.3, 0.4, 0.55, 0.8)
		match item.rarity:
			"rare": r_col = Color(0.2, 0.75, 1.0, 1.0)
			"epic": r_col = Color(0.85, 0.35, 1.0, 1.0)
			"legendary": r_col = Color(1.0, 0.85, 0.25, 1.0)
			
		if item == selected_item:
			slot_btn.modulate = Color(1.4, 1.3, 0.7)
		else:
			slot_btn.self_modulate = r_col
			
		var captured_item := item
		slot_btn.pressed.connect(func():
			if is_move_mode:
				cancel_move_mode()
			_select_item(captured_item, "backpack")
		)
		backpack_container.add_child(slot_btn)

func _refresh_synergies_ui() -> void:
	if not synergy_list_container:
		return
	for c in synergy_list_container.get_children():
		c.queue_free()
		
	var syn_dict: Dictionary = GameManager.cached_synergies
	var list: Array = syn_dict.get("active_synergies", [])
	
	if list.is_empty():
		var empty_lbl := Label.new()
		empty_lbl.text = "No active altar synergies.\nPlace adjacent runes, cores or weapons!"
		empty_lbl.modulate = Color(0.65, 0.65, 0.75, 0.8)
		synergy_list_container.add_child(empty_lbl)
		return
		
	for s in list:
		var card := VBoxContainer.new()
		var title_lbl := Label.new()
		title_lbl.text = "✦ " + s.get("title", "")
		title_lbl.modulate = Color(1.0, 0.85, 0.3)
		var desc_lbl := Label.new()
		desc_lbl.text = s.get("desc", "") + " (" + s.get("reason", "") + ")"
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.modulate = Color(0.85, 0.85, 0.95, 0.9)
		
		card.add_child(title_lbl)
		card.add_child(desc_lbl)
		synergy_list_container.add_child(card)

func _select_item(item: ItemInstance, source: String) -> void:
	if is_move_mode and item != selected_item:
		cancel_move_mode()
	selected_item = item
	selected_source = source
	if AudioManager:
		AudioManager.play_sfx("item_pickup")
	_update_details_panel()
	if altar_board:
		altar_board.queue_redraw()

func start_move_mode() -> void:
	if not selected_item:
		return
	is_move_mode = true
	move_orig_pos = selected_item.grid_pos
	move_orig_rot = selected_item.rotation_step
	preview_cell = selected_item.grid_pos
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_update_details_panel()
	if altar_board:
		altar_board.queue_redraw()

func cancel_move_mode() -> void:
	if not is_move_mode:
		return
	if selected_item:
		selected_item.grid_pos = move_orig_pos
		selected_item.rotation_step = move_orig_rot
	is_move_mode = false
	preview_cell = Vector2i(-999, -999)
	if AudioManager:
		AudioManager.play_sfx("ui_click")
	_update_details_panel()
	if altar_board:
		altar_board.queue_redraw()

func commit_move(target_pos: Vector2i) -> bool:
	if not selected_item:
		return false
		
	var success := false
	if selected_source == "altar":
		success = GameManager.move_item_on_altar(selected_item, target_pos, selected_item.rotation_step)
	else:
		success = GameManager.move_item_to_altar(selected_item, target_pos, selected_item.rotation_step)
		
	if success:
		is_move_mode = false
		selected_source = "altar"
		preview_cell = Vector2i(-999, -999)
		show_toast("✦ Equipped %s to Circle!" % (selected_item.data.name if selected_item.data else "Item"))
		refresh_inventory_ui()
		return true
	else:
		if AudioManager:
			AudioManager.play_sfx("ui_error")
		return false

func _update_details_panel() -> void:
	if not selected_item or not selected_item.data:
		if item_details_panel: item_details_panel.visible = false
		return
		
	if item_details_panel: item_details_panel.visible = true
	var d := selected_item.data
	
	if item_icon_rect:
		item_icon_rect.texture = d.get_icon_texture()
	if lbl_item_name:
		lbl_item_name.text = "%s (Tier %d)" % [d.name, d.tier]
		lbl_item_name.modulate = d.color
	if lbl_item_tags:
		lbl_item_tags.text = "Tags: " + ", ".join(d.tags)
	if lbl_item_desc:
		lbl_item_desc.text = d.description
	if lbl_item_stats:
		var stat_lines: Array[String] = []
		if d.bonus_atk > 0: stat_lines.append("+%.0f ATK" % d.bonus_atk)
		if d.bonus_hp > 0: stat_lines.append("+%.0f Max HP" % d.bonus_hp)
		if d.bonus_crit > 0: stat_lines.append("+%.0f%% Crit" % (d.bonus_crit * 100.0))
		if d.bonus_speed > 0: stat_lines.append("+%.0f Speed" % d.bonus_speed)
		if d.bonus_atk_speed > 0: stat_lines.append("+%.0f%% Atk Speed" % (d.bonus_atk_speed * 100.0))
		if d.passive_type != "none": stat_lines.append("Passive: " + d.passive_type.capitalize())
		lbl_item_stats.text = "Stats: " + (" | ".join(stat_lines) if not stat_lines.is_empty() else "Utility")

	if btn_move:
		if selected_source == "altar":
			btn_move.text = "CANCEL MOVE" if is_move_mode else "MOVE ON ALTAR"
			btn_move.modulate = Color(1.3, 0.45, 0.45) if is_move_mode else Color(1.0, 1.0, 1.0)
		else:
			btn_move.text = "PLACE ON ALTAR"
			btn_move.modulate = Color(1.0, 1.0, 1.0)

	if btn_backpack:
		btn_backpack.visible = (selected_source == "altar")
		btn_backpack.text = "TO BACKPACK"

	if btn_recycle:
		btn_recycle.visible = (selected_item != null)
		if selected_item and selected_item.data:
			var tier: int = selected_item.data.tier
			var gold_val: int = 25 if tier == 1 else (60 if tier == 2 else 150)
			btn_recycle.text = "RECYCLE (+%dG)" % gold_val

	# Check merge availability
	var mergeable: bool = false
	if d.merge_into_id != "":
		for other in (GameManager.altar_items + GameManager.backpack_items):
			if GameManager.can_merge_items(selected_item, other):
				mergeable = true
				break
	if btn_merge:
		btn_merge.visible = mergeable

func _on_rotate_pressed() -> void:
	if not selected_item:
		return
		
	selected_item.rotate_clockwise()
	if AudioManager:
		AudioManager.play_sfx("item_rotate")
		
	if is_move_mode:
		# In move mode: rotation affects live destination preview
		if altar_board:
			altar_board.queue_redraw()
	elif selected_source == "altar":
		# Not in move mode: if fits at current pos, commit; if not, enter move mode with rotated shape!
		if GameManager.grid_manager.can_place_item_ignoring(selected_item, selected_item.grid_pos, GameManager.altar_items, selected_item):
			GameManager.recalculate_stats_and_synergies()
		else:
			# Auto-enter move mode so player can place the rotated item in any valid spot
			start_move_mode()
	
	refresh_inventory_ui()

func _on_move_pressed() -> void:
	if not selected_item:
		return
		
	if selected_source == "altar":
		if not is_move_mode:
			start_move_mode()
		else:
			cancel_move_mode()
	else:
		# Place from backpack to altar: search for first available valid slot
		var valids := GameManager.grid_manager.get_valid_placements(selected_item, GameManager.altar_items, selected_item)
		if not valids.is_empty():
			if GameManager.move_item_to_altar(selected_item, valids[0]):
				selected_source = "altar"
				refresh_inventory_ui()
		else:
			if AudioManager:
				AudioManager.play_sfx("ui_error")

func _on_backpack_pressed() -> void:
	if not selected_item or selected_source != "altar":
		return
		
	if is_move_mode:
		cancel_move_mode()
		
	var iname: String = selected_item.data.name if selected_item.data else "Item"
	if GameManager.move_item_to_backpack(selected_item):
		selected_source = "backpack"
		show_toast("✦ %s moved to backpack." % iname)
		refresh_inventory_ui()

func _on_recycle_pressed() -> void:
	if not selected_item:
		return
	var iname: String = selected_item.data.name if selected_item.data else "Item"
	var gained := GameManager.recycle_item(selected_item)
	show_toast("✦ Recycled %s (+%d Gold)!" % [iname, gained])
	selected_item = null
	selected_source = ""
	if is_move_mode:
		cancel_move_mode()
	refresh_inventory_ui()

func _on_merge_pressed() -> void:
	if not selected_item:
		return
		
	for other in (GameManager.altar_items + GameManager.backpack_items):
		if GameManager.can_merge_items(selected_item, other):
			var merged := GameManager.merge_items(selected_item, other)
			if merged:
				selected_item = merged
				selected_source = "altar" if GameManager.altar_items.has(merged) else "backpack"
				show_toast("✦ Merged into %s!" % merged.data.name)
				refresh_inventory_ui()
			break
