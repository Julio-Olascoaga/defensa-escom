class_name Enemy
extends Node2D
## The ONE scene for every enemy. Its stats come from the EnemyType it receives.
## It walks left along its lane in cells per second, stops at the first defender
## in front of it and bites it (damage per second) until the defender dies.
## All the logic uses cells; pixels are only used to draw the node.

## Emitted when health reaches 0.
signal died(enemy: Enemy)
## Emitted when the enemy enters the safe zone: the player loses.
signal reached_safe_zone(enemy: Enemy)

## Column where enemies appear: just right of the board, in the entry area.
const SPAWN_COLUMN := 9.0
## The safe zone starts at the left edge of column 0 (cell centers are whole numbers).
const SAFE_ZONE_COLUMN := -0.5
## How close (in columns) to a defender's center the enemy stops to bite it.
const BITE_DISTANCE := 0.7
## Size of the placeholder box, in pixels (a cell is 120 px).
const BOX_SIZE := Vector2(92, 92)
const BORDER_COLOR := Color("7a1f45")

var enemy_type: EnemyType
var lane := 0
## Position along the lane, in cells. It has decimals: 6.4 = between cells 6 and 7.
var column := SPAWN_COLUMN
var health := 0.0
## The Board, used to find defenders and to convert cells to pixels.
var board: Board

@onready var sprite: Sprite2D = $Sprite
@onready var text_label: Label = $Text


## Game calls this right after instantiate() and BEFORE add_child().
func setup(type: EnemyType, enemy_lane: int, game_board: Board) -> void:
	enemy_type = type
	lane = enemy_lane
	board = game_board
	health = type.health


func _ready() -> void:
	# The group lets Laptops and projectiles find every enemy alive.
	add_to_group("enemies")
	if enemy_type.texture:
		sprite.texture = enemy_type.texture
		text_label.hide()
	else:
		text_label.text = enemy_type.label_text
	_update_position()


func _process(delta: float) -> void:
	var defender := _defender_in_front()
	if defender:
		defender.take_damage(enemy_type.damage_per_second * delta)  # bite
	else:
		column -= enemy_type.speed * delta  # walk left (cells per second)

	if column <= SAFE_ZONE_COLUMN:
		reached_safe_zone.emit(self)
		set_process(false)  # stop here; Game shows the defeat panel
	_update_position()


## Returns the defender this enemy is touching, or null.
## ceili() gives the nearest cell whose center is at most BITE_DISTANCE ahead of us.
func _defender_in_front() -> Defender:
	var front_column := ceili(column - BITE_DISTANCE)
	return board.get_defender(lane, front_column)


## Laptop projectiles call this.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return  # already dead, ignore extra hits in the same frame
	health -= amount
	if health <= 0.0:
		died.emit(self)
		queue_free()


## Cells -> pixels, only to draw the node on screen.
func _update_position() -> void:
	global_position = board.cell_to_pixel(lane, column)


func _draw() -> void:
	if enemy_type.texture == null:
		var box := Rect2(-BOX_SIZE / 2.0, BOX_SIZE)
		draw_rect(box, enemy_type.color)
		draw_rect(box, BORDER_COLOR, false, 4.0)
