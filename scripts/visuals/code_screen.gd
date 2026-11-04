class_name CodeScreen
extends Node2D
## Lines of code that scroll up on the Laptop's screen (Block 10, idle).
## Child of the Laptop's lid, so it tilts with it. Drawn with rectangles
## (no font, no image): each line is a few "words" of random width and colour.

## Area of the screen in local pixels (the source art of the Laptop).
@export var area := Rect2(-60, -100, 120, 84)
## Pixels per second the code scrolls up.
@export var scroll_speed := 18.0
@export var line_height := 9.0
@export var line_alpha := 0.35

const COLORS: Array[Color] = [Color("7fe3ff"), Color("9cff8f"), Color("ffd45c"), Color("ff8fd2")]

var _scroll := 0.0
## One entry per line: [indent, [word widths...], color index]
var _lines: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1004  # the same code on every Laptop: it only has to look busy
	for i in int(area.size.y / line_height) + 2:
		var words: Array[float] = []
		for w in rng.randi_range(1, 4):
			words.append(rng.randf_range(8.0, 26.0))
		_lines.append([rng.randi_range(0, 2) * 8.0, words, rng.randi_range(0, COLORS.size() - 1)])


func _process(delta: float) -> void:
	_scroll = fmod(_scroll + scroll_speed * delta, line_height * _lines.size())
	queue_redraw()


func _draw() -> void:
	var total := line_height * _lines.size()
	for i in _lines.size():
		var y := fposmod(i * line_height - _scroll, total)
		if y > area.size.y - 4.0:
			continue  # below the screen: it comes back from the top
		var line: Array = _lines[i]
		var x: float = line[0]
		var color: Color = COLORS[line[2]]
		color.a = line_alpha
		for width: float in line[1]:
			if x + width > area.size.x:
				break
			draw_rect(Rect2(area.position + Vector2(x, y), Vector2(width, 4.0)), color)
			x += width + 5.0
