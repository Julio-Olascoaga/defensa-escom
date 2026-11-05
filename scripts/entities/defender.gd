class_name Defender
extends Node2D
## Base script for every defender: its data, its cell, health, damage and death.
## GeneratorDefender, ShooterDefender and BlockerDefender inherit from it.
## The node is placed at the center of its cell; Game does that conversion with Board.
##
## Block 10: if its DefenderType has a visual_scene, the cut-out puppet
## (CharacterVisual) is created inside the Visual node and plays idle / action /
## hit / die; otherwise the fixed image of the 1.0 is used, as before.
## Progressive damage: the puppet shows 3 stages by health (see stage_for()).

## Emitted when health reaches 0, so Game can free the cell on the Board.
signal died(defender: Defender)

## Size of the placeholder circle, in pixels (a cell is 120 px).
const CIRCLE_RADIUS := 46.0
## Width of the final image on the board, in pixels (a cell is 120 px).
const SPRITE_SIZE := 110.0
## Shake when an enemy bites it: pixels to each side, seconds of each move,
## and a short rest before the next shake (bites arrive every frame).
const SHAKE_PIXELS := 4.0
const SHAKE_STEP := 0.05
const SHAKE_REST := 0.25
## Damage stages (Block 10): above STAGE_DAMAGED_RATIO of its health it is
## intact (0), down to STAGE_CRITICAL_RATIO damaged (1), below that critical (2).
const STAGE_DAMAGED_RATIO := 0.66
const STAGE_CRITICAL_RATIO := 0.33
## Shake when it goes to a worse stage: stronger than the shake of each bite.
const STAGE_SHAKE_PIXELS := 10.0
const PUFF_TEXTURE := preload("res://art/fx/puff.png")
const CHIP_TEXTURE := preload("res://art/fx/chip.png")

var defender_type: DefenderType
var lane := 0
var column := 0
var health := 0.0
var shake_tween: Tween
## The animated puppet, or null if this defender uses the fixed image of the 1.0.
var visual: CharacterVisual
## 0 intact, 1 damaged, 2 critical. It only goes up.
var damage_stage := 0
## Continuous smoke of the critical stage (created when it gets there).
var smoke: CPUParticles2D

@onready var sprite: Sprite2D = $Sprite
@onready var letter_label: Label = $Letter
@onready var visual_root: Node2D = $Visual


## Game calls this right after instantiate() and BEFORE add_child(),
## so the data is ready when _ready() runs.
func setup(type: DefenderType, cell_lane: int, cell_column: int) -> void:
	defender_type = type
	lane = cell_lane
	column = cell_column
	health = type.health


func _ready() -> void:
	if defender_type.visual_scene:
		# Cut-out puppet (Block 10): drawn in the pixels of its art, scaled to the cell.
		visual = defender_type.visual_scene.instantiate()
		visual_root.add_child(visual)
		visual.scale = Vector2.ONE * SPRITE_SIZE / visual.design_width
		visual.play("idle")
		sprite.hide()
		letter_label.hide()
	elif defender_type.texture:
		# Final art (Block 6): show the image and hide the letter.
		sprite.texture = defender_type.texture
		# The PNG is bigger (256 px) so it looks sharp on phones; scale it to fit the cell.
		sprite.scale = Vector2.ONE * SPRITE_SIZE / defender_type.texture.get_width()
		letter_label.hide()
	else:
		# Placeholder: the first letter of the name (C, L, F) over a colored circle.
		letter_label.text = defender_type.display_name.left(1)


func _draw() -> void:
	if defender_type.texture == null and defender_type.visual_scene == null:
		draw_circle(Vector2.ZERO, CIRCLE_RADIUS, defender_type.color)


## Enemies call this every frame while they bite the defender.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return  # already dead, ignore extra hits in the same frame
	health -= amount
	if _shake() and visual:
		visual.play_once("hit")
	_update_damage_stage()
	if health <= 0.0:
		_leave_puppet()
		died.emit(self)
		queue_free()


## Stage for a fraction of health (1.0 = full): 0 intact, 1 damaged, 2 critical.
static func stage_for(health_ratio: float) -> int:
	if health_ratio > STAGE_DAMAGED_RATIO:
		return 0
	if health_ratio >= STAGE_CRITICAL_RATIO:
		return 1
	return 2


## Goes to a worse stage when the health crosses a threshold: the pieces change
## frame, some bits fall, it shakes harder and, when critical, it smokes.
## Only with a puppet; the fixed image of the 1.0 has no stages.
func _update_damage_stage() -> void:
	if visual == null or health <= 0.0:
		return
	var stage := stage_for(health / defender_type.health)
	if stage <= damage_stage:
		return
	damage_stage = stage
	visual.set_damage_stage(stage)
	var burst := SparkBurst.spawn(self, global_position, defender_type.color, FxLimits.DEBRIS, 170.0, CHIP_TEXTURE)
	if burst:
		burst.scale_amount_min = 0.35
		burst.scale_amount_max = 0.7
	var tween := create_tween()
	for i in 3:
		tween.tween_property(visual_root, "position:x", STAGE_SHAKE_PIXELS, SHAKE_STEP * 0.6)
		tween.tween_property(visual_root, "position:x", -STAGE_SHAKE_PIXELS, SHAKE_STEP * 0.6)
	tween.tween_property(visual_root, "position:x", 0.0, SHAKE_STEP * 0.6)
	if stage == 2 and smoke == null:
		_start_smoke()


func _start_smoke() -> void:
	smoke = CPUParticles2D.new()
	smoke.name = "Smoke"
	smoke.amount = FxLimits.SMOKE
	smoke.lifetime = 1.4
	smoke.texture = PUFF_TEXTURE
	smoke.position = Vector2(0, -SPRITE_SIZE * 0.3)
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	smoke.emission_sphere_radius = 14.0
	smoke.direction = Vector2(0, -1)
	smoke.spread = 20.0
	smoke.gravity = Vector2(6, -30)
	smoke.initial_velocity_min = 15.0
	smoke.initial_velocity_max = 35.0
	smoke.scale_amount_min = 0.4
	smoke.scale_amount_max = 0.8
	var fade := Gradient.new()
	fade.set_color(0, Color(0.3, 0.28, 0.3, 0.55))
	fade.set_color(1, Color(0.3, 0.28, 0.3, 0.0))
	smoke.color_ramp = fade
	add_child(smoke)


## The defender is freed at once (the Board and the rules do not wait), but its
## puppet moves to the Effects node and falls apart there.
func _leave_puppet() -> void:
	var effects := get_tree().get_first_node_in_group("effects")
	if visual == null or effects == null:
		return
	visual.reparent(effects)
	visual.die(true)
	visual = null


## Small shake to the sides; it does nothing if the last shake has not finished.
## Returns true if a new shake started (the puppet plays "hit" at the same pace).
func _shake() -> bool:
	if shake_tween and shake_tween.is_running():
		return false
	var center_x := position.x  # the center of its cell, in pixels
	shake_tween = create_tween()
	shake_tween.tween_property(self, "position:x", center_x + SHAKE_PIXELS, SHAKE_STEP)
	shake_tween.tween_property(self, "position:x", center_x - SHAKE_PIXELS, SHAKE_STEP)
	shake_tween.tween_property(self, "position:x", center_x, SHAKE_STEP)
	shake_tween.tween_interval(SHAKE_REST)
	return true
