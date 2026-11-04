class_name Tutorial
extends Node
## Guided tutorial of "Primer día" (LevelData.is_tutorial, Block 9).
## It is a list of steps. Each step shows a short text of the Director in a
## bubble, moves an animated arrow (TutorialPointer) to what the player must
## touch, and waits for one event of Game: a card selected, a defender placed
## or an energy orb collected. Game does not start the waves until run() ends.
## It works in cells like the rest of the game; the arrow only converts to
## pixels to be drawn.

## Every step is done. The waves can start.
signal finished

const CAFE := preload("res://data/defenders/cafe.tres")
const LAPTOP := preload("res://data/defenders/laptop.tres")
## Lane where the tasks of "Primer día" walk (the middle one). The Laptop must go there.
const ENEMY_LANE := 2
## Seconds the last message stays on screen after the tutorial ends.
const LAST_MESSAGE_TIME := 5.0
const LAST_TEXT := "¡Listo! En unos segundos llega la tarea. Mientras, junta energía y pon más defensores."

## The steps, in order. "wait" is the event that completes the step:
##   "card"  -> the player selects the card of "type"
##   "place" -> the player places a defender of "type" (in "lane", if the step has one)
##   "orb"   -> the player collects an energy orb
## "gift" is energy the Director gives at the start of the step.
var steps: Array[Dictionary] = [
	{"text": "Primero, cafeína. Toca la carta del Café.", "wait": "card", "type": CAFE},
	{"text": "Ahora toca una casilla para ponerlo. El Café va atrás, a la izquierda, lejos del peligro.", "wait": "place", "type": CAFE},
	{"text": "El Café está preparando energía. Cuando salga el orbe, tócalo antes de que se enfríe.", "wait": "orb"},
	{"text": "¡Eso! Te regalo 75 de energía, pero no le digas a nadie. Ahora toca la carta de la Laptop.", "wait": "card", "type": LAPTOP, "gift": 75},
	{"text": "Ponla en el carril que marca la flecha: por ahí viene la tarea.", "wait": "place", "type": LAPTOP, "lane": ENEMY_LANE},
]
## Position of the current step in steps. -1 = not started; steps.size() = done.
var step_index := -1
## The Game node. Untyped because game.gd has no class_name.
var game: Node

@onready var bubble: Control = %Bubble
@onready var bubble_text: Label = %BubbleText
@onready var pointer: TutorialPointer = %Pointer
@onready var hide_timer: Timer = $HideTimer


func _ready() -> void:
	bubble.hide()
	hide_timer.timeout.connect(bubble.hide)


## Game calls it before the first wave and waits for it (await tutorial.run(self)).
func run(game_node: Node) -> void:
	game = game_node
	game.card_selected.connect(_on_card_selected)
	game.defender_placed.connect(_on_defender_placed)
	game.orb_collected.connect(_on_orb_collected)
	_start_step(0)
	await finished


func is_running() -> bool:
	return step_index >= 0 and step_index < steps.size()


## Game asks before placing a defender: in the Laptop step it must go in the
## lane of the tasks, otherwise the player would lose without understanding why.
func allows_placement(type: DefenderType, lane: int) -> bool:
	if not is_running():
		return true
	var step := steps[step_index]
	if step.wait == "place" and step.has("lane") and step.type == type:
		return lane == step.lane
	return true


func _start_step(index: int) -> void:
	step_index = index
	if index >= steps.size():
		_end()
		return
	var step := steps[index]
	if step.has("gift"):
		game.add_energy(step.gift)
	bubble_text.text = step.text
	bubble.show()


func _end() -> void:
	pointer.hide()
	bubble_text.text = LAST_TEXT
	hide_timer.start(LAST_MESSAGE_TIME)
	game.card_selected.disconnect(_on_card_selected)
	game.defender_placed.disconnect(_on_defender_placed)
	game.orb_collected.disconnect(_on_orb_collected)
	finished.emit()


# --- Events of Game ---

func _on_card_selected(type: DefenderType) -> void:
	_complete_if("card", type)


func _on_defender_placed(type: DefenderType, lane: int, _column: int) -> void:
	if is_running() and steps[step_index].has("lane") and lane != steps[step_index].lane:
		return
	_complete_if("place", type)


func _on_orb_collected(_amount: int) -> void:
	_complete_if("orb", null)


## Goes to the next step if the event is the one the current step waits for.
func _complete_if(event: String, type: DefenderType) -> void:
	if not is_running():
		return
	var step := steps[step_index]
	if step.wait == event and step.get("type") == type:
		_start_step(step_index + 1)


# --- Arrow ---

## Every frame the arrow goes to what the current step needs. It freezes with
## the pause like the rest of the game (this node is Pausable).
func _process(_delta: float) -> void:
	if not is_running():
		return
	var step := steps[step_index]
	match step.wait:
		"card":
			_point_at_card(step.type)
		"place":
			var selected: DefenderCard = game.hud.selected_card
			if selected and selected.defender_type == step.type:
				_point_at_cell(step.get("lane", ENEMY_LANE))
			else:
				_point_at_card(step.type)  # the player put the card away: choose it again
		"orb":
			_point_at_orb()


## The arrow is under the card and points up at it.
func _point_at_card(type: DefenderType) -> void:
	var card: DefenderCard = game.hud.get_card(type)
	if card == null:
		pointer.hide()
		return
	var rect := card.get_global_rect()
	pointer.point_at(Vector2(rect.get_center().x, rect.end.y), true)


## The first free cell of the lane, from the left.
func _point_at_cell(lane: int) -> void:
	var board: Board = game.board
	var column := 0
	while column < Board.COLUMNS - 1 and board.is_occupied(lane, column):
		column += 1
	pointer.point_at(board.cell_to_pixel(lane, column) - Vector2(0, Board.CELL_SIZE * 0.25))


func _point_at_orb() -> void:
	var orbs: Array[Node] = game.orbs.get_children()
	if orbs.is_empty():
		pointer.hide()  # the Café is still preparing it
		return
	var orb: EnergyOrb = orbs[0]
	pointer.point_at(orb.global_position + Vector2(orb.size.x / 2.0, 0))
