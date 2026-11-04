class_name EnemyType
extends Resource
## Data of one enemy: WHAT it is (numbers and image).
## There is only ONE enemy scene (enemy.tscn); it reads all its stats from this resource.
## The three archetypes and the final boss are files of this same type (data/enemies/*.tres).

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
## Width of the image on the board, in pixels (a cell is 120 px). The boss is bigger.
@export var sprite_size: float = 110.0
## Only the boss: Game shows its health bar at the bottom of the screen.
@export var is_boss: bool = false
## Text of its file in the Expediente and in "Nuevo en tu expediente" (Block 9).
@export_multiline var description: String = ""
## Animated cut-out puppet (Block 10). Empty = the fixed texture of the 1.0.
@export var visual_scene: PackedScene

@export_group("Abilities")
## Extra health that is spent before the normal health (a pile of books).
## 0 = no armor. Used from Block 12.
@export var armor_health: float = 0.0
## Enemy it splits into when it dies. Empty = it does not split. Used from Block 12.
@export var split_into: EnemyType
## How many enemies of split_into appear when it dies.
@export var split_count: int = 0
## true = the first time it reaches a defender, it jumps one column over it. Used from Block 12.
@export var jumps_first_defender: bool = false
## Only bosses: speed multiplier from 50 % of health on (phase 2). 1.0 = no phase 2.
@export var phase2_speed_multiplier: float = 1.0

@export_group("Summon")
## Enemy it calls every summon_interval seconds: one in the lane above and one
## in the lane below, at its own column. Empty = it never summons (normal enemies).
@export var summon_type: EnemyType
## Seconds between two summons.
@export var summon_interval: float = 10.0
