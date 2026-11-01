class_name Projectile
extends Node2D
## Piece of code shot by a Laptop. It flies right along its lane.
## Hit detection is a simple calculation per lane (no physics):
## it hits an enemy that is in the same lane and less than HIT_DISTANCE columns away.

## Flying speed, in cells per second.
const SPEED := 5.0
## Max distance in columns between the projectile and an enemy to count as a hit.
const HIT_DISTANCE := 0.3
## Past this column the projectile has left the screen.
const MAX_COLUMN := 9.5
const RADIUS := 10.0
const COLOR := Color("39e58c")

var lane := 0
var column := 0.0
var damage := 20.0
## Game assigns it before add_child(); used only to draw the node.
var board: Board


## The Laptop calls this right after instantiate().
func setup(shot_lane: int, start_column: float, shot_damage: float) -> void:
	lane = shot_lane
	column = start_column
	damage = shot_damage


func _ready() -> void:
	_update_position()


func _process(delta: float) -> void:
	column += SPEED * delta
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.lane == lane and absf(enemy.column - column) < HIT_DISTANCE:
			enemy.take_damage(damage)
			queue_free()
			return
	if column > MAX_COLUMN:
		queue_free()
		return
	_update_position()


func _update_position() -> void:
	global_position = board.cell_to_pixel(lane, column)


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, COLOR)
