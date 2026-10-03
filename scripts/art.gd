extends RefCounted
const TILESET_PATH := "res://craftpix-net-846754-free-green-zone-tileset-pixel-art/Tileset.png"
const OBJECTS := "res://craftpix-net-846754-free-green-zone-tileset-pixel-art/3 Objects/"
const TILE := 16

static func tile_texture(col: int, row: int) -> AtlasTexture:
	var tex := AtlasTexture.new()
	tex.atlas = load(TILESET_PATH)
	tex.region = Rect2(col * TILE, row * TILE, TILE, TILE)
	return tex

static func make_slab(width: int, style: String) -> Node2D:
	var root := Node2D.new()
	var w: int = maxi(width, 2)
	var left := 0
	var right := 0
	var mid: Array = [1]
	var first_row := 0
	match style:
		"stone":
			first_row = 2
			left = 16
			right = 21
			mid = [17, 18, 19, 20]
		"grass":
			if w == 2:
				first_row = 8
				left = 6
				right = 7
			else:
				first_row = 0
				left = 10
				right = 15
				mid = [11, 12, 13, 14]
		_: 
			first_row = 8
			if w == 2:
				left = 6
				right = 7
			else:
				left = 0
				right = 5
				mid = [1, 2, 3, 4]
	for i in w:
		var col := 0
		if i == 0:
			col = left
		elif i == w - 1:
			col = right
		else:
			col = mid[(i - 1) % mid.size()]
		for r in 2:
			var spr := Sprite2D.new()
			spr.centered = false
			spr.texture = tile_texture(col, first_row + r)
			spr.position = Vector2(i * TILE, r * TILE)
			root.add_child(spr)
	return root


static func make_prop(path: String, bottom_left: Vector2) -> Sprite2D:
	var spr := Sprite2D.new()
	var tex: Texture2D = load(path)
	spr.texture = tex
	spr.centered = false
	spr.position = bottom_left - Vector2(0, tex.get_height())
	return spr
