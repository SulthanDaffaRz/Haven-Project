extends CanvasLayer

const NIGHT_DIR := "res://craftpix-net-846754-free-green-zone-tileset-pixel-art/2 Background/Night/"
const MOON_TEX := "res://art/moon.png"
const GLOW_TEX := "res://art/glow.png"
const TEX_W := 576.0
const TEX_H := 324.0
const REST_CAM_Y := 270.0

const LAYERS := [
	["2.png", 0.05, 0.03, Color(0.50, 0.56, 0.95)], 
	["3.png", 0.12, 0.06, Color(0.36, 0.40, 0.78)],
	["4.png", 0.20, 0.09, Color(0.45, 0.50, 0.85)],
	["5.png", 0.32, 0.12, Color(0.55, 0.62, 0.95)],
]

var _sky: Sprite2D
var _stars: Node2D
var _moon: Sprite2D
var _moon_glow: Sprite2D
var _layers: Array = []


class StarField extends Node2D:
	var stars: Array = []
	var area := Vector2(1152, 648)
	var _t := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 77
		for i in 90:
			stars.append([rng.randf(), rng.randf() * 0.62, rng.randf_range(0.6, 2.4),
					rng.randf() * TAU, 2.0 if rng.randf() > 0.25 else 3.0])

	func _process(delta: float) -> void:
		_t += delta
		queue_redraw()

	func _draw() -> void:
		for s in stars:
			var a := 0.30 + 0.70 * (0.5 + 0.5 * sin(_t * s[2] + s[3]))
			draw_rect(Rect2(floorf(s[0] * area.x), floorf(s[1] * area.y), s[4], s[4]),
					Color(1.0, 0.97, 0.85, a))


func _ready() -> void:
	layer = -10

	_sky = _make_sprite(NIGHT_DIR + "1.png", Color(0.20, 0.26, 0.66))
	add_child(_sky)

	_stars = StarField.new()
	add_child(_stars)

	for i in LAYERS.size():
		if i == LAYERS.size() - 1:
			_add_moon()
		var def: Array = LAYERS[i]
		var spr := _make_sprite(NIGHT_DIR + String(def[0]), def[3])
		add_child(spr)
		_layers.append({"sprite": spr, "px": def[1], "py": def[2]})


func _add_moon() -> void:
	_moon_glow = Sprite2D.new()
	_moon_glow.texture = load(GLOW_TEX)
	_moon_glow.modulate = Color(0.75, 0.82, 1.0, 0.30)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_moon_glow.material = mat
	add_child(_moon_glow)
	_moon = Sprite2D.new()
	_moon.texture = load(MOON_TEX)
	add_child(_moon)


func _make_sprite(path: String, tint: Color) -> Sprite2D:
	var spr := Sprite2D.new()
	spr.texture = load(path)
	spr.centered = false
	spr.region_enabled = true
	spr.region_rect = Rect2(0, 0, TEX_W, TEX_H)
	spr.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	spr.modulate = tint
	return spr



func update_scroll(cam: Vector2, zoom: float, view: Vector2) -> void:
	var s := ceilf(maxf(view.x / TEX_W, view.y / TEX_H) * 1.15)
	var extra := TEX_H * s - view.y

	_stars.area = view

	_place(_sky, s, 0.0, 0.0, cam, zoom, view, extra)
	for l in _layers:
		_place(l["sprite"], s, l["px"], l["py"], cam, zoom, view, extra)

	var drift := -cam.x * zoom * 0.01
	_moon.scale = Vector2(s, s)
	_moon.position = Vector2(view.x * 0.80 + drift, view.y * 0.20 - extra * 0.0)
	_moon_glow.scale = Vector2(s * 5.5, s * 5.5)
	_moon_glow.position = _moon.position


func _place(spr: Sprite2D, s: float, px: float, py: float, cam: Vector2,
		zoom: float, view: Vector2, extra: float) -> void:
	spr.scale = Vector2(s, s)
	var scroll := cam.x * zoom * px / s
	spr.region_rect = Rect2(scroll, 0.0, view.x / s + 2.0, TEX_H)
	var shift := clampf(extra * 0.35 + (REST_CAM_Y - cam.y) * zoom * py, 0.0, extra)
	spr.position = Vector2(0.0, view.y - TEX_H * s + shift)
