class_name SaveErrorPanel
extends Control
## Notice "No se pudo guardar tu progreso", shown on top of the Victory panel
## when ProgressRepository.save_progress() returns an error code.
## Its process mode is "When Paused" like the other panels. It does not save
## by itself: on "Reintentar" it asks Game to try again.

signal retry_requested

@onready var message_label: Label = %Message
@onready var retry_button: Button = %RetryButton
@onready var later_button: Button = %LaterButton


func _ready() -> void:
	retry_button.pressed.connect(_on_retry_button_pressed)
	later_button.pressed.connect(_on_later_button_pressed)


## First failure.
func show_error() -> void:
	message_label.text = "Puedes seguir jugando, pero si cierras la app\nperderás el avance de este nivel."
	show()


## "Reintentar" was tapped and saving failed again.
func show_retry_failed() -> void:
	message_label.text = "Sigue sin poder guardarse.\nRevisa el espacio libre del teléfono e inténtalo de nuevo."
	show()


func _on_retry_button_pressed() -> void:
	retry_requested.emit()


## "Ahora no": the progress stays in memory until the app is closed.
func _on_later_button_pressed() -> void:
	hide()
