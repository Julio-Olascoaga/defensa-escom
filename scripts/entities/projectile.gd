class_name Projectile
extends Node2D
## Piece of code shot by a Laptop. It flies right along its lane.
## Hit detection is a simple calculation per lane (no physics):
## it hits the nearest enemy of its lane that is inside the stretch it flew this frame
## (plus HIT_DISTANCE columns on each side), so a slow frame cannot skip an enemy.

## Flying speed, in cells per second.
const SPEED := 5.0
## Extra margin, in columns, on each side of the stretch flown in one frame.
const HIT_DISTANCE := 0.3
## Past this column the projectile has left the screen.
const MAX_COLUMN := 9.5
## Small blue sparks where it hits.
const HIT_SPARK_COLOR := Color("7fe3ff")
const HIT_SPARKS := 6
## Block 10: a short trail behind it (CPUParticles2D "Trail" in projectile.tscn,
## FxLimits.TRAIL particles) and little "code bits" where it hits.
const HIT_BITS_COLOR := Color("9cff8f")
const CHIP_TEXTURE := preload("res://art/fx/chip.png")

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
	var previous_column := column
	column += SPEED * delta
	var target := _nearest_enemy_between(previous_column - HIT_DISTANCE, column + HIT_DISTANCE)
	if target:
		target.take_damage(damage)
		AudioManager.play_sfx_varied(AudioManager.SFX_HIT)
		SparkBurst.spawn(self, global_position, HIT_SPARK_COLOR, HIT_SPARKS, 160.0)
		var bits := SparkBurst.spawn(self, global_position, HIT_BITS_COLOR, FxLimits.HIT_BITS, 120.0, CHIP_TEXTURE)
		if bits:
			bits.scale_amount_min = 0.25
			bits.scale_amount_max = 0.4
		queue_free()
		return
	if column > MAX_COLUMN:
		queue_free()
		return
	_update_position()


## The live enemy of this lane with the lowest column inside [from_column, to_column], or null.
func _nearest_enemy_between(from_column: float, to_column: float) -> Enemy:
	var nearest: Enemy = null
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.lane != lane or enemy.health <= 0.0:
			continue  # other lane, or already dying this frame
		if enemy.column >= from_column and enemy.column <= to_column:
			if nearest == null or enemy.column < nearest.column:
				nearest = enemy
	return nearest


func _update_position() -> void:
	global_position = board.cell_to_pixel(lane, column)
