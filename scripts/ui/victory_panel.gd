class_name VictoryPanel
extends Control
## Victory panel, shown when every wave of the level has been defeated.
## Like the defeat panel, its process mode is "When Paused": the game freezes
## behind it and only these buttons respond. It tells Game what the player chose.

signal next_requested
signal home_requested

@onready var title_label: Label = %Title
@onready var message_label: Label = %Message
@onready var next_button: Button = %NextButton
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)


## A level was won and the world has more levels.
func show_level_cleared(level_number: int, level_name: String) -> void:
	title_label.text = "¡Nivel superado!"
	message_label.text = "Nivel %d · %s" % [level_number, level_name]
	next_button.show()
	show()


## The last level of the world was won: there is no next level.
func show_world_cleared(world_name: String) -> void:
	title_label.text = "¡%s superado!" % world_name
	message_label.text = "Sobreviviste a todos los niveles"
	next_button.hide()
	show()


func _on_next_button_pressed() -> void:
	next_requested.emit()


func _on_home_button_pressed() -> void:
	home_requested.emit()
