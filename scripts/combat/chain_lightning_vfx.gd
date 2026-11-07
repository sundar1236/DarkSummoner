class_name ChainLightningVFX
extends Node2D

# High-voltage branching lightning visual effect connecting chained targets with electric arcs.

var targets: Array[Vector2] = []
var life_timer: float = 0.25
var points: Array[Vector2] = []

func setup(p_points: Array[Vector2]) -> void:
	targets = p_points
	_generate_jagged_path()
	queue_redraw()
	
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, life_timer).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _generate_jagged_path() -> void:
	points.clear()
	if targets.size() < 2:
		return
		
	for i in range(targets.size() - 1):
		var p1 := targets[i]
		var p2 := targets[i + 1]
		var dist := p1.distance_to(p2)
		var segments := maxi(int(dist / 25.0), 2)
		
		points.append(p1)
		for s in range(1, segments):
			var t := float(s) / float(segments)
			var mid := p1.lerp(p2, t)
			var normal := (p2 - p1).orthogonal().normalized()
			var jitter := normal * randf_range(-14.0, 14.0)
			points.append(mid + jitter)
		points.append(p2)

func _draw() -> void:
	if points.size() < 2:
		return
		
	# Outer glowing cyan aura
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], Color(0.2, 0.7, 1.0, 0.5), 6.0)
		draw_line(points[i], points[i + 1], Color(0.6, 0.9, 1.0, 0.8), 3.0)
		draw_line(points[i], points[i + 1], Color(1.0, 1.0, 1.0, 1.0), 1.5)
		
	# Impact sparks at each target node
	for p in targets:
		draw_circle(p, 8.0, Color(0.4, 0.9, 1.0, 0.6))
		draw_circle(p, 4.0, Color(1.0, 1.0, 1.0, 0.95))
