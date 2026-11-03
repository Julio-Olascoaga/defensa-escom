extends Control
## Home screen. Shows the saved progress ("Mundo 1 · Nivel 3") and its main
## button says "Jugar" the first time and "Continuar" afterwards. The button
## opens the loading screen, which loads the current level.
##
## Hidden debug option (debug builds only): tap the title DEBUG_TAPS times
## in a row to open a panel that deletes the progress or simulates a save failure.

const LOADING_SCENE := "res://scenes/ui/loading_screen.tscn"
const DEBUG_TAPS := 5
## Maximum seconds between two taps on the title to keep counting.
const DEBUG_TAP_WINDOW := 1.0

var _debug_taps := 0
var _last_tap_time := 0.0

@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var play_button: Button = %PlayButton
@onready var load_error_label: Label = %LoadErrorLabel
@onready var debug_panel: Control = %DebugPanel
@onready var reset_button: Button = %ResetButton
@onready var fail_save_button: Button = %FailSaveButton
@onready var close_debug_button: Button = %CloseDebugButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	title_label.gui_input.connect(_on_title_gui_input)
	reset_button.pressed.connect(_on_reset_button_pressed)
	fail_save_button.pressed.connect(_on_fail_save_button_pressed)
	close_debug_button.pressed.connect(debug_panel.hide)
	debug_panel.hide()
	_show_progress()


## Writes the progress of the world and the text of the main button.
func _show_progress() -> void:
	var world_name := ProgressRepository.get_world().display_name
	if ProgressRepository.has_progress():
		subtitle_label.text = "%s · Nivel %d" % [world_name, ProgressRepository.get_current_level_number()]
		play_button.text = "Continuar"
	else:
		subtitle_label.text = world_name
		play_button.text = "Jugar"
	# A damaged or invalid progress file is not an error for the player:
	# the game simply starts again from level 1 and says so.
	load_error_label.visible = ProgressRepository.load_error != OK
	fail_save_button.text = "Simular falla al guardar: %s" % ("Sí" if ProgressRepository.simulate_save_error else "No")


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file(LOADING_SCENE)


# --- Hidden debug panel ---

func _on_title_gui_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return  # the option does not exist in a release APK
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_tap_time > DEBUG_TAP_WINDOW:
		_debug_taps = 0
	_last_tap_time = now
	_debug_taps += 1
	if _debug_taps >= DEBUG_TAPS:
		_debug_taps = 0
		debug_panel.show()


func _on_reset_button_pressed() -> void:
	ProgressRepository.reset_progress()
	_show_progress()


func _on_fail_save_button_pressed() -> void:
	ProgressRepository.simulate_save_error = not ProgressRepository.simulate_save_error
	_show_progress()


func _notification(what: int) -> void:
	# Android back button on the home screen closes the debug panel or the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if debug_panel.visible:
			debug_panel.hide()
		else:
			get_tree().quit()
