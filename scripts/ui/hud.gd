class_name Hud
extends PanelContainer
## Top bar of the game screen: pause button, energy, defender cards,
## level name, wave progress ("Oleada X de Y") and play time.
## It shows data and reports taps; Game decides what to do with them.

signal pause_pressed
## Emitted when the player taps a defender card.
signal card_pressed(card: DefenderCard)

const DEFENDER_CARD_SCENE := preload("res://scenes/ui/defender_card.tscn")

## Card chosen by the player. null = no card selected.
var selected_card: DefenderCard = null

@onready var pause_button: Button = %PauseButton
@onready var energy_label: Label = %EnergyLabel
@onready var cards_box: HBoxContainer = %Cards
@onready var level_label: Label = %LevelLabel
@onready var wave_label: Label = %WaveLabel
@onready var wave_bar: ProgressBar = %WaveBar
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)


## Creates one card for each defender of the level (LevelData.defenders), in order.
func create_cards(defender_types: Array[DefenderType]) -> void:
	for type in defender_types:
		var card: DefenderCard = DEFENDER_CARD_SCENE.instantiate()
		card.defender_type = type  # before add_child, so the card's _ready() has its data
		cards_box.add_child(card)
		# bind() adds the card as an argument, so one function serves every card.
		card.pressed.connect(_on_card_pressed.bind(card))


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
	energy_label.text = "Energía %d" % energy
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


func _on_pause_button_pressed() -> void:
	pause_pressed.emit()


func _on_card_pressed(card: DefenderCard) -> void:
	card_pressed.emit(card)
