extends Sprite2D
## A branch or plant that moves with the wind: it turns a few degrees to each
## side, forever (Block 11 decoration). It turns around its position, so in the
## scene the picture is placed with "offset" so that its base is at the position.

## Degrees to each side and seconds of each half of the movement.
@export var degrees := 3.0
@export var time := 2.2


func _ready() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(self, "rotation_degrees", degrees, time).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "rotation_degrees", -degrees, time).set_trans(Tween.TRANS_SINE)
