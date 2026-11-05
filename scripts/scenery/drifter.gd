extends Sprite2D
## Something of the scenery that slides slowly across the screen and, when it
## leaves by one side, comes back by the other (Block 11 decoration).
## Used for the shadows of the clouds passing over the explanada.

## Pixels per second (positive = to the right).
@export var speed := 18.0
## Width of the screen of the game, in pixels.
@export var screen_width := 1280.0


func _process(delta: float) -> void:
	position.x += speed * delta
	var half_width := texture.get_width() * absf(scale.x) / 2.0
	if speed > 0.0 and position.x - half_width > screen_width:
		position.x = -half_width  # it left by the right: back to the left edge
	elif speed < 0.0 and position.x + half_width < 0.0:
		position.x = screen_width + half_width
