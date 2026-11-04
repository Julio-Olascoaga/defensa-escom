class_name SparkBurst
extends CPUParticles2D
## One-shot burst of sparks (art/fx/spark.png is white, so "color" tints it).
## It frees itself when its particles end. Bursts live in the game's Effects node
## (group "effects"), never inside Enemies or Projectiles.
## Projectile creates a small blue one on each hit; Enemy a gold one when it dies.
## Block 10: also paper bits, code bits and falling pieces, with another texture.

const SCENE_PATH := "res://scenes/fx/spark_burst.tscn"


## Creates a burst at a global position (pixels, it is only drawing).
## from = the node that asks for it (any node of the game scene).
## count = number of sparks; speed = how fast they fly out, in pixels per second.
## texture_override = another white image instead of the spark (optional).
## Cap (Block 10): if FxLimits.MAX_BURSTS bursts are already alive, nothing is
## created and it returns null; otherwise it returns the burst, to adjust it.
static func spawn(from: Node, at: Vector2, tint: Color, count: int, speed: float, texture_override: Texture2D = null) -> SparkBurst:
	var effects := from.get_tree().get_first_node_in_group("effects")
	if effects == null:
		return null
	var alive := 0
	for child in effects.get_children():
		if child is SparkBurst:
			alive += 1
	if alive >= FxLimits.MAX_BURSTS:
		return null
	var burst: SparkBurst = load(SCENE_PATH).instantiate()
	if texture_override:
		burst.texture = texture_override
	burst.color = tint
	burst.amount = count
	burst.initial_velocity_min = speed * 0.5
	burst.initial_velocity_max = speed
	effects.add_child(burst)
	burst.global_position = at
	burst.emitting = true  # after placing it, so no spark starts at (0, 0)
	return burst


func _ready() -> void:
	finished.connect(queue_free)
