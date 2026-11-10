class_name CombatSpriteFeedback
extends RefCounted

# Shared presentation-only feedback for enemy and boss sprites.
# All animation runs on a visual wrapper, never on physics or collision nodes.

const TWEEN_META_KEY: StringName = &"_combat_feedback_tween"

static func _begin_tween(target: Node2D) -> Tween:
	if target.has_meta(TWEEN_META_KEY):
		var previous: Tween = target.get_meta(TWEEN_META_KEY)
		if is_instance_valid(previous):
			previous.kill()
	var tween := target.create_tween()
	target.set_meta(TWEEN_META_KEY, tween)
	return tween

static func play_hit(
	target: Node2D,
	push_direction: Vector2 = Vector2.UP,
	intensity: float = 1.0,
	rest_color: Color = Color.WHITE
) -> Tween:
	if not is_instance_valid(target):
		return null
	var tween := _begin_tween(target)
	target.scale = Vector2.ONE
	target.rotation = 0.0
	target.modulate = Color(2.2, 2.2, 2.2, 1.0)
	var direction := push_direction.normalized()
	if direction.length_squared() < 0.001:
		direction = Vector2.UP
	target.rotation = clampf(direction.x * 0.08, -0.08, 0.08) * intensity
	target.scale = Vector2(1.0 + 0.08 * intensity, 1.0 - 0.07 * intensity)
	tween.set_parallel(true)
	tween.tween_property(target, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "rotation", 0.0, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "modulate", rest_color, 0.12)
	return tween

static func play_telegraph(
	target: Node2D,
	direction: Vector2 = Vector2.UP,
	duration: float = 0.4,
	squash: Vector2 = Vector2(1.14, 0.86)
) -> Tween:
	if not is_instance_valid(target):
		return null
	var tween := _begin_tween(target)
	target.scale = Vector2.ONE
	target.rotation = 0.0
	var dir := direction.normalized()
	var lean := clampf(dir.x * 0.06, -0.06, 0.06)
	tween.tween_property(target, "rotation", lean, duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", squash, duration * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", Vector2.ONE, duration * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(target, "rotation", 0.0, duration * 0.55)
	return tween

static func play_death(
	target: Node2D,
	duration: float = 0.3,
	pop_scale: Vector2 = Vector2.ONE,
	final_scale: Vector2 = Vector2(0.1, 0.1)
) -> Tween:
	if not is_instance_valid(target):
		return null
	var tween := _begin_tween(target)
	tween.tween_property(target, "scale", pop_scale, duration * 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(target, "scale", final_scale, duration * 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(target, "modulate:a", 0.0, duration * 0.7)
	return tween
