class_name ShooterDefender
extends Defender
## Laptop: shoots code at the enemies in its lane.
## Every fire_interval seconds (FireTimer) it checks its lane, and it only shoots
## if there is an enemy in front of it (to its right).

## Emitted with each new projectile. Game adds it to the scene.
signal shot_fired(projectile: Projectile)

const PROJECTILE_SCENE := preload("res://scenes/entities/projectile.tscn")

@onready var fire_timer: Timer = $FireTimer


func _ready() -> void:
	super()  # runs Defender._ready() first (letter or image)
	fire_timer.wait_time = defender_type.fire_interval
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.start()


func _on_fire_timer_timeout() -> void:
	if _enemy_in_lane():
		var projectile: Projectile = PROJECTILE_SCENE.instantiate()
		# It starts at the right edge of the Laptop (cell units, not pixels).
		projectile.setup(lane, column + 0.3, defender_type.projectile_damage)
		shot_fired.emit(projectile)


## True if an enemy is in this lane and to the right of this Laptop.
func _enemy_in_lane() -> bool:
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.lane == lane and enemy.column >= column:
			return true
	return false
