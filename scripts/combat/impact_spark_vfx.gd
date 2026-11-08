class_name ImpactSparkVFX
extends Node2D

# Crisp impact spark effect triggered upon weapon hits and critical strikes.

var sprite: Sprite2D

func setup(is_crit: bool, hit_pos: Vector2, hit_normal: Vector2 = Vector2.ZERO, tint: Color = Color.WHITE) -> void:
	global_position = hit_pos
	z_index = 35
	
	sprite = Sprite2D.new()
	var tex_path := "res://assets/sprites/vfx/impact_crit.png" if is_crit else "res://assets/sprites/vfx/impact_spark.png"
	sprite.texture = TextureLoader.get_texture(tex_path)
	
	if hit_normal.length_squared() > 0.01:
		sprite.rotation = hit_normal.angle()
	else:
		sprite.rotation = randf() * TAU
		
	sprite.modulate = tint
	sprite.scale = Vector2(0.3, 0.3)
	add_child(sprite)
	
	var tw := create_tween().set_parallel(true)
	var target_scale := Vector2(1.1, 1.1) if is_crit else Vector2(0.85, 0.85)
	var duration := 0.16 if is_crit else 0.11
	
	tw.tween_property(sprite, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)
