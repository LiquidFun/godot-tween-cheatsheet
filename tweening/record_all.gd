extends Node

const GRID_SCENE = preload("res://tweening/gif_grid_rotation.tscn")

var _jobs := []
var _current := 0

func _ready():
	for prop_i in 4:
		_jobs.append({property = prop_i, format = "webp", scale = 1.0})
	for prop_i in 4:
		_jobs.append({property = prop_i, format = "webp", scale = 2.0})
	_run_next()

func _run_next():
	if _current >= _jobs.size():
		print("All %d recordings complete!" % _jobs.size())
		get_tree().quit()
		return

	var job = _jobs[_current]
	var prop_names := ["rotation", "position", "scale", "modulation"]
	print("\n=== Job %d/%d: %s.%s (%.0fx) ===" % [
		_current + 1, _jobs.size(), prop_names[job.property], job.format, job.scale
	])

	var grid = GRID_SCENE.instantiate()
	grid.tween_property = job.property
	grid.record = true
	grid.ui_scale = job.scale
	grid.output_format = job.format
	grid.auto_quit = false
	grid.recording_done.connect(_on_done.bind(grid), CONNECT_ONE_SHOT)
	add_child(grid)

func _on_done(grid: Control):
	grid.queue_free()
	_current += 1
	await get_tree().process_frame
	await get_tree().process_frame
	_run_next()
