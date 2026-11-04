class_name DialogueLine
extends Resource
## One line of a conversation: who speaks, with which face and what they say.
## The dialogue box (Block 9) shows the lines of a DialogueData one by one.

## Name shown above the text ("El Director").
@export var speaker: String = "El Director"
## Face of the portrait: art/director/<expression>.png.
@export_enum("normal", "feliz", "serio", "sorprendido", "preocupado", "orgulloso") var expression: String = "normal"
## What the character says.
@export_multiline var text: String = ""
## Optional: card presented in the middle of the screen under "¡Nueva carta!".
@export var show_card: DefenderType
## Optional: enemy presented under "Nuevo en tu expediente".
@export var show_enemy: EnemyType
