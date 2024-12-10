extends Control

const TRANSITIONS = [
	["BACK", "SPRING", "BOUNCE", "ELASTIC"],
	["LINEAR", "SINE", "QUAD", "CIRC"], 
	["CUBIC", "QUART", "QUINT", "EXPO"],
]

const EASINGS = ["IN", "OUT", "IN_OUT", "OUT_IN"]

const EASING_TO_COLOR = {
	Tween.EASE_IN: Color(0.35, 0.85, 0.55, 0.85),
	Tween.EASE_OUT: Color(0.85, 0.45, 0.35, 0.85),
	Tween.EASE_IN_OUT: Color(0.35, 0.25, 0.95, 0.85),
	Tween.EASE_OUT_IN: Color(0.95, 0.45, 0.85, 0.85),
}

const CELL_SIZE = Vector2(200, 200)
const OFFSET = Vector2(30, 70)
const INITIAL_OFFSET = Vector2(30, 130)
const EXTRA_OFFSET = [Vector2(0, 0), Vector2(0, 35), Vector2(0, 0)]

const SAMPLING_POINTS = 100

const TITLE_COLOR = Color("46a1e0")

@onready var tween = create_tween()

var font = ThemeDB.fallback_font

func _ready() -> void:
	await RenderingServer.frame_post_draw
	var screenshot = get_viewport().get_texture().get_image()
	var size = get_top_left(3, 2) + CELL_SIZE + OFFSET
	screenshot.crop(size.x, size.y)
	screenshot.save_png("res://cheatsheet.png")
	
func get_top_left(x, y):
	return Vector2(x, y) * (CELL_SIZE + OFFSET) + EXTRA_OFFSET[y] + INITIAL_OFFSET
	
func _draw_legend(at):
	for i in EASINGS.size():
		var easing_name = "EASE_" + EASINGS[i]
		var easing = tween.get(easing_name) 
		var color = EASING_TO_COLOR[easing]
		draw_rect(Rect2(at, Vector2.ONE * 20), color)
		draw_string(font, at + Vector2(26, 17), easing_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, color)
		at += Vector2(36 + 14 * len(easing_name), 0)

func _draw():
	
	draw_string(font, Vector2(30, 60), "Godot Tweening Cheatsheet", HORIZONTAL_ALIGNMENT_LEFT, -1, 32, TITLE_COLOR)
	draw_string(font, Vector2(32, 78), "drawn using Godot v4.3.stable", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, TITLE_COLOR.darkened(.5))
	
	_draw_legend(get_top_left(0, 1) + Vector2(0, 10  - OFFSET.y))
	
	for y in TRANSITIONS.size():
		for x in TRANSITIONS[y].size():
			var transition_suffix = TRANSITIONS[y][x]
			var transition = tween.get("TRANS_" + transition_suffix)
			for easing_suffix in EASINGS:
				var easing = tween.get("EASE_" + easing_suffix)
				var top_left = get_top_left(x, y)
				draw_rect(Rect2(top_left, CELL_SIZE), Color(0, 0, 0, 0), false, 1)
				
				var points = []
				for x1 in SAMPLING_POINTS:
					var t1 = x1 / (SAMPLING_POINTS - 1.0)
					var y1 = Tween.interpolate_value(1.0, -1.0, t1, 1, transition, easing)
					
					var p1 = top_left + Vector2(t1 , y1) * CELL_SIZE
					points.append(p1)
				
				for p in len(points)-1:
					draw_line(points[p], points[p+1], EASING_TO_COLOR[easing], 1, true)
			
				draw_string(ThemeDB.fallback_font, top_left + Vector2(4, 14), transition_suffix)
			
	var credits_at = get_top_left(1, 2) + CELL_SIZE + Vector2(30, 25)
	var credits = "initial version by u/wandomPewlin, updated by github.com/LiquidFun"
	draw_string(font, credits_at, credits, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.BLACK.lightened(.2))
