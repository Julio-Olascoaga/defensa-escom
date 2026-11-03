class_name Notice
extends Label
## Short warning near the bottom of the screen
## ("Esa casilla ya está ocupada", "Energía insuficiente: faltan 25"...).
## It hides itself after DURATION seconds. It is a Label, so it ignores taps.
## The game scene also uses a bigger instance of it, WaveBanner, for the wave warnings.

const DURATION := 2.0

@onready var hide_timer: Timer = $HideTimer


func _ready() -> void:
	hide()
	hide_timer.timeout.connect(hide)


func show_message(message: String) -> void:
	text = message
	show()
	hide_timer.start(DURATION)  # restarts the countdown if a notice was already visible
