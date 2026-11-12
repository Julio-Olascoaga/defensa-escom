class_name Enemy
extends Node2D
## The ONE scene for every enemy. Its stats come from the EnemyType it receives.
## It walks left along its lane in cells per second, stops at the first defender
## in front of it and bites it (damage per second) until the defender dies.
## All the logic uses cells; pixels are only used to draw the node.
##
## Block 10: if its EnemyType has a visual_scene, the cut-out puppet
## (CharacterVisual) is created inside the Visual node and plays walk / attack /
## hit / die (the legs move faster when it walks faster); otherwise the fixed
## image of the 1.0 sways as before. The white hit flash is the same for both.
##
## Block 12 abilities, all read from the EnemyType: armor (armor_health is
## spent before the health), split (when it dies, split_count enemies of
## split_into appear in its column, asked for with summon_requested like the
## boss's summons), jump (the first defender it meets is jumped over: one
## column forward, with a Tween), a boss's phase 2 summon (phase2_summon_type)
## and the "lag" of the Router lento (apply_slow()).

## Emitted when health reaches 0.
signal died(enemy: Enemy)
## Emitted when the enemy enters the safe zone: the player loses.
signal reached_safe_zone(enemy: Enemy)
## Emitted every time it loses health. Game uses it for the boss health bar.
signal damaged(enemy: Enemy)
## The boss asks for a new enemy in a lane, at a column. Game creates it
## (the same way WaveManager asks for enemies with spawn_requested).
## A splitting enemy uses it too when it dies (Block 12).
signal summon_requested(enemy_type: EnemyType, lane: int, column: float)
## Its armor (EnemyType.armor_health) has just run out: the armor piece falls.
signal armor_broken(enemy: Enemy)
## Only bosses: the health went down to PHASE2_HEALTH_RATIO (phase 2).
signal phase_changed(enemy: Enemy)
## It jumped over a defender (EnemyType.jumps_first_defender, Block 12).
signal jumped(enemy: Enemy, over: Defender)

## Column where enemies appear: just right of the board, in the entry area.
const SPAWN_COLUMN := 9.0
## The safe zone starts at the left edge of column 0 (cell centers are whole numbers).
const SAFE_ZONE_COLUMN := -0.5
## How close (in columns) to a defender's center the enemy stops to bite it.
const BITE_DISTANCE := 0.7
## Size of the placeholder box, in pixels (a cell is 120 px).
const BOX_SIZE := Vector2(92, 92)
const BORDER_COLOR := Color("7a1f45")
## Hit flash: color values above 1 make the image brighter, almost white.
const FLASH_COLOR := Color(3, 3, 3)
## Seconds the flash takes to go back to the normal colors.
const FLASH_TIME := 0.1
## Walking sway: degrees to each side and seconds of each swing.
const SWAY_DEGREES := 4.0
const SWAY_TIME := 0.35
## Sparks when it dies. A normal enemy (110 px) gets DEATH_SPARKS; the boss, more.
const DEATH_SPARK_COLOR := Color("f2b33d")
const DEATH_SPARKS := 16
## Seconds between two bite sounds while it bites a defender (Block 11).
## Bites hurt every frame; the sound would be noise if it followed them.
const BITE_SOUND_TIME := 0.6
## Paper bits when a puppet dies (Block 10).
const PAPER_COLOR := Color("f4ecd8")
const CHIP_TEXTURE := preload("res://art/fx/chip.png")
## A boss enters phase 2 at this fraction of its health.
const PHASE2_HEALTH_RATIO := 0.5
## Phase 2 look: the puppet turns red and a bit bigger, with its cracked frames.
const PHASE2_TINT := Color(1.35, 0.8, 0.8)
const PHASE2_SCALE := 1.12
## Name of the puppet piece that falls when the armor runs out.
const ARMOR_PIECE := "Armor"
## Jump over the first defender: columns forward (to the left), seconds in the
## air and how high it goes, in pixels.
const JUMP_COLUMNS := 1.0
const JUMP_TIME := 0.5
const JUMP_HEIGHT := 70.0
## The halves of a split appear this many columns apart, so they do not overlap.
const SPLIT_SPACING := 0.35
## While slowed down by the Router lento ("lag") the enemy is tinted blue.
const SLOW_TINT := Color(0.6, 0.8, 1.35)

var enemy_type: EnemyType
var lane := 0
## Position along the lane, in cells. It has decimals: 6.4 = between cells 6 and 7.
var column := SPAWN_COLUMN
var health := 0.0
## Armor left (EnemyType.armor_health). It takes the damage before the health.
var armor := 0.0
## Multiplies EnemyType.speed (phase 2 of a boss; slow-downs from Block 12).
var speed_multiplier := 1.0
## true once a boss has entered phase 2.
var in_phase2 := false
## Router lento (Block 12): speed multiplier of the "lag" and seconds left.
## It does not add up: a new hit only refreshes the time (and keeps the slowest).
var slow_multiplier := 1.0
var slow_left := 0.0
## true once it used its jump (jumps_first_defender), and while it is in the air.
var has_jumped := false
var jumping := false
## Seconds since the last summon. Only enemies with a summon_type use it.
var summon_time := 0.0
## Seconds left until the next bite sound (0 = it sounds at the first bite).
var bite_sound_left := 0.0
## The Board, used to find defenders and to convert cells to pixels.
var board: Board
## Animations made with Tween (created in code, they stop when the game is paused).
var flash_tween: Tween
var sway_tween: Tween
## The animated puppet, or null if this enemy uses the fixed image of the 1.0.
var visual: CharacterVisual

@onready var sprite: Sprite2D = $Sprite
@onready var text_label: Label = $Text
@onready var visual_root: Node2D = $Visual


## Game calls this right after instantiate() and BEFORE add_child().
## Normal enemies start at SPAWN_COLUMN; the boss's summons start at the boss's column.
func setup(type: EnemyType, enemy_lane: int, game_board: Board, start_column: float = SPAWN_COLUMN) -> void:
	enemy_type = type
	lane = enemy_lane
	column = start_column
	board = game_board
	health = type.health
	armor = type.armor_health


func _ready() -> void:
	# The group lets Laptops and projectiles find every enemy alive.
	add_to_group("enemies")
	if enemy_type.visual_scene:
		# Cut-out puppet (Block 10), scaled to the size in its EnemyType.
		visual = enemy_type.visual_scene.instantiate()
		visual_root.add_child(visual)
		visual.scale = Vector2.ONE * enemy_type.sprite_size / visual.design_width
		visual.play("walk")
		sprite.hide()
		text_label.hide()
	elif enemy_type.texture:
		sprite.texture = enemy_type.texture
		# The PNG is bigger so it looks sharp on phones; scale it to the size in its EnemyType.
		sprite.scale = Vector2.ONE * enemy_type.sprite_size / enemy_type.texture.get_width()
		text_label.hide()
	else:
		text_label.text = enemy_type.label_text
	if visual == null:
		_start_sway()  # the look of the 1.0; the puppet has its own walk cycle
	_update_position()


func _process(delta: float) -> void:
	_update_slow(delta)
	if jumping:
		_update_summon(delta)
		_update_position()
		return  # the jump Tween moves it; it does not bite in the air
	var defender := _defender_in_front()
	if defender and enemy_type.jumps_first_defender and not has_jumped:
		_jump_over(defender)
		_update_position()
		return
	if defender:
		defender.take_damage(enemy_type.damage_per_second * delta)  # bite
		_animate(false)
		bite_sound_left -= delta
		if bite_sound_left <= 0.0:
			AudioManager.play_sfx_varied(AudioManager.SFX_BITE)
			bite_sound_left = BITE_SOUND_TIME
	else:
		column -= current_speed() * delta  # walk left (cells per second)
		bite_sound_left = 0.0  # the next defender gets its first bite sound at once
		_animate(true)
	_update_summon(delta)

	if column <= SAFE_ZONE_COLUMN:
		reached_safe_zone.emit(self)
		set_process(false)  # stop here; Game shows the defeat panel
	_update_position()


## Cells per second it walks now.
func current_speed() -> float:
	return enemy_type.speed * speed_multiplier * slow_multiplier


## Router lento: walks at factor of its speed for seconds. Hits do not add up:
## the slowest factor is kept and the time starts again.
func apply_slow(factor: float, seconds: float) -> void:
	if health <= 0.0 or seconds <= 0.0 or factor >= 1.0:
		return
	slow_multiplier = minf(slow_multiplier, factor) if slow_left > 0.0 else factor
	slow_left = seconds
	visual_root.modulate = SLOW_TINT  # the puppet or the image (and the box of a placeholder)
	sprite.modulate = SLOW_TINT


func is_slowed() -> bool:
	return slow_left > 0.0


func _update_slow(delta: float) -> void:
	if slow_left <= 0.0:
		return
	slow_left -= delta
	if slow_left <= 0.0:
		slow_left = 0.0
		slow_multiplier = 1.0
		visual_root.modulate = Color.WHITE
		sprite.modulate = Color.WHITE


## El Retardo: the first defender it meets is jumped over. It lands one
## column further (on the far side of the defender) and walks on; the next
## defender it meets is bitten as usual.
func _jump_over(defender: Defender) -> void:
	has_jumped = true
	jumping = true
	var landing := defender.column - JUMP_COLUMNS
	var tween := create_tween()
	tween.tween_property(self, "column", landing, JUMP_TIME).set_trans(Tween.TRANS_SINE)
	var arc := create_tween()
	arc.tween_property(visual_root, "position:y", -JUMP_HEIGHT, JUMP_TIME / 2.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	arc.tween_property(visual_root, "position:y", 0.0, JUMP_TIME / 2.0).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func() -> void: jumping = false)
	if visual:
		visual.play_once("jump")  # a puppet without "jump" keeps walking
	jumped.emit(self, defender)


## Walking or biting. The puppet's walk cycle runs at walk_speed_scale(), so a
## fast enemy moves its legs fast; the 1.0 sway only stops while biting.
func _animate(walking: bool) -> void:
	if visual:
		visual.play("walk" if walking else "attack")
		visual.anim.speed_scale = walk_speed_scale() if walking else 1.0
	elif sway_tween == null:
		return  # its puppet already left (it died this frame)
	elif walking:
		sway_tween.play()
	else:
		sway_tween.pause()  # stands still while biting


## anim.speed_scale of the walk: current speed / the speed the cycle was animated for.
func walk_speed_scale() -> float:
	if visual == null or visual.walk_base_speed <= 0.0:
		return 1.0
	return current_speed() / visual.walk_base_speed


## Returns the defender this enemy is touching, or null.
## ceili() gives the nearest cell whose center is at most BITE_DISTANCE ahead of us.
func _defender_in_front() -> Defender:
	var front_column := ceili(column - BITE_DISTANCE)
	return board.get_defender(lane, front_column)


## The boss's ability: every summon_interval seconds it calls summon_type
## in the lane above and in the lane below (only the lanes that exist).
func _update_summon(delta: float) -> void:
	if enemy_type.summon_type == null:
		return  # normal enemies never summon
	summon_time += delta
	if summon_time < enemy_type.summon_interval:
		return
	summon_time = 0.0
	for summon_lane in [lane - 1, lane + 1]:
		if summon_lane >= 0 and summon_lane < Board.LANES:
			summon_requested.emit(current_summon_type(), summon_lane, column)


## What it calls now: phase2_summon_type from phase 2 on, if it has one.
func current_summon_type() -> EnemyType:
	if in_phase2 and enemy_type.phase2_summon_type:
		return enemy_type.phase2_summon_type
	return enemy_type.summon_type


## Split: split_count enemies of split_into appear in its column ("los que no
## trabajaron"), a little apart, asked for with the summon signal of the boss.
func _split() -> void:
	if enemy_type.split_into == null or enemy_type.split_count <= 0:
		return
	for i in enemy_type.split_count:
		var offset := (i - (enemy_type.split_count - 1) / 2.0) * SPLIT_SPACING
		summon_requested.emit(enemy_type.split_into, lane, maxf(column + offset, SAFE_ZONE_COLUMN + 0.1))


## Laptop projectiles call this.
func take_damage(amount: float) -> void:
	if health <= 0.0:
		return  # already dead, ignore extra hits in the same frame
	if armor > 0.0:
		# The armor takes the hit first; what is left over goes to the health.
		armor -= amount
		amount = maxf(0.0, -armor)
		if armor <= 0.0:
			armor = 0.0
			armor_broken.emit(self)
			if visual:
				visual.drop_piece(ARMOR_PIECE)
	health -= amount
	damaged.emit(self)
	_flash()
	if visual:
		visual.play_once("hit")
	_check_phase2()
	if health <= 0.0:
		var size_factor := enemy_type.sprite_size / 110.0  # the boss explodes bigger
		var sparks := mini(roundi(DEATH_SPARKS * size_factor), FxLimits.DEATH_SPARKS_MAX)
		SparkBurst.spawn(self, global_position, DEATH_SPARK_COLOR, sparks, 260.0 * size_factor)
		if visual:
			var bits := SparkBurst.spawn(self, global_position, PAPER_COLOR, FxLimits.PAPER_BITS, 180.0 * size_factor, CHIP_TEXTURE)
			if bits:
				bits.scale_amount_min = 0.4
				bits.scale_amount_max = 0.8
			_leave_puppet()
		AudioManager.play_sfx_varied(AudioManager.SFX_DIE)
		_split()  # before it leaves, so the wave never looks empty
		died.emit(self)
		queue_free()


## Bosses: at PHASE2_HEALTH_RATIO of their health they enter phase 2, once:
## faster if EnemyType.phase2_speed_multiplier says so, cracked, red and bigger.
func _check_phase2() -> void:
	if not enemy_type.is_boss or in_phase2 or health <= 0.0:
		return
	if health > enemy_type.health * PHASE2_HEALTH_RATIO:
		return
	in_phase2 = true
	speed_multiplier = enemy_type.phase2_speed_multiplier
	if visual:
		visual.set_damage_stage(1)
		var tween := visual.create_tween().set_parallel()
		tween.tween_property(visual, "modulate", PHASE2_TINT, 0.4)
		tween.tween_property(visual, "scale", visual.scale * PHASE2_SCALE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		sprite.self_modulate = PHASE2_TINT
	phase_changed.emit(self)


## The enemy is freed at once (the rules do not wait), but its puppet moves to
## the Effects node and falls backwards there (CharacterVisual.die()).
func _leave_puppet() -> void:
	var effects := get_tree().get_first_node_in_group("effects")
	if effects == null:
		return
	visual.reparent(effects)
	visual.die(false)
	visual = null


## Hit flash: the enemy turns white and goes back to its colors in FLASH_TIME seconds.
func _flash() -> void:
	if flash_tween:
		flash_tween.kill()  # a new hit restarts the flash
	modulate = FLASH_COLOR
	flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, FLASH_TIME)


## Walking sway: the image tilts left and right forever (set_loops with no number).
func _start_sway() -> void:
	sway_tween = create_tween().set_loops()
	sway_tween.tween_property(sprite, "rotation_degrees", SWAY_DEGREES, SWAY_TIME).set_trans(Tween.TRANS_SINE)
	sway_tween.tween_property(sprite, "rotation_degrees", -SWAY_DEGREES, SWAY_TIME).set_trans(Tween.TRANS_SINE)


## Cells -> pixels, only to draw the node on screen.
func _update_position() -> void:
	global_position = board.cell_to_pixel(lane, column)


func _draw() -> void:
	if enemy_type.texture == null and enemy_type.visual_scene == null:
		var box := Rect2(-BOX_SIZE / 2.0, BOX_SIZE)
		draw_rect(box, enemy_type.color)
		draw_rect(box, BORDER_COLOR, false, 4.0)
