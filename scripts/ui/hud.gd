class_name Hud
extends PanelContainer
## Top bar of the game screen: pause button, "Dar de baja" (eraser) button,
## energy, defender cards, level name, wave progress ("Oleada X de Y") and play time.
## It shows data and reports taps; Game decides what to do with them.
##
## Card bar (Block 8): up to MAX_CARDS cards in a compact row at the top.
## The team chose the top row over a vertical bar on the left, so the left
## edge of the board stays free for the Extraordinarios. To try the vertical
## bar instead, move %Cards out of Row into a VBoxContainer on the left of
## the game screen and change its type to VBoxContainer: create_cards() and
## the cards do not depend on where the box is.

signal pause_pressed
## Emitted when the player taps a defender card.
signal card_pressed(card: DefenderCard)
## Emitted when the player turns the eraser on or off with its button.
signal eraser_toggled(active: bool)

const DEFENDER_CARD_SCENE := preload("res://scenes/ui/defender_card.tscn")
## A level never offers more cards than this (the limit of the bar).
const MAX_CARDS := 6
## Up to this many cards keep the big size of the 1.0; more use the compact size.
const FULL_SIZE_CARDS := 3

## Card chosen by the player. null = no card selected.
var selected_card: DefenderCard = null
## true while "Dar de baja" is on: the next tap on a defender removes it.
var eraser_active := false

@onready var pause_button: Button = %PauseButton
@onready var eraser_button: Button = %EraserButton
@onready var energy_label: Label = %EnergyLabel
@onready var cards_box: HBoxContainer = %Cards
@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel
@onready var wave_bar: ProgressBar = %WaveBar
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)
	eraser_button.toggled.connect(_on_eraser_button_toggled)


## Creates one card for each defender of the level (LevelData.defenders), in order.
## Four or more cards use the compact size so that six fit in the bar.
func create_cards(defender_types: Array[DefenderType]) -> void:
	if defender_types.size() > MAX_CARDS:
		push_warning("A level has %d defenders; the bar shows the first %d" % [defender_types.size(), MAX_CARDS])
	var compact := defender_types.size() > FULL_SIZE_CARDS
	for type in defender_types.slice(0, MAX_CARDS):
		var card: DefenderCard = DEFENDER_CARD_SCENE.instantiate()
		card.defender_type = type  # before add_child, so the card's _ready() has its data
		card.compact = compact
		cards_box.add_child(card)
		# bind() adds the card as an argument, so one function serves every card.
		card.pressed.connect(_on_card_pressed.bind(card))


## The card of a defender type, or null if the level does not have it
## (the tutorial points its arrow at it).
func get_card(type: DefenderType) -> DefenderCard:
	for card: DefenderCard in cards_box.get_children():
		if card.defender_type == type:
			return card
	return null


## Moves the content of the bar away from the phone's notch (Game measures it).
## The dark background of the bar still covers the whole width.
func set_side_margins(left: float, right: float) -> void:
	if left <= 0.0 and right <= 0.0:
		return
	var style := get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.content_margin_left += left
	style.content_margin_right += right
	add_theme_stylebox_override("panel", style)


func set_energy(energy: int) -> void:
	energy_label.text = "Energía
%d" % energy
	for card: DefenderCard in cards_box.get_children():
		card.update_energy(energy)


func set_time(seconds: float) -> void:
	time_label.text = "Tiempo: %d s" % seconds


func set_level_name(level_number: int, level_name: String) -> void:
	level_label.text = "Nivel %d · %s" % [level_number, level_name]


## WaveManager emits wave_started(wave_number, wave_count) and Game connects it here.
func set_wave(wave_number: int, wave_count: int) -> void:
	wave_label.text = "Oleada %d de %d" % [wave_number, wave_count]


## The bar fills as the enemies of the current wave appear, and starts empty in each wave.
func set_wave_progress(spawned: int, total: int) -> void:
	wave_bar.max_value = maxi(total, 1)  # never 0, so the bar can be drawn
	wave_bar.value = spawned


func select_card(card: DefenderCard) -> void:
	clear_selection()
	selected_card = card
	card.set_selected(true)


func clear_selection() -> void:
	if selected_card:
		selected_card.set_selected(false)
	selected_card = null


## Turns the eraser on or off from code (Game puts it away after removing
## a defender or when a card is chosen). It does not emit eraser_toggled.
func set_eraser_active(active: bool) -> void:
	eraser_active = active
	eraser_button.set_pressed_no_signal(active)


func _on_eraser_button_toggled(active: bool) -> void:
	eraser_active = active
	eraser_toggled.emit(active)


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()


func _on_card_pressed(card: DefenderCard) -> void:
	card_pressed.emit(card)
