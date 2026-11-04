class_name VictoryPanel
extends Control
## Victory panel, shown when every wave of the level has been defeated.
## It shows the grade of the level with a stamp animation (10 minus the
## Extraordinarios used, minimum 6) and whether it beat the saved grade.
## Like the defeat panel, its process mode is "When Paused": the game freezes
## behind it and only these buttons respond (its Tweens run too, because they
## belong to this node). It tells Game what the player chose.

## "Siguiente nivel", or "Continuar" (to Semestre aprobado) after the last level.
signal next_requested
## "Selección de nivel".
signal home_requested

## The stamp falls from this scale and this angle (radians) onto the panel.
const STAMP_START_SCALE := 2.4
const STAMP_START_ROTATION := -0.6
const STAMP_END_ROTATION := -0.2
const STAMP_TIME := 0.35
const STAMP_DELAY := 0.15

## Animation of the stamp, kept so a test (or a second show) can wait for it or restart it.
var stamp_tween: Tween

@onready var title_label: Label = %Title
@onready var message_label: Label = %Message
## The stamp and its number. It is a child of StampBox (not StampBox itself)
## because containers reset the scale and rotation of their direct children.
@onready var seal: Control = %Seal
@onready var grade_label: Label = %GradeLabel
@onready var best_label: Label = %BestLabel
@onready var next_button: Button = %NextButton
@onready var home_button: Button = %HomeButton


func _ready() -> void:
	next_button.pressed.connect(_on_next_button_pressed)
	home_button.pressed.connect(_on_home_button_pressed)


## A level was won. previous_grade is the best grade saved before this
## victory (0 = first win). After the last level of the world the next
## button says "Continuar" and leads to the "Semestre aprobado" screen.
func show_victory(level_number: int, level_name: String, grade: int, previous_grade: int, is_last_level: bool) -> void:
	title_label.text = "¡Nivel superado!"
	message_label.text = "Nivel %d · %s" % [level_number, level_name]
	grade_label.text = str(grade)
	if grade > previous_grade:
		best_label.text = "¡Nueva mejor calificación!"
	else:
		best_label.text = "Tu mejor calificación: %d" % previous_grade
	next_button.text = "Continuar" if is_last_level else "Siguiente nivel"
	next_button.show()
	show()
	_play_stamp()


## The stamp falls big and turned, and lands on the panel with a small bounce.
func _play_stamp() -> void:
	if stamp_tween:
		stamp_tween.kill()
	seal.pivot_offset = seal.get_parent().custom_minimum_size / 2.0
	seal.scale = Vector2.ONE * STAMP_START_SCALE
	seal.rotation = STAMP_START_ROTATION
	seal.modulate.a = 0.0
	stamp_tween = create_tween().set_parallel()
	stamp_tween.tween_property(seal, "scale", Vector2.ONE, STAMP_TIME).set_delay(STAMP_DELAY).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stamp_tween.tween_property(seal, "rotation", STAMP_END_ROTATION, STAMP_TIME).set_delay(STAMP_DELAY)
	stamp_tween.tween_property(seal, "modulate:a", 1.0, STAMP_TIME * 0.5).set_delay(STAMP_DELAY)


func _on_next_button_pressed() -> void:
	next_requested.emit()


func _on_home_button_pressed() -> void:
	home_requested.emit()
