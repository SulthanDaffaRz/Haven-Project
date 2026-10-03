extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const LevelScript := preload("res://scripts/level.gd")
const BackgroundScript := preload("res://scripts/background.gd")
const HudScript := preload("res://scripts/hud.gd")
const NIGHT_TINT := Color(0.46, 0.52, 0.84)
const VIEW_HEIGHT := 216.0

var level: Node2D
var player: CharacterBody2D
var camera: Camera2D
var background: CanvasLayer
var hud: CanvasLayer

var checkpoint := Vector2.ZERO
var fireflies := 0
var falls := 0
var elapsed := 0.0
var running := false
var finished := false
var _respawning := false


func _ready() -> void:
	get_viewport().canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	background = BackgroundScript.new()
	add_child(background)

	var night := CanvasModulate.new()
	night.color = NIGHT_TINT
	add_child(night)

	level = LevelScript.new()
	add_child(level)
	level.build()

	player = PlayerScript.new()
	player.z_index = 2
	player.position = level.start_pos
	player.can_control = false
	add_child(player)

	camera = Camera2D.new()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(level.world_w)
	camera.limit_bottom = int(level.world_bottom)
	camera.offset = Vector2(0, -26)
	player.add_child(camera)
	camera.make_current()

	hud = HudScript.new()
	add_child(hud)
	hud.setup(level.firefly_total, level.start_pos.x, level.door_x)

	checkpoint = level.start_pos
	level.firefly_collected.connect(_on_firefly)
	level.checkpoint_reached.connect(_on_checkpoint)
	level.home_reached.connect(_on_home)
	get_viewport().size_changed.connect(_update_zoom)
	_update_zoom()
	camera.reset_smoothing()

	_intro()


func _intro() -> void:
	await hud.play_intro()
	player.can_control = true
	running = true


func _update_zoom() -> void:
	var view := get_viewport().get_visible_rect().size
	var z := maxf(1.0, floorf(view.y / VIEW_HEIGHT))
	camera.zoom = Vector2(z, z)


func _process(delta: float) -> void:
	if running and not finished:
		elapsed += delta
	var view := get_viewport().get_visible_rect().size
	background.update_scroll(camera.get_screen_center_position(), camera.zoom.x, view)
	hud.update_progress(player.global_position.x)

	var ahead := clampf(player.velocity.x * 0.15, -18.0, 18.0)
	camera.offset.x = move_toward(camera.offset.x, ahead, 60.0 * delta)


func _physics_process(_delta: float) -> void:
	if player.global_position.y > level.death_y and not _respawning and not finished:
		_respawn()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	if finished:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			get_tree().reload_current_scene()
	elif not running:
		hud.skip_intro()
	elif event.keycode == KEY_R and not _respawning:
		_respawn()


func _respawn() -> void:
	_respawning = true
	falls += 1
	player.can_control = false
	await hud.fade_to_black(0.2)
	player.respawn_at(checkpoint)
	camera.reset_smoothing()
	await hud.fade_from_black(0.3)
	player.can_control = not finished
	_respawning = false


func _on_firefly() -> void:
	fireflies += 1
	hud.set_fireflies(fireflies)


func _on_checkpoint(lamp: Node2D) -> void:
	checkpoint = lamp.spawn_position
	hud.toast("Checkpoint!")


func _on_home() -> void:
	if finished:
		return
	finished = true
	player.can_control = false
	player.walk_to(level.door_x)
	await player.arrived
	await get_tree().create_timer(0.3).timeout
	player.enter_house()
	level.house_node.open_door_glow()
	await get_tree().create_timer(1.2).timeout
	hud.show_end(fireflies, level.firefly_total, elapsed, falls)
