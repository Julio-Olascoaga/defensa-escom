class_name EnergyOrb
extends Button
## Energy orb produced by a generator (Café). The player taps it to collect energy.
## It is a Button, so the UI handles the tap before the Board receives it:
## tapping an orb never places a defender by accident.
##
## Block 10: it pops out with a bounce and, when it is tapped, it flies to the
## energy counter of the top bar; the energy is added when it arrives.

## Emitted when the orb reaches the energy counter. Game adds the amount to the energy.
signal collected(amount: int)

## Seconds before an orb that nobody tapped disappears.
const LIFETIME := 8.0
## Floating: pixels it goes up and down, and seconds of each half.
const FLOAT_PIXELS := 6.0
const FLOAT_TIME := 0.6
## Appearing: it jumps BOUNCE_PIXELS up out of the Café and falls back with a bounce.
const BOUNCE_PIXELS := 40.0
const APPEAR_TIME := 0.45
## Seconds of the flight to the energy counter, and its size when it arrives.
const FLY_TIME := 0.4
const FLY_END_SCALE := 0.45

var amount := 25
## Position in board cells (decimals allowed). Game converts it to pixels.
var lane := 0.0
var column := 0.0
## Where it flies when tapped (the energy counter), in screen pixels.
## Game sets it; if it is never set, the orb is collected where it is (as in the 1.0).
var fly_target := Vector2.INF
## true from the tap on: it is flying and cannot be collected again.
var collecting := false

var float_tween: Tween

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
	pivot_offset = size / 2.0  # scale from the center
	_appear()


## Pops in: grows from nothing while it jumps up and lands with a bounce,
## then it starts floating. Game places the orb in the same frame it is added,
## so the jump is done on the Button's own contents (position is relative).
func _appear() -> void:
	scale = Vector2.ZERO
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE, APPEAR_TIME * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position:y", -BOUNCE_PIXELS, APPEAR_TIME * 0.35).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(self, "position:y", BOUNCE_PIXELS, APPEAR_TIME * 0.65).as_relative().set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(_start_floating)


## as_relative() moves it FROM wherever it is, so it works after Game places it.
func _start_floating() -> void:
	if collecting:
		return
	float_tween = create_tween().set_loops()
	float_tween.tween_property(self, "position:y", -FLOAT_PIXELS, FLOAT_TIME).as_relative().set_trans(Tween.TRANS_SINE)
	float_tween.tween_property(self, "position:y", FLOAT_PIXELS, FLOAT_TIME).as_relative().set_trans(Tween.TRANS_SINE)


func _on_pressed() -> void:
	if collecting:
		return
	collecting = true
	disabled = true  # avoids collecting the same orb twice
	AudioManager.play_sfx(AudioManager.SFX_COLLECT)
	life_timer.stop()  # it must not disappear in the middle of the flight
	if fly_target == Vector2.INF:
		_arrive()
		return
	if float_tween:
		float_tween.kill()
	# fly_target is in screen pixels; the orb lives in the game world.
	var target := get_viewport().get_canvas_transform().affine_inverse() * fly_target - size / 2.0
	var tween := create_tween().set_parallel()
	tween.tween_property(self, "global_position", target, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2.ONE * FLY_END_SCALE, FLY_TIME)
	tween.chain().tween_callback(_arrive)


func _arrive() -> void:
	collected.emit(amount)
	queue_free()
