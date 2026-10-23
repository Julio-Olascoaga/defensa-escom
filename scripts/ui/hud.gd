class_name Hud
extends PanelContainer
## Top bar of the game screen. In v0.1 it shows fixed data
## (energy, defender cards, wave) and the play time.

signal pause_pressed

@onready var pause_button: Button = %PauseButton
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)


func set_time(seconds: float) -> void:
	time_label.text = "Tiempo: %.1f s" % seconds


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()
