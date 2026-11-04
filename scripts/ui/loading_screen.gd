extends Control
## Loading screen shown every time a level is entered (from Inicio and from
## "Siguiente nivel"). GameSession says which level; it loads game.tscn in a background thread with
## ResourceLoader and fills the bar with the loading progress.
## If the background load fails it tries once more the normal way, and if the
## level data or the scene still cannot be loaded, it shows an error
## with "Volver al inicio" instead of crashing.

const GAME_SCENE := "res://scenes/game/game.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
## The screen stays at least this long so it does not just flash on fast phones.
const MIN_TIME := 0.6

var elapsed_time := 0.0

@onready var title_label: Label = %Title
@onready var level_label: Label = %LevelLabel
@onready var bar: ProgressBar = %Bar
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	home_button.pressed.connect(_on_home_button_pressed)
	home_button.hide()
	var level := GameSession.current_level()
	if level == null or level.waves.is_empty():
		_show_error("Los datos del nivel %d no son válidos" % GameSession.current_level_number())
		return
	level_label.text = "Nivel %d · %s" % [GameSession.current_level_number(), level.display_name]
	if ResourceLoader.load_threaded_request(GAME_SCENE) != OK:
		_show_error("No se pudo cargar el nivel")


func _process(delta: float) -> void:
	elapsed_time += delta
	var progress := []
	var status := ResourceLoader.load_threaded_get_status(GAME_SCENE, progress)
	match status:
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			bar.value = progress[0] * 100.0
		ResourceLoader.THREAD_LOAD_LOADED:
			bar.value = 100.0
			if elapsed_time >= MIN_TIME:
				set_process(false)
				SceneTransition.change_scene_to_packed(ResourceLoader.load_threaded_get(GAME_SCENE))
		_:  # THREAD_LOAD_FAILED or THREAD_LOAD_INVALID_RESOURCE
			_load_without_thread()


## Plan B: load the scene on the main thread (the screen freezes for a moment).
func _load_without_thread() -> void:
	set_process(false)
	var scene := load(GAME_SCENE) as PackedScene
	if scene:
		SceneTransition.change_scene_to_packed(scene)
	else:
		_show_error("No se pudo cargar el nivel")


func _show_error(message: String) -> void:
	set_process(false)
	push_error(message)
	title_label.text = "Algo salió mal"
	level_label.text = message
	bar.hide()
	home_button.show()


func _on_home_button_pressed() -> void:
	SceneTransition.change_scene(MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	# Android back button: only works on the error state, like "Volver al inicio".
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and home_button.visible:
		_on_home_button_pressed()
