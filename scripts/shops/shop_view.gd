class_name ShopView
extends Control

# Working Shop with Blacksmith, Potion Merchant, and Relic Merchant.
# Validates gold, updates inventory safely, and handles purchases.

signal leave_shop_requested()

@export var btn_tab_blacksmith: Button
@export var btn_tab_potion: Button
@export var btn_tab_relic: Button

@export var items_grid: HFlowContainer
@export var lbl_gold: Label
@export var btn_leave: Button
@export var btn_altar: Button

var current_category: String = "blacksmith"

# Store stock per category: Array of Dictionary { "data": ItemData, "cost": int, "purchased": bool }
var shop_stock: Dictionary = {
	"blacksmith": [],
	"potion_merchant": [],
	"relic_merchant": []
}

func _ready() -> void:
	_init_shop_stock()
	_setup_signals()
	_update_category("blacksmith")
	_refresh_gold_label()

func _setup_signals() -> void:
	if btn_tab_blacksmith:
		btn_tab_blacksmith.pressed.connect(func(): _update_category("blacksmith"))
	if btn_tab_potion:
		btn_tab_potion.pressed.connect(func(): _update_category("potion_merchant"))
	if btn_tab_relic:
		btn_tab_relic.pressed.connect(func(): _update_category("relic_merchant"))
	if btn_leave:
		btn_leave.pressed.connect(func(): leave_shop_requested.emit())
	GameManager.gold_changed.connect(func(_g: int): _refresh_gold_label())

func _init_shop_stock() -> void:
	# Blacksmith: Weapons, shields, upgrades
	shop_stock["blacksmith"] = [
		{ "data": ItemDatabase.get_item("shadow_dagger"), "cost": 25, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("shadow_blade"), "cost": 50, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("iron_shield"), "cost": 30, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("void_shield"), "cost": 65, "is_potion": false, "sold": false }
	]
	
	# Potion Merchant: Potions & Vitality
	shop_stock["potion_merchant"] = [
		{ "data": null, "cost": 20, "is_potion": true, "name": "Healing Potion (+1)", "desc": "Restores 1 potion charge.", "sold": false },
		{ "data": ItemDatabase.get_item("blood_chalice"), "cost": 35, "is_potion": false, "sold": false }
	]
	
	# Relic Merchant: Runes, Cores, Magical Relics
	shop_stock["relic_merchant"] = [
		{ "data": ItemDatabase.get_item("fire_rune"), "cost": 30, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("wolf_core"), "cost": 40, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("lightning_orb"), "cost": 45, "is_potion": false, "sold": false },
		{ "data": ItemDatabase.get_item("soul_urn"), "cost": 40, "is_potion": false, "sold": false }
	]

func _update_category(cat: String) -> void:
	current_category = cat
	_render_stock()

func _refresh_gold_label() -> void:
	if lbl_gold:
		lbl_gold.text = "Run Gold: %d" % GameManager.run_gold

func _render_stock() -> void:
	if not items_grid:
		return
	for c in items_grid.get_children():
		c.queue_free()
		
	var stock_list: Array = shop_stock.get(current_category, [])
	for entry in stock_list:
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(300, 100)
		
		var vbox := VBoxContainer.new()
		var title := Label.new()
		var desc := Label.new()
		var btn_buy := Button.new()
		
		var is_sold: bool = entry.get("sold", false)
		var cost: int = entry.get("cost", 30)
		
		if entry.get("is_potion", false):
			title.text = entry.get("name", "Potion")
			title.modulate = Color(0.4, 1.0, 0.4)
			desc.text = entry.get("desc", "")
		else:
			var d: ItemData = entry.get("data", null)
			if d:
				title.text = "%s (Tier %d)" % [d.name, d.tier]
				title.modulate = d.color
				desc.text = d.description
				
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 12)
		
		if is_sold:
			btn_buy.text = "SOLD OUT"
			btn_buy.disabled = true
		else:
			btn_buy.text = "BUY (%d Gold)" % cost
			var cap_entry: Dictionary = entry
			btn_buy.pressed.connect(func(): _attempt_purchase(cap_entry))
			
		vbox.add_child(title)
		vbox.add_child(desc)
		vbox.add_child(btn_buy)
		card.add_child(vbox)
		items_grid.add_child(card)

func _attempt_purchase(entry: Dictionary) -> void:
	var cost: int = entry.get("cost", 30)
	if GameManager.run_gold < cost:
		if AudioManager: AudioManager.play_sfx("ui_error")
		return
		
	if entry.get("is_potion", false):
		if GameManager.potions >= GameManager.MAX_POTIONS:
			if AudioManager: AudioManager.play_sfx("ui_error")
			return
		GameManager.spend_gold(cost)
		GameManager.potions += 1
		GameManager.potion_count_changed.emit(GameManager.potions)
		entry["sold"] = true
		if AudioManager: AudioManager.play_sfx("shop_buy")
	else:
		var d: ItemData = entry.get("data", null)
		if not d: return
		
		# Try to add to backpack first, or altar
		var inst := ItemInstance.new(d)
		if GameManager.backpack_items.size() >= GameManager.BACKPACK_CAPACITY:
			# Check if altar has space
			var placed: bool = false
			for y in range(GameManager.grid_manager.height):
				for x in range(GameManager.grid_manager.width):
					if GameManager.move_item_to_altar(inst, Vector2i(x, y)):
						placed = true
						break
				if placed: break
			if not placed:
				# Inventory completely full!
				if AudioManager: AudioManager.play_sfx("ui_error")
				return
		else:
			GameManager.add_item_to_backpack(inst)
			
		GameManager.spend_gold(cost)
		entry["sold"] = true
		if AudioManager: AudioManager.play_sfx("shop_buy")
		
	_render_stock()
	_refresh_gold_label()
