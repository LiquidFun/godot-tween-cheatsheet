extends Control

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

const SCALE = 2.0
const CELL_SIZE = Vector2(50, 50) * SCALE
const OFFSET = Vector2(100, 60) * SCALE
const INITIAL_OFFSET = Vector2(200, 100) * SCALE

const SAMPLING_POINTS = 500

const TITLE_COLOR = Color("46a1e0")

const ICON_SCENE = preload("res://tweening/icon.tscn")

@onready var some_tween = create_tween()

var font = ThemeDB.fallback_font
	
func get_top_left(x, y):
	return Vector2(x, y) * (CELL_SIZE + OFFSET) + INITIAL_OFFSET
	
func _draw_legend(at):
	for i in EASINGS.size():
		var easing_name = "EASE_" + EASINGS[i]
		var easing = some_tween.get(easing_name) 
		var color = EASING_TO_COLOR[easing]
		draw_text(at + Vector2(26, 17) * SCALE, easing_name, 20, color)
		at += Vector2(36 + 14 * len(easing_name), 0) * SCALE
		
func draw_text(pos, text, size=16, color=Color.WHITE, alignment=HORIZONTAL_ALIGNMENT_LEFT):
	draw_string(font, pos, text, alignment, -1, size * SCALE, color)
	
func _draw():
		
	#draw_text(Vector2(30, 60) * SCALE, "Godot Tweening Cheatsheet", 32, TITLE_COLOR)
	#draw_text(Vector2(32, 78) * SCALE, "drawn using Godot v4.3.stable", 14, TITLE_COLOR.darkened(.5))
	
	_draw_legend(get_top_left(0, 0) - OFFSET + Vector2(50, -20))
	for y in TRANSITIONS.size():
		var transition_suffix = TRANSITIONS[y]
		draw_text(get_top_left(0, y) - Vector2(150, 0) * SCALE, transition_suffix, 18, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
					
	var credits_at = get_top_left(1, 2) + CELL_SIZE + Vector2(30, 25) * SCALE
	var credits = "github.com/LiquidFun"
	draw_text(credits_at, credits, 12, Color.BLACK.lightened(.2))
		
func _ready():

	
	for y in TRANSITIONS.size():
		var transition_suffix = TRANSITIONS[y]
		var transition = some_tween.get("TRANS_" + transition_suffix)
		for x in EASINGS.size():
			var easing_suffix = EASINGS[x]
			var easing = some_tween.get("EASE_" + easing_suffix)
			var top_left = get_top_left(x, y)
			
			var icon = ICON_SCENE.instantiate()
			add_child(icon)
			icon.position = get_top_left(x, y)
			icon.scale = Vector2.ZERO
			var tween = create_tween().set_ease(easing).set_trans(transition)
			tween.set_loops().tween_property(icon, "scale", Vector2(0.7, 0.7) * SCALE, 1)
			tween.set_loops().tween_property(icon, "scale", Vector2(0.7, 0.7) * SCALE, 0.1)
			# tween.tween_property(icon, "scale", Vector2.ONE * SCALE, 1)
			tween.tween_property(icon, "scale", Vector2.ZERO, 1)
		
