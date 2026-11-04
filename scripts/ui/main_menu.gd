extends Control
## Home screen ("Inicio"). Shows the saved progress ("Primer semestre · Nivel 3")
## and its main button says "Jugar" the first time and "Continuar" afterwards;
## it opens the career map. The other buttons open Ajustes and Créditos
## (Expediente arrives in Block 9 and is disabled until then).
## The Android back button asks before closing the game.
##
## Hidden debug option (debug builds only): tap the logo DEBUG_TAPS times
## in a row to open a panel that deletes the progress or simulates a save failure.

const DEBUG_TAPS := 5
## Maximum seconds between two taps on the logo to keep counting.
const DEBUG_TAP_WINDOW := 1.0

var _debug_taps := 0
var _last_tap_time := 0.0

@onready var logo: TextureRect = %Logo
@onready var subtitle_label: Label = %Subtitle
@onready var play_button: Button = %PlayButton
@onready var expediente_button: Button = %ExpedienteButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var load_error_label: Label = %LoadErrorLabel
@onready var version_label: Label = $VersionLabel
@onready var debug_panel: Control = %DebugPanel
@onready var reset_button: Button = %ResetButton
@onready var fail_save_button: Button = %FailSaveButton
@onready var close_debug_button: Button = %CloseDebugButton
@onready var quit_panel: Control = %QuitPanel
@onready var quit_yes_button: Button = %QuitYesButton
@onready var quit_no_button: Button = %QuitNoButton


func _ready() -> void:
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	logo.gui_input.connect(_on_logo_gui_input)
	reset_button.pressed.connect(_on_reset_button_pressed)
	fail_save_button.pressed.connect(_on_fail_save_button_pressed)
	close_debug_button.pressed.connect(debug_panel.hide)
	quit_yes_button.pressed.connect(get_tree().quit)
	quit_no_button.pressed.connect(quit_panel.hide)
	debug_panel.hide()
	quit_panel.hide()
	# The version is written only once, in Project Settings (application/config/version).
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	_show_progress()


## Writes the progress of the latest open world and the text of the main button.
func _show_progress() -> void:
	var world := GameSession.campaign.worlds[GameSession.latest_world_index()]
	if ProgressRepository.has_progress():
		subtitle_label.text = "%s · Nivel %d" % [world.display_name, ProgressRepository.get_current_level(world)]
		play_button.text = "Continuar"
	else:
		subtitle_label.text = world.display_name
		play_button.text = "Jugar"
	# A damaged or invalid progress file is not an error for the player:
	# the game simply starts again from zero and says so.
	load_error_label.visible = ProgressRepository.load_error != OK
	fail_save_button.text = "Simular falla al guardar: %s" % ("Sí" if ProgressRepository.simulate_save_error else "No")


func _on_play_button_pressed() -> void:
	GameSession.open_map()


func _on_settings_button_pressed() -> void:
	SceneTransition.change_scene(GameSession.SETTINGS_SCENE)


func _on_credits_button_pressed() -> void:
	Credits.back_scene = Credits.MAIN_MENU_SCENE
	SceneTransition.change_scene(Credits.CREDITS_SCENE)


# --- Hidden debug panel ---

func _on_logo_gui_input(event: InputEvent) -> void:
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
	# Android back button on the home screen: closes the open panel,
	# or asks "¿Salir del juego?" before closing the app.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		if debug_panel.visible:
			debug_panel.hide()
		elif quit_panel.visible:
			quit_panel.hide()
		else:
			quit_panel.show()
