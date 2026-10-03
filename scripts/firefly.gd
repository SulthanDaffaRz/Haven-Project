extends Area2D

signal collected

const PlayerScript := preload("res://scripts/player.gd")
const GLOW_TEX := "res://art/glow.png"
const LIGHT_TEX := "res://art/light.png"
const COLOR := Color(0.85, 1.0, 0.45)

var _home := Vector2.ZERO
var _time := 0.0
var _taken := false
var _glow: Sprite2D
var _light: PointLight2D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = 3
	_home = position
	_time = randf() * TAU

	_glow = Sprite2D.new()
	_glow.texture = load(GLOW_TEX)
	_glow.scale = Vector2(0.4, 0.4)
	_glow.modulate = Color(COLOR.r, COLOR.g, COLOR.b, 0.95)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)

	_light = PointLight2D.new()
	_light.texture = load(LIGHT_TEX)
	_light.texture_scale = 0.45
	_light.color = COLOR
	_light.energy = 0.7
	add_child(_light)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	add_child(shape)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	if _taken:
		return
	_time += delta
	position = _home + Vector2(sin(_time * 1.3) * 3.0, cos(_time * 1.7) * 3.5)
	var pulse := 0.75 + 0.25 * sin(_time * 3.1)
	_glow.modulate.a = 0.95 * pulse
	_light.energy = 0.7 * pulse


func _on_body_entered(body: Node2D) -> void:
	if _taken or not (body is PlayerScript):
		return
	_taken = true
	collected.emit()

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_glow, "scale", Vector2(1.1, 1.1), 0.25)
	tw.tween_property(_glow, "modulate:a", 0.0, 0.25)
	tw.tween_property(_light, "energy", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
