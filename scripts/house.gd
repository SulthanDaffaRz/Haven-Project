extends Node2D
signal reached

const PlayerScript := preload("res://scripts/player.gd")
const HOUSE_TEX := "res://art/house.png"
const LIGHT_TEX := "res://art/light.png"
const GLOW_TEX := "res://art/glow.png"
const HOUSE_SIZE := Vector2(128, 112)
const DOOR_X := 66.0

var _door_light: PointLight2D


func door_world_x() -> float:
	return global_position.x + DOOR_X


func _ready() -> void:
	z_index = -1

	var spr := Sprite2D.new()
	spr.texture = load(HOUSE_TEX)
	spr.centered = false
	spr.position = Vector2(0, -HOUSE_SIZE.y)
	add_child(spr)

	var warm := Color(1.0, 0.8, 0.5)
	for spec in [[Vector2(35, -40), 2.0, 0.26], [Vector2(99, -40), 2.0, 0.26], [Vector2(67, -48), 2.6, 0.30]]:
		var light := PointLight2D.new()
		light.texture = load(LIGHT_TEX)
		light.color = warm
		light.position = spec[0]
		light.texture_scale = spec[1]
		light.energy = spec[2]
		add_child(light)
		
	var beacon := Sprite2D.new()
	beacon.texture = load(GLOW_TEX)
	beacon.position = Vector2(67, -60)
	beacon.scale = Vector2(4.0, 4.0)
	beacon.modulate = Color(1.0, 0.75, 0.4, 0.09)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	beacon.material = mat
	add_child(beacon)

	_door_light = PointLight2D.new()
	_door_light.texture = load(LIGHT_TEX)
	_door_light.color = Color(1.0, 0.9, 0.7)
	_door_light.position = Vector2(DOOR_X, -22)
	_door_light.texture_scale = 1.6
	_door_light.energy = 0.0
	add_child(_door_light)

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(22, 40)
	shape.shape = rect
	shape.position = Vector2(DOOR_X, -20)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)


func open_door_glow() -> void:
	var tw := create_tween()
	tw.tween_property(_door_light, "energy", 0.6, 0.4)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerScript:
		reached.emit()
