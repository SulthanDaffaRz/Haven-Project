extends Node2D

signal firefly_collected
signal checkpoint_reached(lamp: Node2D)
signal home_reached

const Art := preload("res://scripts/art.gd")
const LampScript := preload("res://scripts/lamp.gd")
const FireflyScript := preload("res://scripts/firefly.gd")
const MoverScript := preload("res://scripts/mover.gd")
const CrumbleScript := preload("res://scripts/crumble.gd")
const HouseScript := preload("res://scripts/house.gd")
const BuildingScript := preload("res://scripts/building.gd")

const T := 16
const WORLD_TILES_W := 546
const WORLD_TILES_H := 26
const ST := 20
const FIREFLY_DENSITY := 0.55

var ox := 0
var start_pos := Vector2.ZERO
var world_w := 0.0
var world_bottom := 0.0
var death_y := 0.0
var firefly_total := 0
var door_x := 0.0
var goal_rect := Rect2()
var house_node: Node2D


var solid := {}
var info_solids: Array = []
var info_oneways: Array = []
var info_movers: Array = []
var info_crumbles: Array = []
var info_lamps: Array = []
var mover_nodes: Array = []
var _terrain_layer: TileMapLayer
var _tile_set: TileSet
var _tile_source: TileSetAtlasSource
var _tile_source_id := 0
var _flip_alt := {}
var _props: Node2D
var _rng := RandomNumberGenerator.new()


func build() -> void:
	_rng.seed = 20261003
	world_w = WORLD_TILES_W * T
	world_bottom = WORLD_TILES_H * T
	death_y = world_bottom + 60.0

	_make_tileset()
	_terrain_layer = TileMapLayer.new()
	_terrain_layer.tile_set = _tile_set
	add_child(_terrain_layer)
	_props = Node2D.new()
	add_child(_props)

	_layout()

	_build_terrain()
	_build_collision()
	_scatter_grass()
	_add_walls()


#uhhh idk why i made the map like this but its fun
func _layout() -> void:
	start_pos = Vector2(3 * T + 22, ST * T - 1)
	ground(0, 28, ST, ST + 4)
	lamp(3, ST, true)
	fence_run(0.0, 7, ST, 5)
	tree(9, ST, 1)
	bush(6, ST, 5)
	bush(13, ST, 1)
	bench(11.5, ST, 1)
	bin(16.2, ST, 1)
	crate(18, ST * T)
	slab(22, 17, 4, "grass")
	fly_line(7.5, 18.5, 12.5, 18.5, 5)
	fly_arc(14.5, 21.0, 18.5, 2.6, 6)
	fly_line(22.5, 16.2, 25.5, 16.2, 4)
	fly_arc(28.0, 31.5, 18.5, 2.2, 4)
	ground(31, 62, ST, ST + 4)
	ground(40, 48, 18, 19)
	lamp(36, ST)
	bush(33, ST, 2)
	tree(41, 18, 2)
	fly_line(41.5, 16.5, 47.5, 16.5, 5)
	fly_line(50.0, 18.5, 56.0, 18.5, 4)
	bush(51, ST, 6)
	rock(53, ST, 3)
	bench(55, ST, 2)
	lamp(58, ST)
	fly_arc(61.0, 66.5, 18.5, 2.4, 5)
	ground(66, 81, ST, ST + 4)
	tree(68, ST, 3)
	lamp(79, ST)
	slab(84, 18, 3, "jag")
	slab(90, 17, 3, "jag")
	fly_arc(81.0, 85.5, 17.0, 2.3, 4)
	fly_line(84.5, 16.4, 86.5, 16.4, 2)
	fly_arc(87.5, 91.5, 16.2, 2.3, 4)
	fly_line(90.5, 15.3, 92.5, 15.3, 2)
	ground(96, 115, ST, ST + 4)
	tree(100, ST, 4)
	lamp(98, ST)
	bench(105, ST, 2)
	bush(107, ST, 3)
	rock(110, ST, 2)
	fly_line(103.0, 18.5, 108.0, 18.5, 4)
	lamp(113, ST)
	mover(117, 19, 4, 10.0, 0.0, 3.2, "grass")
	fly_line(119.0, 17.2, 129.0, 17.2, 6)

	ground(132, 150, ST, ST + 4)
	lamp(134, ST)
	fence_run(135.0, 6, ST, 6)
	bin(138, ST, 2)
	crate(143, ST * T)
	crate(145, ST * T)
	crate(144, ST * T - 25.0)
	fly_line(139.5, 18.5, 141.5, 18.5, 2)
	fly_arc(146.5, 150.5, 16.5, 2.4, 4)
	slab(149, 17, 3, "stone")
	slab(154, 14, 4, "stone")
	slab(160, 11, 4, "stone")
	lamp(161, 11)
	fly_line(155.0, 12.4, 157.0, 12.4, 3)
	fly_line(160.5, 9.3, 162.5, 9.3, 3)
	crumble(166, 11, 3, "stone")
	crumble(171, 11, 3, "stone")
	crumble(176, 10, 3, "stone")
	fly_arc(164.0, 168.0, 9.3, 2.0, 3)
	fly_arc(169.0, 173.0, 9.3, 2.0, 3)
	fly_arc(174.5, 179.5, 8.4, 2.0, 4)

	building(181, 11, 12, 16, 3)
	building(205, 11, 8, 16, 5)
	slab(181, 10, 12, "stone")
	lamp(184, 10)
	fly_line(186.0, 8.4, 191.0, 8.4, 5)
	mover(194, 10, 4, 6.0, 0.0, 2.8, "stone")
	fly_line(195.0, 8.3, 202.0, 8.3, 5)
	slab(205, 10, 8, "stone")
	lamp(207, 10)
	fly_line(208.5, 8.4, 212.0, 8.4, 3)
	mover(215, 10, 3, 0.0, 8.0, 3.2, "stone")
	fly_line(216.5, 12.0, 216.5, 16.0, 3)

	ground(220, 262, ST, ST + 4)
	lamp(223, ST)
	tree(226, ST, 2)
	fence_run(234.0, 5, ST, 7)
	bush(232, ST, 4)
	bench(240, ST, 1)
	bin(244, ST, 2)
	tree(248, ST, 1)
	crate(252, ST * T)
	crate(254, ST * T)
	slab(256, 17, 3, "grass")
	fly_line(224.5, 18.5, 230.0, 18.5, 4)
	fly_line(238.0, 18.5, 246.0, 18.5, 5)
	fly_line(256.5, 15.4, 258.5, 15.4, 3)
	lamp(260, ST)

	crumble(264, ST, 3, "grass")
	crumble(269, ST, 3, "grass")
	crumble(274, ST, 3, "grass")
	crumble(279, ST, 3, "grass")
	fly_arc(262.5, 267.0, 18.4, 1.8, 3)
	fly_arc(267.5, 272.5, 18.4, 1.8, 3)
	fly_arc(272.5, 277.5, 18.4, 1.8, 3)
	fly_arc(277.5, 283.0, 18.4, 1.8, 3)

	ground(284, 303, ST, ST + 4)
	lamp(286, ST)
	tree(290, ST, 3)
	bush(296, ST, 1)
	fly_line(289.0, 18.5, 297.0, 18.5, 5)

	ox = 304
	ground(0, 11, ST, ST + 4)
	lamp(3, ST)
	crate(6, ST * T)
	bin(9, ST, 2)
	fly_line(1.0, 18.5, 5.0, 18.5, 4)
	fly_arc(5.0, 8.5, 18.5, 2.0, 3)

	slab(14, 18, 3, "stone")
	slab(19, 16, 3, "stone")
	slab(24, 14, 3, "stone")
	fly_arc(10.5, 15.5, 17.0, 2.0, 4)
	fly_arc(16.5, 20.5, 15.0, 2.0, 3)
	fly_arc(21.5, 25.5, 13.0, 2.0, 3)

	crumble(29, 14, 3, "stone")
	crumble(34, 14, 3, "stone")
	fly_arc(27.0, 30.5, 12.6, 1.8, 3)
	fly_arc(32.0, 35.5, 12.6, 1.8, 3)
	building(39, 15, 6, 14, 7)
	slab(39, 14, 6, "stone")
	lamp(41, 14)
	fly_line(39.5, 12.4, 43.5, 12.4, 4)

	mover(47, 14, 3, 0.0, 6.0, 3.0, "stone")
	fly_line(48.5, 15.0, 48.5, 19.0, 3)
	ground(52, 75, ST, ST + 4)
	lamp(54, ST)
	tree(57, ST, 3)
	bench(63, ST, 2)
	crate(67, ST * T)
	crate(69, ST * T)
	crate(68, ST * T - 25.0)
	fly_line(55.5, 18.5, 61.5, 18.5, 5)
	fly_arc(65.0, 71.5, 16.5, 2.5, 5)
	bush(72, ST, 5)

	mover(77, 19, 4, 10.0, 0.0, 3.2, "grass")
	fly_line(79.0, 17.2, 89.0, 17.2, 5)
	ground(92, 99, ST, ST + 4)
	lamp(94, ST)
	fence_run(95.0, 3, ST, 5)
	ox = 100

	ground(304, 309, 18, 24)
	ground(312, 317, 16, 24)
	fly_arc(309.0, 313.5, 16.4, 2.2, 4)
	slab(320, 14, 3, "jag")
	crumble(325, 13, 3, "jag")
	crumble(330, 12, 3, "jag")
	fly_arc(317.0, 321.5, 14.4, 2.2, 3)
	fly_arc(322.5, 327.0, 12.6, 2.0, 3)
	fly_arc(328.0, 332.5, 11.6, 2.0, 3)
	ground(335, 352, 12, 24)
	lamp(337, 12)
	bush(343, 12, 2)
	fly_line(339.0, 10.4, 348.0, 10.4, 5)
	mover(353, 12, 4, 4.0, 0.0, 2.5, "stone")
	fly_line(354.0, 10.3, 358.0, 10.3, 3)
	ground(362, 370, 11, 24)
	lamp(366, 11)

	ground(371, WORLD_TILES_W - 1 - ox, 10, 24)
	lamp(378, 10)
	tree(380, 10, 4)
	bench(388, 10, 1)
	lamp(392, 10)
	bush(396, 10, 3)
	fence_run(398.0, 6, 10, 5)
	lamp(405, 10)
	tree(408, 10, 2)
	bush(413, 10, 1)
	lamp(416, 10)
	fly_line(373.0, 8.4, 383.0, 8.4, 6)
	fly_line(386.0, 8.4, 396.0, 8.4, 5)
	fly_line(399.0, 8.4, 409.0, 8.4, 5)
	fly_line(411.0, 8.4, 421.0, 8.4, 5)
	house(424, 10)
	fence_run(434.0, 4, 10, 6)
	tree(437, 10, 3)
	bush(432, 10, 4)


func ground(x0: int, x1: int, y0: int, y1: int) -> void:
	for x in range(x0 + ox, x1 + ox + 1):
		for y in range(y0, y1 + 1):
			solid[Vector2i(x, y)] = true


func slab(x: int, y: int, w: int, style: String = "stone") -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2((x + ox) * T, y * T)
	body.z_index = 1
	body.add_child(Art.make_slab(w, style))
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w * T, 8)
	shape.shape = rect
	shape.position = Vector2(w * T / 2.0, 4)
	shape.one_way_collision = true
	shape.one_way_collision_margin = 3.0
	body.add_child(shape)
	_props.add_child(body)
	info_oneways.append(Rect2((x + ox) * T, y * T, w * T, 8))


func crumble(x: int, y: int, w: int, style: String = "stone") -> void:
	var c := CrumbleScript.new()
	c.setup(w, style)
	c.position = Vector2((x + ox) * T, y * T)
	_props.add_child(c)
	info_crumbles.append(Rect2((x + ox) * T, y * T, w * T, 8))


func mover(x: int, y: int, w: int, dx: float, dy: float, seconds: float, style: String = "stone") -> void:
	var m := MoverScript.new()
	var travel := Vector2(dx * T, dy * T)
	m.setup(w, travel, seconds, style)
	m.position = Vector2((x + ox) * T, y * T)
	_props.add_child(m)
	mover_nodes.append(m)
	info_movers.append({"rect": Rect2((x + ox) * T, y * T, w * T, 8), "travel": travel})


func crate(x: int, surface_y: float) -> void:
	var size := Vector2(32, 25)
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = Vector2((x + ox) * T, surface_y - size.y)
	body.z_index = 0
	var spr := Sprite2D.new()
	spr.texture = load(Art.OBJECTS + "Other/Box.png")
	spr.centered = false
	body.add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size / 2.0
	body.add_child(shape)
	_props.add_child(body)
	info_solids.append(Rect2(body.position, size))


func lamp(x: int, row: int, lit: bool = false) -> void:
	var l := LampScript.new()
	l.position = Vector2((x + ox) * T + T / 2.0, row * T)
	_props.add_child(l)
	l.activated.connect(func(who: Node2D) -> void: checkpoint_reached.emit(who))
	if lit:
		l.turn_on(false)
	info_lamps.append(l.position)


func fly(x: float, y: float) -> void:
	var f := FireflyScript.new()
	f.position = Vector2((x + ox) * T, y * T)
	f.collected.connect(func() -> void: firefly_collected.emit())
	_props.add_child(f)
	firefly_total += 1


func fly_line(x0: float, y0: float, x1: float, y1: float, count: int) -> void:
	var n := maxi(2, roundi(count * FIREFLY_DENSITY))
	for i in n:
		var t := 0.0 if n == 1 else float(i) / float(n - 1)
		fly(lerpf(x0, x1, t), lerpf(y0, y1, t))

func fly_arc(x0: float, x1: float, y_base: float, height: float, count: int) -> void:
	var n := maxi(2, roundi(count * FIREFLY_DENSITY))
	for i in n:
		var t := 0.5 if n == 1 else float(i) / float(n - 1)
		var lift := 1.0 - pow(2.0 * t - 1.0, 2.0)
		fly(lerpf(x0, x1, t), y_base - height * lift)


func house(x: int, row: int) -> void:
	var h := HouseScript.new()
	h.position = Vector2((x + ox) * T, row * T)
	_props.add_child(h)
	h.reached.connect(func() -> void: home_reached.emit())
	house_node = h
	door_x = (x + ox) * T + HouseScript.DOOR_X
	goal_rect = Rect2((x + ox) * T + 55, row * T - 40, 22, 40)


func _prop(path: String, x: float, row: int, z: int) -> Sprite2D:
	var s := Art.make_prop(Art.OBJECTS + path, Vector2((x + ox) * T, row * T))
	s.z_index = z
	_props.add_child(s)
	return s


func tree(x: float, row: int, kind: int) -> void:
	_prop("Other/Tree%d.png" % kind, x, row, -3)


func bush(x: float, row: int, kind: int) -> void:
	_prop("Bushes/%d.png" % kind, x, row, -1)


func fence(x: float, row: int, kind: int) -> void:
	_prop("Fence/%d.png" % kind, x, row, -4)


func bench(x: float, row: int, kind: int) -> void:
	_prop("Benches/%d.png" % kind, x, row, -1)


func rock(x: float, row: int, kind: int) -> void:
	_prop("Stones/%d.png" % kind, x, row, -1)


func bin(x: float, row: int, kind: int) -> void:
	_prop("Other/Garbage_Can%d.png" % kind, x, row, -1)


func fence_run(x: float, count: int, row: int, kind: int) -> void:
	for i in count:
		fence(x + i * 35.0 / T, row, kind)


func building(x: int, row: int, w: int, rows: int, seed_value: int = 1) -> void:
	var b := BuildingScript.new()
	b.size = Vector2(w * T, rows * T)
	b.seed_value = seed_value
	b.position = Vector2((x + ox) * T, row * T)
	_props.add_child(b)

func _make_tileset() -> void:
	_tile_set = TileSet.new()
	_tile_set.tile_size = Vector2i(T, T)
	_tile_source = TileSetAtlasSource.new()
	_tile_source.texture = load(Art.TILESET_PATH)
	_tile_source.texture_region_size = Vector2i(T, T)
	_tile_source_id = _tile_set.add_source(_tile_source)

	for c in 6:
		for r in 6:
			_tile_source.create_tile(Vector2i(c, r))

	for r in range(0, 6):
		var coords := Vector2i(0, r)
		var alt := _tile_source.create_alternative_tile(coords)
		_tile_source.get_tile_data(coords, alt).flip_h = true
		_flip_alt[coords] = alt


func _build_terrain() -> void:
	for cell in solid.keys():
		var x: int = cell.x
		var y: int = cell.y
		var down_solid := solid.has(Vector2i(x, y + 1))
		var left_empty := not solid.has(Vector2i(x - 1, y))
		var right_empty := not solid.has(Vector2i(x + 1, y))
		var depth := 0
		var yy := y - 1
		while solid.has(Vector2i(x, yy)) and depth < 12:
			depth += 1
			yy -= 1
		var variant := 1 + (x * 7 + y * 3) % 4
		var atlas := Vector2i(variant, 0)
		var alt := 0
		if depth == 0:
			if left_empty:
				atlas = Vector2i(0, 0)
			elif right_empty:
				atlas = Vector2i(5, 0)
		else:
			var row := 5
			if down_solid:
				row = 1 if depth == 1 else 2 + (depth - 2) % 3
			if left_empty:
				atlas = Vector2i(0, row)
			elif right_empty:
				atlas = Vector2i(0, row)
				alt = _flip_alt[atlas]
			else:
				atlas = Vector2i(variant, row)
		_terrain_layer.set_cell(cell, _tile_source_id, atlas, alt)



func _merged_cells() -> Array:
	var by_row := {}
	for cell in solid.keys():
		if not by_row.has(cell.y):
			by_row[cell.y] = []
		by_row[cell.y].append(cell.x)
	var ys: Array = by_row.keys()
	ys.sort()
	var result: Array = []
	var open := {}
	var prev_y := -9999
	for y in ys:
		var xs: Array = by_row[y]
		xs.sort()
		var runs: Array = []
		var start: int = xs[0]
		var last: int = xs[0]
		for i in range(1, xs.size()):
			if xs[i] == last + 1:
				last = xs[i]
			else:
				runs.append([start, last])
				start = xs[i]
				last = xs[i]
		runs.append([start, last])
		var next_open := {}
		for run in runs:
			var key := "%d:%d" % [run[0], run[1]]
			if y == prev_y + 1 and open.has(key):
				var idx: int = open[key]
				result[idx][3] = y
				next_open[key] = idx
			else:
				result.append([run[0], run[1], y, y])
				next_open[key] = result.size() - 1
		open = next_open
		prev_y = y
	return result


func _build_collision() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	for r in _merged_cells():
		var rect := Rect2(r[0] * T, r[2] * T, (r[1] - r[0] + 1) * T, (r[3] - r[2] + 1) * T)
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = rect.size
		shape.shape = rs
		shape.position = rect.position + rect.size / 2.0
		body.add_child(shape)
		info_solids.append(rect)
	add_child(body)



func _scatter_grass() -> void:
	for cell in solid.keys():
		if solid.has(Vector2i(cell.x, cell.y - 1)):
			continue
		if _rng.randf() > 0.22:
			continue
		var kind := _rng.randi_range(1, 8)
		var jitter := _rng.randi_range(0, 8)
		var tuft := Art.make_prop(Art.OBJECTS + "Grass/%d.png" % kind,
				Vector2(cell.x * T + jitter, cell.y * T + 1))
		tuft.z_index = 0
		_props.add_child(tuft)



func _add_walls() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	for rect in [Rect2(-32, -400, 32, world_bottom + 1200), Rect2(world_w, -400, 32, world_bottom + 1200)]:
		var shape := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = rect.size
		shape.shape = rs
		shape.position = rect.position + rect.size / 2.0
		body.add_child(shape)
	add_child(body)



func dump_info() -> Dictionary:
	var as_arr := func(r: Rect2) -> Array:
		return [r.position.x, r.position.y, r.size.x, r.size.y]
	var movers: Array = []
	for m in info_movers:
		movers.append({"rect": as_arr.call(m["rect"]), "travel": [m["travel"].x, m["travel"].y]})
	return {
		"tile": T,
		"start": [start_pos.x, start_pos.y],
		"goal": as_arr.call(goal_rect),
		"world_w": world_w,
		"death_y": death_y,
		"solids": info_solids.map(as_arr),
		"oneways": info_oneways.map(as_arr),
		"crumbles": info_crumbles.map(as_arr),
		"movers": movers,
		"lamps": info_lamps.map(func(v: Vector2) -> Array: return [v.x, v.y]),
		"fireflies": firefly_total,
	}
