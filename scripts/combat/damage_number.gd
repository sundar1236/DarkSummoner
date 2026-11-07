class_name DamageNumber
extends Node2D

# Lightweight floating damage indicator with critical bounce and smooth fade out.

var label: Label

func _init() -> void:
	z_index = 50

func setup(amount: float, is_crit: bool, start_pos: Vector2) -> void:
	global_position = start_pos + Vector2(randf_range(-12.0, 12.0), randf_range(-10.0, 5.0))
	
	label = Label.new()
	var val: int = int(round(amount))
	
	if is_crit:
		label.text = "CRIT! %d" % val
		label.modulate = Color(1.0, 0.85, 0.15, 1.0)
		scale = Vector2(1.3, 1.3)
	else:
		label.text = "%d" % val
		label.modulate = Color(1.0, 1.0, 1.0, 0.95)
		scale = Vector2(1.0, 1.0)
		
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = -Vector2(40, 15)
	label.size = Vector2(80, 30)
	add_child(label)
	
	var tween := create_tween().set_parallel(true)
	# Float upward
	var target_y := global_position.y - (55.0 if is_crit else 40.0)
	tween.tween_property(self, "global_position:y", target_y, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Scale punch
	if is_crit:
		tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
