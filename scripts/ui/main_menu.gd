extends Control
## Home screen. The Play button opens the game scene.

const GAME_SCENE := "res://scenes/game/game.tscn"

@onready var play_button: Button = %PlayButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)


func _notification(what: int) -> void:
	# Android back button on the home screen closes the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		get_tree().quit()
