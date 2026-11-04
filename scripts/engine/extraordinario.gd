class_name Extraordinario
extends Node2D
## The "Extraordinario" of one lane: it waits at the left edge of the board.
## The first time an enemy of its lane reaches the safe zone, Game calls
## trigger(): it runs along the whole lane (column -0.5 to 9.5) with a Tween,
## removes every enemy it touches, and disappears. It saves the lane only once:
## when it is gone, the next enemy that arrives causes the defeat.
## Like the rest of the game, it works in cells; pixels are only for drawing.

## READY = waiting, SWEEPING = running along the lane, USED = gone.
enum State { READY, SWEEPING, USED }

## Column where it waits: the left edge of the board (the start of the safe zone).
const REST_COLUMN := -0.5
## Column where the run ends: the right edge of the board.
const END_COLUMN := 9.5
## Seconds the run takes from one end of the lane to the other.
const SWEEP_TIME := 1.2
## An enemy this close (in columns) in front of it, or anywhere behind it, is removed.
const TOUCH_DISTANCE := 0.5
## Width of the image on the board, in pixels (a cell is 120 px).
const SPRITE_SIZE := 64.0
## Damage that removes any enemy, the boss included.
const SWEEP_DAMAGE := 1000000.0

var lane := 0
## Position along the lane, in cells. The Tween moves it during the run.
var column := REST_COLUMN
var state := State.READY
var board: Board
var sweep_tween: Tween

@onready var sprite: Sprite2D = $Sprite


## Game calls this right after instantiate() and BEFORE add_child().
func setup(extraordinario_lane: int, game_board: Board) -> void:
	lane = extraordinario_lane
	board = game_board


func _ready() -> void:
	sprite.scale = Vector2.ONE * SPRITE_SIZE / sprite.texture.get_width()
	set_process(false)  # it only works during the run
	_update_position()


## True while it can still save its lane (waiting, or already running:
## an enemy that arrives during the run is removed by the same run).
func can_save() -> bool:
	return state != State.USED


## Starts the run. Game calls it when an enemy of this lane reaches the safe zone.
func trigger() -> void:
	if state != State.READY:
		return
	state = State.SWEEPING
	set_process(true)
	# The Tween belongs to this node, so it freezes with the pause like the enemies.
	sweep_tween = create_tween()
	sweep_tween.tween_property(self, "column", END_COLUMN, SWEEP_TIME)
	sweep_tween.finished.connect(_on_sweep_finished)


func _process(_delta: float) -> void:
	_update_position()
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.lane == lane and enemy.health > 0.0 and enemy.column <= column + TOUCH_DISTANCE:
			enemy.take_damage(SWEEP_DAMAGE)


func _on_sweep_finished() -> void:
	state = State.USED
	set_process(false)
	hide()  # it disappears; Game keeps the node to ask can_save()


## Cells -> pixels, only to draw the node on screen.
func _update_position() -> void:
	global_position = board.cell_to_pixel(lane, column)
