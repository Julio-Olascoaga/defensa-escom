extends Control
## "Mapa de la carrera": the 8 semesters side by side in a horizontal
## ScrollContainer, joined by a path. The buttons are created in code from
## GameSession.campaign.worlds, so a new WorldData added to campaign.tres
## appears here without touching this script.
## A tap on an open semester opens its level select; a tap on a locked one
## does not enter and says why. Back (button or Android) returns to Inicio.

## Color and width of the path drawn between the semesters.
const PATH_COLOR := Color(0.957, 0.949, 1, 0.55)
const PATH_WIDTH := 10.0

## The buttons in campaign order (index = world index).
var semester_buttons: Array[SemesterButton] = []

@onready var back_button: Button = %BackButton
@onready var scroll: ScrollContainer = %Scroll
@onready var track: Control = %Track
@onready var semesters_box: HBoxContainer = %Semesters
@onready var notice: Notice = %Notice


func _ready() -> void:
	back_button.pressed.connect(_go_back)
	track.draw.connect(_draw_path)
	_create_buttons()
	# Wait for the containers to place the buttons, then show the latest open semester.
	await get_tree().process_frame
	track.queue_redraw()
	scroll_to_world(GameSession.latest_world_index())


func _create_buttons() -> void:
	var worlds := GameSession.campaign.worlds
	for i in worlds.size():
		var world := worlds[i]
		var button := SemesterButton.new()
		button.setup(world, i, _state_of(i), ProgressRepository.get_world_average(world))
		# Up and down, so the path between the semesters zigzags.
		button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if i % 2 == 0 else Control.SIZE_SHRINK_END
		button.pressed.connect(_on_semester_pressed.bind(i))
		semesters_box.add_child(button)
		semester_buttons.append(button)


func _state_of(index: int) -> SemesterButton.State:
	if not GameSession.is_world_unlocked(index):
		return SemesterButton.State.LOCKED
	if ProgressRepository.is_world_completed(GameSession.campaign.worlds[index]):
		return SemesterButton.State.PASSED
	return SemesterButton.State.AVAILABLE


## Line through the centers of the buttons, drawn on Track behind them.
func _draw_path() -> void:
	var points := PackedVector2Array()
	for button in semester_buttons:
		points.append(button.position + semesters_box.position + button.size / 2.0)
	if points.size() >= 2:
		track.draw_polyline(points, PATH_COLOR, PATH_WIDTH, true)


## Scrolls so that the semester is near the left third of the screen.
func scroll_to_world(index: int) -> void:
	if index < 0 or index >= semester_buttons.size():
		return
	var button := semester_buttons[index]
	scroll.scroll_horizontal = maxi(0, int(button.position.x + semesters_box.position.x - size.x / 3.0))


func _on_semester_pressed(index: int) -> void:
	var reason := GameSession.world_lock_reason(index)
	if reason != "":
		notice.show_message(reason)  # locked: it does not enter and says why
		return
	GameSession.open_world(index)


func _go_back() -> void:
	SceneTransition.change_scene(GameSession.MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	# Android back button: back to Inicio.
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and not SceneTransition.is_changing:
		_go_back()
