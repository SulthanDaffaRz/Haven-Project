extends Node2D

var size := Vector2(96, 240)
var seed_value := 1

var _lit_layer: Node2D


func _ready() -> void:
	z_index = -5
	_lit_layer = Node2D.new()
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	_lit_layer.material = mat
	_lit_layer.draw.connect(_draw_lit)
	add_child(_lit_layer)


func _cells() -> Array:
	var out: Array = []
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var cols := int((size.x - 12.0) / 16.0)
	var rows := int((size.y - 20.0) / 22.0)
	for r in rows:
		for c in cols:
			out.append([c, r, rng.randf() < 0.33])
	return out


func _window_rect(c: int, r: int) -> Rect2:
	var cols := int((size.x - 12.0) / 16.0)
	var margin_x := (size.x - cols * 16.0) / 2.0 + 3.0
	return Rect2(margin_x + c * 16.0, 14.0 + r * 22.0, 9.0, 12.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.13, 0.15, 0.30))
	draw_rect(Rect2(-3, 0, size.x + 6, 6), Color(0.20, 0.23, 0.42))
	draw_rect(Rect2(0, 6, 3, size.y - 6), Color(0.09, 0.10, 0.22))
	for cell in _cells():
		if not cell[2]:
			draw_rect(_window_rect(cell[0], cell[1]), Color(0.08, 0.10, 0.21))


func _draw_lit() -> void:
	for cell in _cells():
		if cell[2]:
			_lit_layer.draw_rect(_window_rect(cell[0], cell[1]), Color(1.0, 0.82, 0.48, 0.95))
