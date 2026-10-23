extends Node2D
## Root of the game scene.
## In v0.1 it counts play time, reacts to taps on the board and handles pause.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

## Seconds of play. It stops while the game is paused because this node
## uses the default process mode (Inherit -> Pausable).
var elapsed_time := 0.0

@onready var board: Board = $Board
@onready var hud: Hud = $UI/HUD
@onready var pause_menu: PauseMenu = $UI/PauseMenu


func _ready() -> void:
	board.cell_tapped.connect(_on_board_cell_tapped)
	hud.pause_pressed.connect(pause_game)
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.exit_requested.connect(_on_exit_requested)


func _process(delta: float) -> void:
	elapsed_time += delta
	hud.set_time(elapsed_time)


func pause_game() -> void:
	get_tree().paused = true  # every Pausable node stops (_process and input)
	pause_menu.show()         # the menu keeps working: its mode is "When Paused"


func resume_game() -> void:
	pause_menu.hide()
	get_tree().paused = false


func _on_board_cell_tapped(lane: int, column: int) -> void:
	board.highlight_cell(lane, column)
	print("Tapped cell: lane %d, column %d" % [lane, column])


func _on_restart_requested() -> void:
	get_tree().paused = false  # the new scene must not start paused
	get_tree().reload_current_scene()


func _on_exit_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	# Notifications arrive even while paused.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# The app went to the background (call, home button...): pause it.
		if not get_tree().paused:
			pause_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# Android back button: opens or closes the pause menu.
		if get_tree().paused:
			resume_game()
		else:
			pause_game()
