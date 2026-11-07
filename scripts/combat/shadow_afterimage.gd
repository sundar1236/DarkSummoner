class_name ShadowAfterimage
extends Sprite2D

# Fading shadow afterimage left during dodge dash.

func setup(p_texture: Texture2D, p_pos: Vector2, p_rot: float, p_flip_h: bool, tint: Color = Color(0.6, 0.2, 0.9, 0.55)) -> void:
	texture = p_texture
	global_position = p_pos
	rotation = p_rot
	flip_h = p_flip_h
	modulate = tint
	z_index = -1
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", scale * 1.15, 0.35)
	tween.tween_callback(queue_free)
