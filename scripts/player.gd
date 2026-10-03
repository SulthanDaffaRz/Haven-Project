extends CharacterBody2D
signal jumped
signal landed
signal arrived


const SPEED := 120.0
const GROUND_ACCEL := 1000.0
const GROUND_FRICTION := 1400.0
const AIR_ACCEL := 750.0
const AIR_FRICTION := 300.0
const GRAVITY := 900.0
const FALL_GRAVITY_MULT := 1.35
const MAX_FALL_SPEED := 420.0
const JUMP_VELOCITY := -340.0
const JUMP_CUT := 0.45
const COYOTE_TIME := 0.10     # so uhh u can still jump just after walking off a ledge
const JUMP_BUFFER := 0.12

const IDLE_SHEET := "res://craftpix-net-481510-free-townspeople-cyberpunk-pixel-art/11/Idle.png"
const WALK_SHEET := "res://craftpix-net-481510-free-townspeople-cyberpunk-pixel-art/11/Walk.png"
const LIGHT_TEX := "res://art/light.png"
const FRAME := 48
const BODY_CENTER_OFFSET := 10.0
const FEET_OFFSET := 24.0

var can_control := true

var _facing := 1
var _coyote := 0.0
var _buffer := 0.0
var _prev_vy := 0.0
var _was_on_floor := true
var _walking_to := false
var _walk_target := 0.0

var _visual: Node2D
var _sprite: AnimatedSprite2D
var _dust: CPUParticles2D
var _squash_tween: Tween


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 4.0

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 24)
	shape.shape = rect
	shape.position = Vector2(0, -12)
	add_child(shape)

	_visual = Node2D.new()
	add_child(_visual)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = _build_frames()
	_sprite.position = Vector2(BODY_CENTER_OFFSET, -FEET_OFFSET)
	_visual.add_child(_sprite)
	_sprite.play("idle")

	var glow := PointLight2D.new()
	glow.texture = load(LIGHT_TEX)
	glow.texture_scale = 0.8
	glow.energy = 0.55
	glow.color = Color(1.0, 0.88, 0.68)
	glow.position = Vector2(0, -14)
	add_child(glow)

	_dust = CPUParticles2D.new()
	_dust.emitting = false
	_dust.one_shot = true
	_dust.amount = 8
	_dust.lifetime = 0.4
	_dust.explosiveness = 1.0
	_dust.local_coords = false
	_dust.direction = Vector2(0, -1)
	_dust.spread = 75.0
	_dust.initial_velocity_min = 18.0
	_dust.initial_velocity_max = 42.0
	_dust.gravity = Vector2(0, 90)
	_dust.scale_amount_min = 1.0
	_dust.scale_amount_max = 2.0
	_dust.color = Color(0.78, 0.84, 0.95, 0.75)
	_dust.position = Vector2(0, -1)
	add_child(_dust)


func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	var idle_tex: Texture2D = load(IDLE_SHEET)
	var walk_tex: Texture2D = load(WALK_SHEET)
	_add_animation(frames, "idle", idle_tex, [0, 1, 2, 3], 5.0, true)
	_add_animation(frames, "walk", walk_tex, [0, 1, 2, 3, 4, 5], 11.0, true)
	_add_animation(frames, "jump", walk_tex, [3], 1.0, false)
	_add_animation(frames, "fall", walk_tex, [2], 1.0, false)
	return frames


func _add_animation(frames: SpriteFrames, anim: String, sheet: Texture2D,
		indices: Array, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in indices:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(int(i) * FRAME, 0, FRAME, FRAME)
		atlas.filter_clip = true
		frames.add_frame(anim, atlas)


func respawn_at(pos: Vector2) -> void:
	global_position = pos
	velocity = Vector2.ZERO
	_coyote = 0.0
	_buffer = 0.0
	_was_on_floor = true
	_prev_vy = 0.0
	_visual.scale = Vector2.ONE
	_visual.modulate.a = 1.0

func walk_to(x: float) -> void:
	_walking_to = true
	_walk_target = x

func enter_house() -> void:
	var tw := create_tween()
	tw.tween_property(_visual, "modulate:a", 0.0, 0.5)


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	#the y
	if on_floor:
		_coyote = COYOTE_TIME
	else:
		_coyote = maxf(_coyote - delta, 0.0)
	if can_control and Input.is_action_just_pressed("jump"):
		_buffer = JUMP_BUFFER
	else:
		_buffer = maxf(_buffer - delta, 0.0)

	if not on_floor:
		var g := GRAVITY
		if velocity.y > 0.0:
			g *= FALL_GRAVITY_MULT
		velocity.y = minf(velocity.y + g * delta, MAX_FALL_SPEED)

	if _buffer > 0.0 and _coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		_buffer = 0.0
		_coyote = 0.0
		jumped.emit()
		_squash(0.8, 1.25, 0.25)
		_puff()
	if can_control and Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= JUMP_CUT
	#the x
	var dir := 0.0
	if can_control:
		dir = Input.get_axis("lef", "right")
	elif _walking_to:
		var dx := _walk_target - global_position.x
		if absf(dx) < 2.0:
			_walking_to = false
			arrived.emit()
		else:
			dir = signf(dx) * 0.5

	var accel := GROUND_ACCEL if on_floor else AIR_ACCEL
	var friction := GROUND_FRICTION if on_floor else AIR_FRICTION
	if dir != 0.0:
		velocity.x = move_toward(velocity.x, dir * SPEED, accel * delta)
		_facing = 1 if dir > 0.0 else -1
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	_prev_vy = velocity.y
	move_and_slide()

	if is_on_floor() and not _was_on_floor:
		if _prev_vy > 140.0:
			_squash(1.3, 0.72, 0.22)
			_puff()
		landed.emit()
	_was_on_floor = is_on_floor()

	_animate(dir)


func _animate(dir: float) -> void:
	_sprite.flip_h = _facing < 0
	_sprite.position.x = -BODY_CENTER_OFFSET if _facing < 0 else BODY_CENTER_OFFSET

	var anim := "idle"
	if not is_on_floor():
		anim = "jump" if velocity.y < 0.0 else "fall"
		_sprite.speed_scale = 1.0
	elif absf(velocity.x) > 10.0 and dir != 0.0:
		anim = "walk"
		_sprite.speed_scale = clampf(absf(velocity.x) / SPEED, 0.5, 1.2)
	else:
		_sprite.speed_scale = 1.0
	if _sprite.animation != anim:
		_sprite.play(anim)


func _squash(sx: float, sy: float, time: float) -> void:
	if _squash_tween:
		_squash_tween.kill()
	_visual.scale = Vector2(sx, sy)
	_squash_tween = create_tween()
	_squash_tween.set_trans(Tween.TRANS_BACK)
	_squash_tween.set_ease(Tween.EASE_OUT)
	_squash_tween.tween_property(_visual, "scale", Vector2.ONE, time)


func _puff() -> void:
	_dust.restart()
	_dust.emitting = true
