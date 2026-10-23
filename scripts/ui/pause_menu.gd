class_name PauseMenu
extends Control
## Pause menu. Its process mode is "When Paused", so it only works
## while the game is paused. It does not pause anything by itself:
## it tells the Game node what the player chose, through signals.

signal resume_requested
signal restart_requested
signal exit_requested

@onready var resume_button: Button = %ResumeButton
@onready var restart_button: Button = %RestartButton
@onready var exit_button: Button = %ExitButton


func _ready() -> void:
	resume_button.pressed.connect(_on_resume_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)


func _on_resume_button_pressed() -> void:
	resume_requested.emit()


func _on_restart_button_pressed() -> void:
	restart_requested.emit()


func _on_exit_button_pressed() -> void:
	exit_requested.emit()
