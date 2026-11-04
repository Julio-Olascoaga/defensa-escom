class_name Credits
extends Control
## "Créditos": the team, the course and the engine. It opens from Inicio and
## from Ajustes; "Volver" and the Android back button return to the screen
## that opened it (back_scene).

const CREDITS_SCENE := "res://scenes/ui/credits.tscn"
const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings.tscn"

## Screen that opened the credits. The caller sets it before changing scene.
static var back_scene := MAIN_MENU_SCENE

@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(_go_back)


func _go_back() -> void:
	SceneTransition.change_scene(back_scene)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_back()
