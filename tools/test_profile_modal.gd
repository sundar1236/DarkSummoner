extends SceneTree

func _init() -> void:
	var scene = load("res://scenes/ui/player_profile_modal.tscn")
	var modal = scene.instantiate() as PlayerProfileModal
	root.add_child(modal)
	modal.open_modal()
	
	print("Modal visible: ", modal.visible)
	print("Backdrop visible: ", modal.backdrop.visible)
	print("Card visible: ", modal.card.visible)
	print("Card size: ", modal.card.size)
	print("Card modulate: ", modal.card.modulate)
	print("Card scale: ", modal.card.scale)
	
	for child in modal.card.get_node("VBox").get_children():
		print("  VBox child: ", child.name, " size: ", child.size, " visible: ", child.visible)
		
	quit(0)
