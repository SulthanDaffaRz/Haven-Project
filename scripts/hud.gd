extends CanvasLayer


const HOUSE_TEX := "res://art/house.png"
const IDLE_SHEET := "res://craftpix-net-481510-free-townspeople-cyberpunk-pixel-art/11/Idle.png"
const BAR_W := 420.0

var _fire_label: Label
var _toast: Label
var _fade: ColorRect
var _title: Label
var _bar_fill: ColorRect
var _kid_icon: TextureRect
var _end_panel: Control
var _end_stats: Label

var _total := 0
var _start_x := 0.0
var _goal_x := 1.0
var _toast_tween: Tween
var _skip := false
var _controls: Label


func _ready() -> void:
	layer = 10

	_fire_label = _make_label("", 26)
	_fire_label.position = Vector2(24, 18)
	add_child(_fire_label)

	var bar := Control.new()
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	bar.offset_left = -BAR_W / 2.0
	bar.offset_right = BAR_W / 2.0
	bar.offset_top = 14.0
	bar.offset_bottom = 54.0
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	var track := ColorRect.new()
	track.color = Color(0, 0, 0, 0.55)
	track.position = Vector2(0, 32)
	track.size = Vector2(BAR_W, 8)
	bar.add_child(track)
	_bar_fill = ColorRect.new()
	_bar_fill.color = Color(1.0, 0.8, 0.45)
	_bar_fill.position = Vector2(1, 33)
	_bar_fill.size = Vector2(0, 6)
	bar.add_child(_bar_fill)

	var home := TextureRect.new()
	home.texture = load(HOUSE_TEX)
	home.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	home.stretch_mode = TextureRect.STRETCH_SCALE
	home.size = Vector2(36, 31)
	home.position = Vector2(BAR_W - 28, 40 - 31)
	bar.add_child(home)

	var kid_tex := AtlasTexture.new()
	kid_tex.atlas = load(IDLE_SHEET)
	kid_tex.region = Rect2(4, 20, 24, 28)
	_kid_icon = TextureRect.new()
	_kid_icon.texture = kid_tex
	_kid_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_kid_icon.size = Vector2(24, 28)
	_kid_icon.position = Vector2(-12, 40 - 28)
	bar.add_child(_kid_icon)

	_toast = _make_label("", 22)
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_top = 70
	_toast.offset_left = -300
	_toast.offset_right = 300
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	add_child(_toast)

	_end_panel = Control.new()
	_end_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_panel.visible = false
	add_child(_end_panel)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.02, 0.03, 0.10, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_panel.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end_panel.add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 18)
	center.add_child(box)
	var heading := _make_label("HOME SWEET HOME", 60)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.modulate = Color(1.0, 0.85, 0.55)
	box.add_child(heading)
	var story := _make_label("The porch light is on, and you made it back before it got any later.", 24)
	story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(story)
	_end_stats = _make_label("", 26)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_end_stats)
	var again := _make_label("Press Enter to play again", 22)
	again.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	again.modulate = Color(1, 1, 1, 0.75)
	box.add_child(again)

	# --- controls hint (bottom centre) ---
	_controls = _make_label("A / D or arrows: move      Space / W / Up: jump      R: back to the last lamp", 20)
	_controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_controls.offset_left = -520
	_controls.offset_right = 520
	_controls.offset_top = -64
	_controls.offset_bottom = -24
	_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_controls.modulate.a = 0.0
	add_child(_controls)

	# --- story title + fade (drawn last, on top) ---
	_fade = ColorRect.new()
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.color = Color(0.01, 0.015, 0.05, 1.0)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)

	_title = _make_label("", 34)
	_title.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.modulate.a = 0.0
	_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_title)


func _make_label(text: String, size: int) -> Label:
	var label := Label.new()
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = Color(1, 1, 1)
	settings.outline_size = maxi(4, int(size / 5.0))
	settings.outline_color = Color(0.02, 0.03, 0.10, 0.9)
	label.label_settings = settings
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func setup(firefly_total: int, start_x: float, goal_x: float) -> void:
	_total = firefly_total
	_start_x = start_x
	_goal_x = goal_x
	set_fireflies(0)
	update_progress(start_x)


func set_fireflies(count: int) -> void:
	_fire_label.text = "Fireflies  %d / %d" % [count, _total]


func update_progress(player_x: float) -> void:
	var p := clampf((player_x - _start_x) / (_goal_x - _start_x), 0.0, 1.0)
	_bar_fill.size.x = maxf((BAR_W - 2.0) * p, 0.0)
	_kid_icon.position.x = BAR_W * p - 12.0


func toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.4)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func play_intro() -> void:
	_fade.color.a = 1.0
	_title.modulate.a = 0.0
	await _show_line("The streetlights are coming on...", 0.6, 0.7)
	if not _skip:
		await _show_line("It's already late.\nTime to go home.", 0.5, 1.0)
	_title.modulate.a = 0.0
	var up := create_tween()
	up.tween_property(_fade, "color:a", 0.0, 0.9)
	show_controls()


func skip_intro() -> void:
	_skip = true


func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds and not _skip:
		await get_tree().process_frame
		elapsed += get_process_delta_time()


func _show_line(text: String, fade_in: float, hold: float) -> void:
	if _skip:
		return
	_title.text = text
	var tw := create_tween()
	tw.tween_property(_title, "modulate:a", 1.0, fade_in)
	await _wait(fade_in + hold)
	var tw2 := create_tween()
	tw2.tween_property(_title, "modulate:a", 0.0, 0.3)
	await _wait(0.35)


func show_controls() -> void:
	_controls.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_controls, "modulate:a", 1.0, 0.5)
	tw.tween_interval(6.0)
	tw.tween_property(_controls, "modulate:a", 0.0, 1.0)


func fade_to_black(time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, time)
	await tw.finished


func fade_from_black(time: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 0.0, time)
	await tw.finished


func show_end(fireflies: int, total: int, seconds: float, falls: int) -> void:
	var minutes := int(seconds / 60.0)
	var secs := int(seconds) % 60
	_end_stats.text = "Fireflies  %d / %d      Time  %d:%02d      Tumbles  %d" % [fireflies, total, minutes, secs, falls]
	_end_panel.modulate.a = 0.0
	_end_panel.visible = true
	var tw := create_tween()
	tw.tween_property(_end_panel, "modulate:a", 1.0, 0.8)
