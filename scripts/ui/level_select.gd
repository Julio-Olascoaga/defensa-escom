extends Control
## "Selección de nivel" of the world chosen on the career map
## (GameSession.world_index). A GridContainer of 4 columns x 2 rows is filled
## in code with one LevelButton per LevelData of the world (6 to 8), so a level
## added to world_N.tres in the Inspector appears here without touching scripts.
## A tap on an open level plays it; a tap on a locked one says why.
## Back (button or Android) returns to the career map.

var level_buttons: Array[LevelButton] = []

@onready var back_button: Button = %BackButton
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle
@onready var average_label: Label = %Average
@onready var grid: GridContainer = %Grid
@onready var notice: Notice = %Notice


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	var world := GameSession.current_world()
	title_label.text = world.display_name
	subtitle_label.text = world.location_name
	var average := ProgressRepository.get_world_average(world)
	average_label.text = "Promedio: %.1f" % average
	average_label.visible = average > 0.0
	_create_buttons(world)


func _create_buttons(world: WorldData) -> void:
	for i in world.levels.size():
		var button := LevelButton.new()
		var unlocked := GameSession.is_level_unlocked(GameSession.world_index, i)
		button.setup(world.levels[i], i, unlocked, ProgressRepository.get_grade(world, i))
		button.pressed.connect(_on_level_pressed.bind(i))
		grid.add_child(button)
		level_buttons.append(button)


func _on_level_pressed(index: int) -> void:
	var reason := GameSession.level_lock_reason(GameSession.world_index, index)
	if reason != "":
		notice.show_message(reason)  # locked: it does not enter and says why
		return
	GameSession.start_level(GameSession.world_index, index)


func _go_back() -> void:
	GameSession.open_map()


func _notification(what: int) -> void:
	# Android back button: back to the career map.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_back()
