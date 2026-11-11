extends Control
## "Mapa de la carrera": the 8 semesters side by side in a horizontal
## ScrollContainer, joined by a path. Block 11: it is an illustrated map: the
## grass is a tile drawn under the whole track (it scrolls with it), the path
## is a dirt road with curves, and each button shows its place of the IPN. The buttons are created in code from
## GameSession.campaign.worlds, so a new WorldData added to campaign.tres
## appears here without touching this script.
## A tap on an open semester opens its level select; a tap on a locked one
## does not enter and says why. Back (button or Android) returns to Inicio.

## The road between the semesters: its border, its dirt and its widths.
const PATH_BORDER_COLOR := Color("2b1b2e")
const PATH_COLOR := Color("e2c48f")
const PATH_BORDER_WIDTH := 34.0
const PATH_WIDTH := 24.0
## Picture of the grass, repeated along the whole map.
const GROUND_TEXTURE := preload("res://art/map/map_ground.png")

## The buttons in campaign order (index = world index).
var semester_buttons: Array[SemesterButton] = []

@onready var back_button: Button = %BackButton
@onready var scroll: ScrollContainer = %Scroll
@onready var track: Control = %Track
@onready var semesters_box: HBoxContainer = %Semesters
@onready var notice: Notice = %Notice


func _ready() -> void:
	AudioManager.play_music(AudioManager.MENU_MUSIC)  # it keeps playing if it already was
	back_button.pressed.connect(_go_back)
	track.draw.connect(_draw_path)
	semesters_box.sort_children.connect(track.queue_redraw)  # the path follows the buttons
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
	if GameSession.is_world_coming_soon(index):
		return SemesterButton.State.COMING_SOON  # opened, but not built yet
	if not GameSession.is_world_unlocked(index):
		return SemesterButton.State.LOCKED
	if ProgressRepository.is_world_completed(GameSession.campaign.worlds[index]):
		return SemesterButton.State.PASSED
	return SemesterButton.State.AVAILABLE


## The grass, and a curved road through the centers of the buttons,
## drawn on Track behind them. The Curve2D bends the road: each point gets
## horizontal "handles", so the road leaves and arrives flat.
func _draw_path() -> void:
	track.draw_texture_rect(GROUND_TEXTURE, Rect2(Vector2.ZERO, track.size), true)  # true = tiled
	var curve := Curve2D.new()
	for button in semester_buttons:
		var center := button.position + semesters_box.position + button.size / 2.0
		var handle := Vector2(semesters_box.get_theme_constant("separation") + button.size.x / 2.0, 0)
		curve.add_point(center, -handle, handle)
	if curve.point_count >= 2:
		var points := curve.tessellate()
		track.draw_polyline(points, PATH_BORDER_COLOR, PATH_BORDER_WIDTH, true)
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
