class_name DefeatPanel
extends Control
## Defeat panel, shown when an enemy reaches the safe zone.
## Like the pause menu, its process mode is "When Paused": the game freezes
## behind it and only these buttons respond. It tells Game what the player chose.

signal retry_requested
signal home_requested

@onready var retry_button: Button = %RetryButton
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)


func _on_retry_button_pressed() -> void:
	retry_requested.emit()


func _on_home_button_pressed() -> void:
	home_requested.emit()
