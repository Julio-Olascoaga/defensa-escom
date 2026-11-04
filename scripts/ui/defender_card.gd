class_name DefenderCard
extends Button
## One defender card of the top bar. It only SHOWS state; Game decides the rules.
## Text by state:
##   ready        -> "Café / 50"            (normal)
##   no energy    -> "Café / faltan 25"     (dimmed)
##   recharging   -> "Café / espera 5 s"    (dimmed)
## A yellow frame marks the selected card.

const DIMMED := Color(1, 1, 1, 0.45)
## Size of the card when the bar has 1 to 3 cards (as in the 1.0) and when it has 4 to 6.
const FULL_SIZE := Vector2(160, 80)
const COMPACT_SIZE := Vector2(110, 80)
const COMPACT_FONT_SIZE := 16
const COMPACT_ICON_WIDTH := 36

## The defender this card places. Hud assigns it when it creates the card from LevelData.defenders.
@export var defender_type: DefenderType
## true = narrow card, so that 6 cards fit in the top bar. Hud sets it before add_child.
@export var compact := false

## Energy the player still needs to afford this defender. 0 = affordable.
var missing_energy := 0
## Seconds left until the card can be used again. 0 = ready.
var cooldown_left := 0.0

@onready var selected_frame: Panel = $SelectedFrame


func _ready() -> void:
	# The picture of the defender, next to the text (no picture if the resource has none).
	icon = defender_type.texture
	if compact:
		custom_minimum_size = COMPACT_SIZE
		add_theme_font_size_override("font_size", COMPACT_FONT_SIZE)
		add_theme_constant_override("icon_max_width", COMPACT_ICON_WIDTH)
	else:
		custom_minimum_size = FULL_SIZE
	_refresh()


func _process(delta: float) -> void:
	# Counts the recharge down. It stops while paused, like the rest of the game.
	if cooldown_left > 0.0:
		cooldown_left = maxf(cooldown_left - delta, 0.0)
		_refresh()


func is_recharging() -> bool:
	return cooldown_left > 0.0


## Game calls this (through Hud) every time the energy changes.
func update_energy(energy: int) -> void:
	missing_energy = maxi(defender_type.cost - energy, 0)
	_refresh()


## Locks the card for defender_type.cooldown seconds, right after placing.
func start_cooldown() -> void:
	cooldown_left = defender_type.cooldown
	_refresh()


func set_selected(value: bool) -> void:
	selected_frame.visible = value


func _refresh() -> void:
	if is_recharging():
		text = "%s\nespera %d s" % [defender_type.display_name, ceili(cooldown_left)]
		modulate = DIMMED
	elif missing_energy > 0:
		text = "%s\nfaltan %d" % [defender_type.display_name, missing_energy]
		modulate = DIMMED
	else:
		text = "%s\n%d" % [defender_type.display_name, defender_type.cost]
		modulate = Color.WHITE
