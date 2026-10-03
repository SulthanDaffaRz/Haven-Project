extends StaticBody2D
const PlayerScript := preload("res://scripts/player.gd")
const Art := preload("res://scripts/art.gd")
const TILE := 16
const SHAKE_TIME := 0.5
const GONE_TIME := 2.4

var width_tiles := 3
var style := "stone"

var _visual: Node2D
var _shape: CollisionShape2D
var _trigger: Area2D
var _busy := false


func setup(w: int, style_name: String) -> void:
	width_tiles = w
	style = style_name


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	z_index = 1

	_visual = Art.make_slab(width_tiles, style)
	add_child(_visual)

	_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * TILE, 8)
	_shape.shape = rect
	_shape.position = Vector2(width_tiles * TILE / 2.0, 4)
	_shape.one_way_collision = true
	_shape.one_way_collision_margin = 3.0
	add_child(_shape)

	_trigger = Area2D.new()
	_trigger.collision_layer = 0
	_trigger.collision_mask = 2
	var sensor := CollisionShape2D.new()
	var sensor_rect := RectangleShape2D.new()
	sensor_rect.size = Vector2(width_tiles * TILE - 4, 6)
	sensor.shape = sensor_rect
	sensor.position = Vector2(width_tiles * TILE / 2.0, -2)
	_trigger.add_child(sensor)
	add_child(_trigger)


func _physics_process(_delta: float) -> void:
	if _busy:
		return
	for body in _trigger.get_overlapping_bodies():
		if body is PlayerScript and body.is_on_floor() and body.velocity.y >= 0.0:
			_crumble()
			return


func _crumble() -> void:
	_busy = true
	var shake := create_tween()
	for i in 8:
		var dx := 1.0 if i % 2 == 0 else -1.0
		shake.tween_property(_visual, "position:x", dx, SHAKE_TIME / 8.0)
	shake.tween_property(_visual, "position:x", 0.0, 0.02)
	await shake.finished

	_shape.set_deferred("disabled", true)
	var fall := create_tween()
	fall.set_parallel(true)
	fall.tween_property(_visual, "position:y", 40.0, 0.5).set_ease(Tween.EASE_IN)
	fall.tween_property(_visual, "modulate:a", 0.0, 0.5)
	await fall.finished

	await get_tree().create_timer(GONE_TIME).timeout

	_visual.position = Vector2.ZERO
	_shape.set_deferred("disabled", false)
	var back := create_tween()
	back.tween_property(_visual, "modulate:a", 1.0, 0.35)
	await back.finished
	_busy = false
