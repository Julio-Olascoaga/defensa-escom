class_name EnergyOrb
extends Button
## Energy orb produced by a generator (Café). The player taps it to collect energy.
## It is a Button, so the UI handles the tap before the Board receives it:
## tapping an orb never places a defender by accident.

## Emitted when the player taps the orb. Game adds the amount to the energy.
signal collected(amount: int)

## Seconds before an orb that nobody tapped disappears.
const LIFETIME := 8.0

var amount := 25
## Position in board cells (decimals allowed). Game converts it to pixels.
var lane := 0.0
var column := 0.0

@onready var life_timer: Timer = $LifeTimer


## Called by the generator right after instantiate() and before add_child().
func setup(orb_amount: int, cell_lane: float, cell_column: float) -> void:
	amount = orb_amount
	lane = cell_lane
	column = cell_column


func _ready() -> void:
	text = "+%d" % amount
	pressed.connect(_on_pressed)
	life_timer.timeout.connect(queue_free)  # not collected in time: it disappears
	life_timer.start(LIFETIME)


func _on_pressed() -> void:
	disabled = true  # avoids collecting the same orb twice
	collected.emit(amount)
	queue_free()
