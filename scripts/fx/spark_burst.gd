class_name SparkBurst
extends CPUParticles2D
## One-shot burst of sparks (art/fx/spark.png is white, so "color" tints it).
## It frees itself when its particles end. Bursts live in the game's Effects node
## (group "effects"), never inside Enemies or Projectiles.
## Projectile creates a small blue one on each hit; Enemy a gold one when it dies.

const SCENE_PATH := "res://scenes/fx/spark_burst.tscn"


## Creates a burst at a global position (pixels, it is only drawing).
## from = the node that asks for it (any node of the game scene).
## count = number of sparks; speed = how fast they fly out, in pixels per second.
static func spawn(from: Node, at: Vector2, tint: Color, count: int, speed: float) -> void:
	var effects := from.get_tree().get_first_node_in_group("effects")
	var burst: SparkBurst = load(SCENE_PATH).instantiate()
	burst.color = tint
	burst.amount = count
	burst.initial_velocity_min = speed * 0.5
	burst.initial_velocity_max = speed
	effects.add_child(burst)
	burst.global_position = at
	burst.emitting = true  # after placing it, so no spark starts at (0, 0)


func _ready() -> void:
	finished.connect(queue_free)
