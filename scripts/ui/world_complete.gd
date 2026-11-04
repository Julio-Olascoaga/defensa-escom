extends Control
## "Semestre aprobado": shown after the last level of a world is won
## (Victory -> "Continuar"). It shows the average of the semester with the
## grade stamp, the best grade of every level, and whether the next semester
## opened. It replaces the 1.0 notice "¡Mundo 1 superado!" and, unlike the 1.0,
## the progress is not sent back to level 1.
## "Mapa de la carrera" and the Android back button go to the career map.

const STAMP_START_SCALE := 2.4
const STAMP_TIME := 0.35

var stamp_tween: Tween

@onready var title_label: Label = %Title
@onready var world_name_label: Label = %WorldName
## The stamp and its number. It is a child of StampBox (not StampBox itself)
## because containers reset the scale and rotation of their direct children.
@onready var seal: Control = %Seal
@onready var average_label: Label = %AverageLabel
@onready var grades_grid: GridContainer = %Grades
@onready var next_world_label: Label = %NextWorldLabel
@onready var map_button: Button = %MapButton


func _ready() -> void:
	map_button.pressed.connect(_go_to_map)
	var world := GameSession.current_world()
	title_label.text = "¡%s aprobado!" % world.display_name
	world_name_label.text = world.location_name
	average_label.text = "%.1f" % ProgressRepository.get_world_average(world)
	for i in world.levels.size():
		var grade := ProgressRepository.get_grade(world, i)
		var line := Label.new()
		line.add_theme_font_size_override("font_size", 20)
		line.text = "%d. %s: %s" % [i + 1, world.levels[i].display_name, str(grade) if grade > 0 else "—"]
		grades_grid.add_child(line)
	next_world_label.text = _next_world_text()
	_play_stamp()


## What happens with the next semester now that this one is passed.
func _next_world_text() -> String:
	var next_index := GameSession.world_index + 1
	if next_index >= GameSession.campaign.worlds.size():
		return "¡Terminaste la carrera!"
	var next_world := GameSession.campaign.worlds[next_index]
	if GameSession.is_world_unlocked(next_index):
		return "Se abrió %s" % next_world.display_name
	return "%s: Próximamente" % next_world.display_name


func _play_stamp() -> void:
	seal.pivot_offset = seal.get_parent().custom_minimum_size / 2.0
	seal.scale = Vector2.ONE * STAMP_START_SCALE
	seal.modulate.a = 0.0
	stamp_tween = create_tween().set_parallel()
	stamp_tween.tween_property(seal, "scale", Vector2.ONE, STAMP_TIME).set_delay(0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	stamp_tween.tween_property(seal, "rotation", -0.2, STAMP_TIME).set_delay(0.3)
	stamp_tween.tween_property(seal, "modulate:a", 1.0, STAMP_TIME * 0.5).set_delay(0.3)


func _go_to_map() -> void:
	GameSession.open_map()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_to_map()
