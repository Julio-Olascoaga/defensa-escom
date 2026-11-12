class_name DefenderType
extends Resource
## Data of one defender: WHAT it is (numbers and image).
## HOW it behaves lives in behavior_scene (generator, shooter or blocker).
## Café, Laptop and Firewall are three files of this same type (data/defenders/*.tres),
## created and edited from the Inspector without touching any script.

## Name shown on the card. Its first letter is drawn on the board until the art exists.
@export var display_name: String = ""
## Short name for the card of the top bar (Block 12), for long names such as
## "Calculadora científica". Empty = display_name.
@export var card_name: String = ""
## Energy the player pays to place it.
@export var cost: int = 50
## Health points. Enemies take it away in Block 3.
@export var health: float = 300.0
## Seconds the card stays locked after placing this defender.
@export var cooldown: float = 7.5
## Final image (Block 6). While it is empty, the board shows the first letter.
@export var texture: Texture2D
## Color of the placeholder circle behind the letter.
@export var color: Color = Color.WHITE
## Scene with the behavior script (generator, shooter or blocker).
@export var behavior_scene: PackedScene
## Text of its card in the Expediente and in "¡Nueva carta!" (Block 9).
@export_multiline var description: String = ""
## Small image for the card bar and the Expediente. Empty = texture.
@export var icon: Texture2D
## Animated cut-out puppet (Block 10). Empty = the fixed texture of the 1.0.
@export var visual_scene: PackedScene

@export_group("Generator")
## Energy inside each orb. Only generator defenders use it.
@export var energy_per_orb: int = 25
## Seconds between two orbs. Only generator defenders use it.
@export var orb_interval: float = 10.0

@export_group("Shooter")
## Seconds between two shots. Only shooter defenders use it.
@export var fire_interval: float = 1.5
## Damage of each projectile. Only shooter defenders use it.
@export var projectile_damage: float = 20.0
## Speed multiplier the projectile leaves on the enemy (0.5 = half speed, "lag").
## 1.0 = it does not slow down (Laptop). Used from Block 12 (Router lento).
@export var slow_factor: float = 1.0
## Seconds the slow-down lasts. Used from Block 12.
@export var slow_time: float = 0.0

@export_group("Instant")
## Radius in cells of the area it hits (1 = a 3 x 3 square). Used from Block 12 (Ctrl+Z).
@export var area_radius: float = 1.0
## Damage it does to every enemy inside the area (the armor takes it first).
## Only instant defenders use it (InstantDefender, Block 12).
@export var area_damage: float = 1800.0
## Seconds between being placed and going off.
@export var trigger_delay: float = 0.5
