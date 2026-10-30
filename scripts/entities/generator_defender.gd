class_name GeneratorDefender
extends Defender
## Café: produces an energy orb every orb_interval seconds, using a Timer node.
## The Timer stops by itself while the game is paused.

## Emitted with each new orb. Game adds it to the scene and listens to it.
signal orb_produced(orb: EnergyOrb)

const ENERGY_ORB_SCENE := preload("res://scenes/entities/energy_orb.tscn")

@onready var orb_timer: Timer = $OrbTimer


func _ready() -> void:
	super()  # runs Defender._ready() first (letter or image)
	orb_timer.wait_time = defender_type.orb_interval
	orb_timer.timeout.connect(_on_orb_timer_timeout)
	orb_timer.start()


func _on_orb_timer_timeout() -> void:
	var orb: EnergyOrb = ENERGY_ORB_SCENE.instantiate()
	# The orb appears at the top-right corner of this cell (cell units, not pixels).
	orb.setup(defender_type.energy_per_orb, lane - 0.25, column + 0.25)
	orb_produced.emit(orb)
