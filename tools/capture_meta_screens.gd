class_name CaptureMetaScreens
extends SceneTree

# Renders each screen to an off-screen SubViewport and captures high-res PNG screenshots.

var screen_index: int = 0
var screens: Array[Dictionary] = [
	{ "name": "screen_campaign_hub", "scene": "res://scenes/main/main_shell.tscn", "setup": "campaign" },
	{ "name": "screen_hero_characters", "scene": "res://scenes/characters/hero_loadout_screen.tscn", "setup": "characters" },
	{ "name": "screen_hero_gear", "scene": "res://scenes/characters/hero_loadout_screen.tscn", "setup": "gear" },
	{ "name": "screen_hero_runes_altar", "scene": "res://scenes/characters/hero_loadout_screen.tscn", "setup": "runes" },
	{ "name": "screen_talent_collectibles", "scene": "res://scenes/collectibles/collectible_screen.tscn", "setup": "none" },
	{ "name": "screen_shop_market", "scene": "res://scenes/shops/shop_screen.tscn", "setup": "none" },
	{ "name": "screen_valkyrie_draft_modal", "scene": "res://scenes/ui/skill_draft_modal.tscn", "setup": "modal" },
	{ "name": "screen_combat_arena_hud", "scene": "res://scenes/combat/combat_arena.tscn", "setup": "arena" }
]

func _init() -> void:
	_capture_next()

func _capture_next() -> void:
	if screen_index >= screens.size():
		print("All screenshots captured successfully!")
		quit(0)
		return
		
	var entry: Dictionary = screens[screen_index]
	var scn_res := load(entry["scene"]) as PackedScene
	if not scn_res:
		screen_index += 1
		_capture_next()
		return
		
	var inst := scn_res.instantiate() as Control
	if not inst:
		# Could be Node2D (CombatArena)
		var node2d := scn_res.instantiate()
		root.add_child(node2d)
		_wait_and_save(node2d, entry)
		return
		
	root.add_child(inst)
	inst.size = Vector2(720, 1280)
	
	if entry["setup"] == "campaign" and inst is MainShellUI:
		inst._switch_to_tab(2)
	elif entry["setup"] == "characters" and inst is HeroLoadoutScreen:
		inst._switch_subtab(0)
	elif entry["setup"] == "gear" and inst is HeroLoadoutScreen:
		inst._switch_subtab(1)
	elif entry["setup"] == "runes" and inst is HeroLoadoutScreen:
		inst._switch_subtab(2)
	elif entry["setup"] == "modal" and inst is SkillDraftModal:
		inst.show_draft()
		
	_wait_and_save(inst, entry)

func _wait_and_save(node: Node, entry: Dictionary) -> void:
	create_timer(0.1).timeout.connect(func():
		var img := root.get_texture().get_image()
		var out_path := "res://screenshots/%s.png" % entry["name"]
		DirAccess.make_dir_recursive_absolute("D:/work drive/AbyssalAltar/screenshots")
		img.save_png(ProjectSettings.globalize_path(out_path))
		print("Saved screenshot: %s" % out_path)
		node.queue_free()
		screen_index += 1
		create_timer(0.05).timeout.connect(_capture_next)
	)
