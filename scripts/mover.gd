extends AnimatableBody2D

const Art := preload("res://scripts/art.gd")
const TILE := 16

var width_tiles := 3
var travel := Vector2.ZERO
var duration := 3.0
var style := "stone"


func setup(w: int, travel_px: Vector2, seconds: float, style_name: String) -> void:
	width_tiles = w
	travel = travel_px
	duration = seconds
	style = style_name


func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	sync_to_physics = true
	z_index = 1

	add_child(Art.make_slab(width_tiles, style))

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(width_tiles * TILE, 8)
	shape.shape = rect
	shape.position = Vector2(width_tiles * TILE / 2.0, 4)
	shape.one_way_collision = true
	shape.one_way_collision_margin = 3.0
	add_child(shape)

	var start := position
	var tw := create_tween()
	tw.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tw.set_loops()
	tw.set_trans(Tween.TRANS_SINE)
	tw.set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "position", start + travel, duration)
	tw.tween_interval(0.25)
	tw.tween_property(self, "position", start, duration)
	tw.tween_interval(0.25)
