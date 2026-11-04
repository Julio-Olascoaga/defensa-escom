class_name TutorialPointer
extends Node2D
## Animated arrow of the tutorial (Block 9). Its tip is the node's position,
## so pointing at something is only moving the node there. The arrow bobs
## towards its target with a looping Tween.
## Drawn with polygons, so it needs no image file.

## Pixels the arrow moves back and forth, and seconds of each half.
const BOB_PIXELS := 14.0
const BOB_TIME := 0.4

@onready var arrow: Node2D = $Arrow


func _ready() -> void:
	hide()
	var tween := create_tween().set_loops()
	tween.tween_property(arrow, "position:y", -BOB_PIXELS, BOB_TIME).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arrow, "position:y", 0.0, BOB_TIME).set_trans(Tween.TRANS_SINE)


## Puts the tip of the arrow on target (screen pixels).
## from_below = true: the arrow is under the target and points up (used for the cards of the top bar).
func point_at(target: Vector2, from_below := false) -> void:
	position = target
	rotation = PI if from_below else 0.0
	show()
