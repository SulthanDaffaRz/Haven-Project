extends Area2D

signal activated(lamp: Node2D)

const PlayerScript := preload("res://scripts/player.gd")
const OFF_TEX := "res://art/lamp_off.png"
const ON_TEX := "res://art/lamp_on.png"
const LIGHT_TEX := "res://art/light.png"
const GLOW_TEX := "res://art/glow.png"
const POLE_H := 72.0
const BULB := Vector2(0, -62.5)
const WARM := Color(1.0, 0.82, 0.5)

var is_on := false
var spawn_position := Vector2.ZERO

var _pole: Sprite2D
var _light: PointLight2D
var _glow: Sprite2D
var _time := 0.0
var _phase := 0.0
var _start_on := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	z_index = -2
	_phase = randf() * TAU
	spawn_position = global_position + Vector2(0, -1)

	_pole = Sprite2D.new()
	_pole.texture = load(OFF_TEX)
	_pole.centered = false
	_pole.position = Vector2(-8, -POLE_H)
	add_child(_pole)

	_glow = Sprite2D.new()
	_glow.texture = load(GLOW_TEX)
	_glow.position = BULB
	_glow.scale = Vector2(1.1, 1.1)
	_glow.modulate = Color(WARM.r, WARM.g, WARM.b, 0.0)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)

	_light = PointLight2D.new()
	_light.texture = load(LIGHT_TEX)
	_light.texture_scale = 2.6
	_light.color = WARM
	_light.energy = 0.0
	_light.position = BULB
	add_child(_light)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, POLE_H + 40)
	shape.shape = rect
	shape.position = Vector2(0, -(POLE_H + 40) / 2.0)
	add_child(shape)

	body_entered.connect(_on_body_entered)
	if _start_on:
		turn_on(false)


func _process(delta: float) -> void:
	if is_on:
		_time += delta
		_light.energy = 1.0 + 0.06 * sin(_time * 9.0 + _phase) + 0.04 * sin(_time * 23.0)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerScript and not is_on:
		turn_on(true)
		activated.emit(self)


func turn_on(animate: bool) -> void:
	is_on = true
	if _pole == null:
		_start_on = true
		return
	_pole.texture = load(ON_TEX)
	if animate:
		var tw := create_tween()
		tw.set_parallel(true)
		tw.tween_property(_light, "energy", 1.0, 0.45)
		tw.tween_property(_glow, "modulate:a", 0.7, 0.45)
	else:
		_light.energy = 1.0
		_glow.modulate.a = 0.7
