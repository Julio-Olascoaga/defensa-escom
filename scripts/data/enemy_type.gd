class_name EnemyType
extends Resource
## Data of one enemy: WHAT it is (numbers and image).
## There is only ONE enemy scene (enemy.tscn); it reads all its stats from this resource.
## The three archetypes are three files of this same type (data/enemies/*.tres).

## Name of the archetype (for the docs and the Inspector).
@export var display_name: String = ""
## Short text drawn on the board until the art exists ("T∞", "!", "200").
@export var label_text: String = "?"
## Health points. Laptop projectiles take it away.
@export var health: float = 200.0
## Walking speed in cells per second (NOT pixels).
@export var speed: float = 0.25
## Damage per second to the defender it is biting.
@export var damage_per_second: float = 25.0
## Final image (Block 6). While it is empty, the board shows label_text.
@export var texture: Texture2D
## Color of the placeholder box behind the text.
@export var color: Color = Color("f3d9e4")
