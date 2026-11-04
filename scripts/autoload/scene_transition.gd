extends CanvasLayer
## Autoload (singleton) "SceneTransition": a black ColorRect above everything
## that fades in with a Tween, changes the scene, and fades out again.
## Every screen change of the game goes through here instead of calling
## get_tree().change_scene_to_file() directly.

## Seconds of each half of the fade (to black and back).
const FADE_TIME := 0.25

## True while a fade is running, so a second tap does not start another one.
var is_changing := false

var _curtain := ColorRect.new()


func _ready() -> void:
	layer = 100  # above every other CanvasLayer of the game
	process_mode = Node.PROCESS_MODE_ALWAYS  # it works even while the game is paused
	_curtain.color = Color(0, 0, 0, 0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_curtain)


## Fades to black and opens the scene in this path.
func change_scene(path: String) -> void:
	_fade_and_run(get_tree().change_scene_to_file.bind(path))


## Same, with a scene that is already loaded (the loading screen uses it).
func change_scene_to_packed(scene: PackedScene) -> void:
	_fade_and_run(get_tree().change_scene_to_packed.bind(scene))


## Fades to black and starts the current scene again ("Reiniciar nivel").
func reload_scene() -> void:
	_fade_and_run(get_tree().reload_current_scene)


func _fade_and_run(change: Callable) -> void:
	if is_changing:
		return
	is_changing = true
	_curtain.mouse_filter = Control.MOUSE_FILTER_STOP  # no taps during the fade
	var tween := create_tween()
	tween.tween_property(_curtain, "color:a", 1.0, FADE_TIME)
	await tween.finished
	# The old scene stayed frozen behind the curtain; the new one must not start paused.
	get_tree().paused = false
	change.call()
	tween = create_tween()
	tween.tween_property(_curtain, "color:a", 0.0, FADE_TIME)
	await tween.finished
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing = false
