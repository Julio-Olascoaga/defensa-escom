class_name Pigeon
extends Sprite2D
## A pigeon of the scenery (Block 11 decoration). It pecks the floor where it
## stands and, from time to time, flies away across the screen and comes back.
## Everything is done with Tweens of this node, so it freezes with the pause
## and stops by itself when the scene closes.

## Picture standing and picture with the wings open.
@export var stand_texture: Texture2D
@export var fly_texture: Texture2D
## Where it flies away to, relative to its place (a point off the screen).
@export var fly_offset := Vector2(-1400, -150)
## Seconds between two "moments" (pecking or flying).
@export var min_wait := 4.0
@export var max_wait := 9.0
## Chance (0 to 1) that a moment is a flight instead of pecking.
@export var fly_chance := 0.3

## Pecking: degrees it leans down and seconds of each peck.
const PECK_DEGREES := 22.0
const PECK_TIME := 0.12
## Seconds of the flight away (and of the flight back), and of the wait off-screen.
const FLY_TIME := 2.6
const AWAY_TIME := 4.0
## Wing flap: how flat the picture gets and seconds of each flap.
const FLAP_SCALE := 0.55
const FLAP_TIME := 0.09

## The place where it lands.
var home := Vector2.ZERO
## Its normal height (scale.y); the wing flap squashes it and gives it back.
var normal_scale_y := 1.0


func _ready() -> void:
	home = position
	normal_scale_y = scale.y
	texture = stand_texture
	_next_moment()


## Waits a random time, then pecks or flies; at the end it calls itself again.
func _next_moment() -> void:
	var tween := create_tween()
	tween.tween_interval(randf_range(min_wait, max_wait))
	if randf() < fly_chance:
		tween.tween_callback(_fly_away_and_back)
	else:
		tween.tween_callback(_peck)


## Two or three quick nods to the floor.
func _peck() -> void:
	var tween := create_tween()
	for i in randi_range(2, 3):
		tween.tween_property(self, "rotation_degrees", -PECK_DEGREES * _facing(), PECK_TIME)
		tween.tween_property(self, "rotation_degrees", 0.0, PECK_TIME)
	tween.tween_callback(_next_moment)


## Flies off the screen, waits there and comes back to its place.
func _fly_away_and_back() -> void:
	texture = fly_texture
	flip_h = fly_offset.x > 0.0  # the pictures look to the left
	var flap := create_tween().set_loops()
	flap.tween_property(self, "scale:y", normal_scale_y * FLAP_SCALE, FLAP_TIME)
	flap.tween_property(self, "scale:y", normal_scale_y, FLAP_TIME)
	var tween := create_tween()
	tween.tween_property(self, "position", home + fly_offset, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_interval(AWAY_TIME)
	tween.tween_callback(func() -> void: flip_h = not flip_h)  # it comes back looking the other way
	tween.tween_property(self, "position", home, FLY_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_land.bind(flap))


## Back at its place: the wings stop and it stands again.
func _land(flap: Tween) -> void:
	flap.kill()
	scale.y = normal_scale_y
	texture = stand_texture
	flip_h = false
	_next_moment()


## 1 if the pigeon looks to the left (its pictures do), -1 if it is flipped.
## Looking left, the head goes down when it turns to the left (negative degrees).
func _facing() -> float:
	return -1.0 if flip_h else 1.0
