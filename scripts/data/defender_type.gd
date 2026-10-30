class_name DefenderType
extends Resource
## Data of one defender: WHAT it is (numbers and image).
## HOW it behaves lives in behavior_scene (generator, shooter or blocker).
## Café, Laptop and Firewall are three files of this same type (data/defenders/*.tres),
## created and edited from the Inspector without touching any script.

## Name shown on the card. Its first letter is drawn on the board until the art exists.
@export var display_name: String = ""
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

@export_group("Generator")
## Energy inside each orb. Only generator defenders use it.
@export var energy_per_orb: int = 25
## Seconds between two orbs. Only generator defenders use it.
@export var orb_interval: float = 10.0
