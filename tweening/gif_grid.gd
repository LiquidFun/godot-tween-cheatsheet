extends Control

enum Property { ROTATION, POSITION, SCALE, MODULATION }

@export var tween_property: Property = Property.ROTATION
@export var record: bool = true
@export var ui_scale: float = 1.0
@export var output_format: String = "webp"

signal recording_done
var auto_quit := true

const TRANSITIONS = [
	"BOUNCE", "BACK", "SPRING", "ELASTIC",
	"LINEAR", "SINE", "QUAD", "CIRC",
	"CUBIC", "QUART", "QUINT", "EXPO",
]

const EASINGS = ["IN", "OUT", "IN_OUT", "OUT_IN"]

const EASING_TO_COLOR = {
	Tween.EASE_IN: Color(0.35, 0.85, 0.55, 1),
	Tween.EASE_OUT: Color(0.85, 0.45, 0.35, 1),
	Tween.EASE_IN_OUT: Color(0.35, 0.25, 0.95, 1),
	Tween.EASE_OUT_IN: Color(0.95, 0.45, 0.85, 1),
}

const TITLE_COLOR = Color("46a1e0")
const GHOST_SCENE = preload("res://tweening/ghost.tscn")
const GHOST_FILL = 0.55

const TWEEN_DURATION = 1.0
const HOLD_DURATION = 0.15
const RECORD_FPS = 60

var cell_size: Vector2
var cell_gap: Vector2
var grid_offset: Vector2

var font = ThemeDB.fallback_font
var _recording := false
var _elapsed := 0.0
var _loop_duration: float
var _output_dir: String
var _crop_size: Vector2
var _all_tweens: Array[Tween] = []
var _frames: Array[Image] = []

@onready var _ref_tween := create_tween()

func _cell_origin(col: int, row: int) -> Vector2:
	return Vector2(col, row) * (cell_size + cell_gap) + grid_offset

func _ready():
	cell_size = Vector2(60, 60) * ui_scale
	cell_gap = Vector2(12, 6) * ui_scale
	grid_offset = Vector2(90, 55) * ui_scale

	var prop_name: String = Property.keys()[tween_property].to_lower()
	_output_dir = "res://output/%s" % prop_name
	_loop_duration = (TWEEN_DURATION + HOLD_DURATION) * 2
	_crop_size = _cell_origin(3, 11) + cell_size + Vector2(10, 15) * ui_scale

	_setup_ghosts()

	for tw in _all_tweens:
		tw.pause()

	if record:
		DirAccess.make_dir_recursive_absolute(_output_dir)
		Engine.max_fps = RECORD_FPS
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw

	for tw in _all_tweens:
		tw.play()

	if record:
		_recording = true

func _setup_ghosts():
	for row in TRANSITIONS.size():
		var trans: int = _ref_tween.get("TRANS_" + TRANSITIONS[row])
		for col in EASINGS.size():
			var ease_val: int = _ref_tween.get("EASE_" + EASINGS[col])
			var center := _cell_origin(col, row) + cell_size / 2

			var ghost: Sprite2D = GHOST_SCENE.instantiate()
			add_child(ghost)
			ghost.position = center

			var tex_size := ghost.texture.get_size()
			var fit := cell_size * GHOST_FILL
			var s: float = min(fit.x / tex_size.x, fit.y / tex_size.y)
			ghost.scale = Vector2(s, s)
			ghost.set_meta("target_scale", ghost.scale)

			ghost.modulate = EASING_TO_COLOR[ease_val]

			_create_tween(ghost, trans, ease_val)

func _create_tween(ghost: Node2D, trans: int, ease_val: int):
	var tw := create_tween().set_ease(ease_val).set_trans(trans)
	if not record:
		tw.set_loops()
	_all_tweens.append(tw)

	match tween_property:
		Property.ROTATION:
			tw.tween_property(ghost, "rotation", PI / 2, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)
			tw.tween_property(ghost, "rotation", TAU, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)

		Property.POSITION:
			var travel := cell_size.x * 0.25
			var start_pos := ghost.position - Vector2(travel, 0)
			var end_pos := ghost.position + Vector2(travel, 0)
			ghost.position = start_pos
			tw.tween_property(ghost, "position", end_pos, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)
			tw.tween_property(ghost, "position", start_pos, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)

		Property.SCALE:
			var target_scale: Vector2 = ghost.get_meta("target_scale")
			ghost.scale = Vector2.ZERO
			tw.tween_property(ghost, "scale", target_scale, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)
			tw.tween_property(ghost, "scale", Vector2.ZERO, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)

		Property.MODULATION:
			ghost.modulate.a = 0.0
			tw.tween_property(ghost, "modulate:a", 1.0, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)
			tw.tween_property(ghost, "modulate:a", 0.0, TWEEN_DURATION)
			tw.tween_interval(HOLD_DURATION)

func _draw():
	var prop_name: String = Property.keys()[tween_property].capitalize()
	draw_string(font, Vector2(20, 32) * ui_scale, "Tween Cheatsheet: %s" % prop_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20 * ui_scale, TITLE_COLOR)

	for col in EASINGS.size():
		var ease_name: String = "EASE_" + EASINGS[col]
		var ease_val: int = _ref_tween.get("EASE_" + EASINGS[col])
		var x_pos := _cell_origin(col, 0).x
		var y_pos := _cell_origin(col, 0).y - 8 * ui_scale
		draw_string(font, Vector2(x_pos, y_pos), ease_name, HORIZONTAL_ALIGNMENT_CENTER, cell_size.x, 10 * ui_scale, EASING_TO_COLOR[ease_val])

	var label_width := grid_offset.x - 8 * ui_scale
	for row in TRANSITIONS.size():
		var y_pos := _cell_origin(0, row).y + cell_size.y / 2 + 4 * ui_scale
		draw_string(font, Vector2(0, y_pos), TRANSITIONS[row], HORIZONTAL_ALIGNMENT_RIGHT, label_width, 12 * ui_scale, Color.WHITE)

	var credits_at := _cell_origin(1, 11) + cell_size + Vector2(15, 15) * ui_scale
	draw_string(font, credits_at, "github.com/LiquidFun", HORIZONTAL_ALIGNMENT_LEFT, -1, 9 * ui_scale, Color.BLACK.lightened(.2))

func _process(delta):
	if not _recording:
		return

	var image := get_viewport().get_texture().get_image()
	image.crop(int(_crop_size.x), int(_crop_size.y))
	_frames.append(image)

	_elapsed += delta
	if _elapsed >= _loop_duration:
		_recording = false
		Engine.max_fps = 0
		_save_and_convert()

func _save_and_convert():
	var prop_name: String = Property.keys()[tween_property].to_lower()
	_clear_frames_dir()
	print("Saving %d frames..." % _frames.size())
	for i in _frames.size():
		_frames[i].save_png("%s/frame_%04d.png" % [_output_dir, i])
	_frames.clear()

	var input_pattern: String = ProjectSettings.globalize_path("%s/frame_%%04d.png" % _output_dir)
	var scale_suffix := "" if ui_scale == 1.0 else "_%dx" % int(ui_scale)
	var output_path: String = ProjectSettings.globalize_path("res://output/%s%s.%s" % [prop_name, scale_suffix, output_format])
	var args: Array

	match output_format:
		"webp":
			args = [
				"-y", "-framerate", str(RECORD_FPS),
				"-i", input_pattern,
				"-vcodec", "libwebp", "-lossless", "1",
				"-loop", "0",
				output_path,
			]
		"webm":
			args = [
				"-y", "-framerate", str(RECORD_FPS),
				"-i", input_pattern,
				"-c:v", "libvpx-vp9", "-crf", "10", "-b:v", "0",
				"-pix_fmt", "yuv420p",
				output_path,
			]

	print("Running: ffmpeg ", " ".join(args))
	var pid := OS.create_process("ffmpeg", args)
	if pid != -1:
		print("ffmpeg started (pid %d) → %s" % [pid, output_path])
	else:
		print("ffmpeg failed to start")

	recording_done.emit()
	if auto_quit:
		get_tree().quit()

func _clear_frames_dir():
	var dir := DirAccess.open(_output_dir)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png"):
			dir.remove(file_name)
		file_name = dir.get_next()
