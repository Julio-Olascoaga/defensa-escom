class_name Hud
extends PanelContainer
## Top bar of the game screen: pause button, energy, defender cards and play time.
## It shows data and reports taps; Game decides what to do with them.

signal pause_pressed
## Emitted when the player taps a defender card.
signal card_pressed(card: DefenderCard)

## Card chosen by the player. null = no card selected.
var selected_card: DefenderCard = null

@onready var pause_button: Button = %PauseButton
@onready var energy_label: Label = %EnergyLabel
@onready var cards_box: HBoxContainer = %Cards
@onready var time_label: Label = %TimeLabel


func _ready() -> void:
	pause_button.pressed.connect(_on_pause_button_pressed)
	for card: DefenderCard in cards_box.get_children():
		# bind() adds the card as an argument, so one function serves every card.
		card.pressed.connect(_on_card_pressed.bind(card))


func set_energy(energy: int) -> void:
	energy_label.text = "Energía %d" % energy
	for card: DefenderCard in cards_box.get_children():
		card.update_energy(energy)


func set_time(seconds: float) -> void:
	time_label.text = "Tiempo: %.1f s" % seconds


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
