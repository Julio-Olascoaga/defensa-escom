class_name PauseHiddenLayer
extends CanvasLayer
## A CanvasLayer that hides itself while the game is paused and shows itself
## again on resume (v1.4 fix). The tutorial uses it for its bubble and arrow:
## they are on layer 2, above the game UI, so without it they were drawn over
## the pause menu. Godot sends NOTIFICATION_PAUSED / NOTIFICATION_UNPAUSED to
## Pausable nodes, so it also works with the Android back button.


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		hide()
	elif what == NOTIFICATION_UNPAUSED:
		show()
