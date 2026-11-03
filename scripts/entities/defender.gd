class_name Defender
extends Node2D
## Base script for every defender: its data, its cell, health, damage and death.
## GeneratorDefender, ShooterDefender and BlockerDefender inherit from it.
## The node is placed at the center of its cell; Game does that conversion with Board.

## Emitted when health reaches 0, so Game can free the cell on the Board.
signal died(defender: Defender)

## Size of the placeholder circle, in pixels (a cell is 120 px).
const CIRCLE_RADIUS := 46.0
## Width of the final image on the board, in pixels (a cell is 120 px).
const SPRITE_SIZE := 110.0

var defender_type: DefenderType
var lane := 0
var column := 0
var health := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var letter_label: Label = $Letter


## Game calls this right after instantiate() and BEFORE add_child(),
## so the data is ready when _ready() runs.
func setup(type: DefenderType, cell_lane: int, cell_column: int) -> void:
	defender_type = type
	lane = cell_lane
	column = cell_column
	health = type.health


func _ready() -> void:
	if defender_type.texture:
		# Final art (Block 6): show the image and hide the letter.
		sprite.texture = defender_type.texture
		# The PNG is bigger (256 px) so it looks sharp on phones; scale it to fit the cell.
		sprite.scale = Vector2.ONE * SPRITE_SIZE / defender_type.texture.get_width()
		letter_label.hide()
	else:
		# Placeholder: the first letter of the name (C, L, F) over a colored circle.
		letter_label.text = defender_type.display_name.left(1)


func _draw() -> void:
	if defender_type.texture == null:
		draw_circle(Vector2.ZERO, CIRCLE_RADIUS, defender_type.color)


## Enemies call this every frame while they bite the defender.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return  # already dead, ignore extra hits in the same frame
	health -= amount
	if health <= 0.0:
		died.emit(self)
		queue_free()
