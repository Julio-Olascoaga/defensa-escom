class_name InstantDefender
extends Defender
## Ctrl+Z (Block 12): an "instant" card. When it is placed it waits
## trigger_delay seconds (TriggerTimer, so it freezes with the pause), then
## hits every enemy inside a square of area_radius cells around its cell
## (area_radius 1 = 3 x 3 cells) with area_damage, and disappears.
## Every number comes from its DefenderType, so another instant card is only a
## new .tres file with this behavior scene.

## Emitted when it goes off, with how many enemies it hit. Game frees its cell.
signal used(defender: InstantDefender, hits: int)

## Color of the flash that shows the area on the board.
const AREA_COLOR := Color(0.75, 0.55, 1.0, 0.55)
const AREA_FLASH_TIME := 0.45

## true once it went off (it only works once).
var fired := false

@onready var trigger_timer: Timer = $TriggerTimer


func _ready() -> void:
	super()
	trigger_timer.wait_time = maxf(defender_type.trigger_delay, 0.01)
	trigger_timer.one_shot = true
	trigger_timer.timeout.connect(trigger)
	trigger_timer.start()
	if visual:
		visual.play_once("action")  # the key goes down


## True if an enemy at (enemy_lane, enemy_column) is inside the area.
## Lanes are whole numbers; an enemy's column has decimals, and a cell
## covers half a column to each side of its center.
func is_in_area(enemy_lane: int, enemy_column: float) -> bool:
	var radius := defender_type.area_radius
	return absf(enemy_lane - lane) <= radius and absf(enemy_column - column) <= radius + 0.5


## Hits every live enemy in the area and disappears. Enemies created during
## the hit (the halves of a split) are not hit: the list is taken first.
func trigger() -> void:
	if fired:
		return
	fired = true
	var hits := 0
	for enemy: Enemy in get_tree().get_nodes_in_group("enemies").duplicate():
		if is_instance_valid(enemy) and enemy.health > 0.0 and is_in_area(enemy.lane, enemy.column):
			enemy.take_damage(defender_type.area_damage)
			hits += 1
	_flash_area()
	used.emit(self, hits)
	_leave_puppet()
	queue_free()


## A square of light over the area, in the Effects node (it outlives this node).
func _flash_area() -> void:
	var effects := get_tree().get_first_node_in_group("effects")
	if effects == null:
		return
	var half := (defender_type.area_radius + 0.5) * Board.CELL_SIZE
	var flash := Polygon2D.new()
	flash.name = "CtrlZArea"
	flash.polygon = PackedVector2Array([Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	flash.color = AREA_COLOR
	effects.add_child(flash)
	flash.global_position = global_position
	var tween := flash.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, AREA_FLASH_TIME)
	tween.tween_callback(flash.queue_free)
	SparkBurst.spawn(self, global_position, AREA_COLOR, FxLimits.DEBRIS, 260.0, CHIP_TEXTURE)
