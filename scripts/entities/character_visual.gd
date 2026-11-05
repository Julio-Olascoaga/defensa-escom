class_name CharacterVisual
extends Node2D
## Cut-out puppet of a character (Block 10). Each scenes/visuals/*_visual.tscn
## has this script on its root: a "Rig" with one Sprite2D per piece (arms,
## legs, lid...) placed on its pivot (shoulder, hip, laptop hinge) and an
## AnimationPlayer with the animations of the character.
##
## Fixed animation names, so every Enemy and Defender can use any puppet:
##   enemies:   idle, walk, attack, hit, die
##   defenders: idle, action, hit, die
## A puppet that lacks one of them simply does not play it.
##
## Damage: every piece is a strip of 3 frames (intact, damaged, critical) made
## by tools/cut_parts.py, so the Sprite2D has hframes = 3 and
## set_damage_stage() only changes the frame.
##
## The puppet is drawn in the pixels of its source art (design_width wide);
## Enemy and Defender scale it to their size on the board.

## Emitted when the death animation ends, right before the puppet frees itself.
signal death_finished

## Frames of every piece: intact, damaged, critical.
const DAMAGE_FRAMES := 3
## Death: seconds the pieces take to fall and fade, and how far they fall (source pixels).
const DIE_FADE_TIME := 0.8
const DIE_FALL_PIXELS := 160.0

## Width of the source art in pixels (256 for the 1.0 characters, 512 for the boss).
@export var design_width := 256.0
## Enemies: walking speed (cells per second) the "walk" cycle was animated for.
## Enemy sets anim.speed_scale = its speed / walk_base_speed, so faster enemies
## move their legs faster.
@export var walk_base_speed := 0.25

## Animation to come back to after a one-shot (hit, action): "idle", "walk"...
var base_animation := ""
## true while a one-shot animation is playing.
var one_shot_playing := false
var damage_stage := 0
var dying := false

@onready var anim: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	anim.animation_finished.connect(_on_animation_finished)


## Loop or state animation (idle, walk, attack). It does nothing if the puppet
## does not have it or if it is already the current one (it is called every frame).
## While a one-shot plays, it is remembered and starts when the one-shot ends.
func play(anim_name: String) -> void:
	if dying:
		return
	base_animation = anim_name
	if one_shot_playing:
		return
	if anim.has_animation(anim_name) and anim.current_animation != anim_name:
		_switch_to(anim_name)


## Short animation (hit, action) that goes back to base_animation when it ends.
## It is not restarted if it is already playing (bites arrive every frame).
func play_once(anim_name: String) -> void:
	if dying or not anim.has_animation(anim_name):
		return
	if one_shot_playing and anim.current_animation == anim_name:
		return
	one_shot_playing = true
	_switch_to(anim_name)


## Puts every piece back in its rest pose (the "RESET" animation) and starts
## another animation from its first key, so no piece keeps a pose of the old one.
func _switch_to(anim_name: String) -> void:
	anim.stop()
	if anim.has_animation(&"RESET"):
		anim.play(&"RESET")
		anim.advance(0.0)
		anim.stop()
	anim.play(anim_name)


func has_animation(anim_name: String) -> bool:
	return anim.has_animation(anim_name)


## 0 = intact, 1 = damaged, 2 = critical. Sets that frame on every piece
## made of 3 frames (pieces without damage frames are left alone).
func set_damage_stage(stage: int) -> void:
	damage_stage = clampi(stage, 0, DAMAGE_FRAMES - 1)
	for piece in get_pieces():
		piece.frame = damage_stage


## Every Sprite2D of the puppet with the 3 damage frames, at any depth.
func get_pieces() -> Array[Sprite2D]:
	var pieces: Array[Sprite2D] = []
	_collect_pieces(self, pieces)
	return pieces


func _collect_pieces(node: Node, pieces: Array[Sprite2D]) -> void:
	for child in node.get_children():
		if child is Sprite2D and child.hframes == DAMAGE_FRAMES:
			pieces.append(child)
		_collect_pieces(child, pieces)


## A piece by its node name (for example "Armor"), or null.
func get_piece(piece_name: String) -> Sprite2D:
	for piece in get_pieces():
		if piece.name == piece_name:
			return piece
	return null


## Drops one piece (the armor of an armored enemy): it falls spinning and fades.
func drop_piece(piece_name: String) -> void:
	var piece := get_piece(piece_name)
	if piece == null or not piece.visible:
		return
	var tween := create_tween().set_parallel()
	tween.tween_property(piece, "position", piece.position + Vector2(randf_range(30, 70), DIE_FALL_PIXELS), DIE_FADE_TIME)
	tween.tween_property(piece, "rotation", piece.rotation + randf_range(2.0, 4.0), DIE_FADE_TIME)
	tween.tween_property(piece, "modulate:a", 0.0, DIE_FADE_TIME)
	tween.chain().tween_callback(piece.hide)


## Death. The entity is already gone: Enemy and Defender move their puppet to
## the Effects node before freeing themselves, so the animation can be seen.
## Plays "die" and then, if disassemble is true (defenders), the pieces fall
## apart spinning; enemies only fade after falling backwards. Frees itself.
func die(disassemble: bool) -> void:
	if dying:
		return
	dying = true  # from now on play() and play_once() do nothing
	one_shot_playing = false
	if anim.has_animation("die"):
		_switch_to("die")
		await anim.animation_finished
	var tween := create_tween().set_parallel()
	if disassemble:
		for piece in get_pieces():
			var side := -1.0 if piece.global_position.x < global_position.x else 1.0
			tween.tween_property(piece, "position", piece.position + Vector2(side * randf_range(20, 80), DIE_FALL_PIXELS), DIE_FADE_TIME).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
			tween.tween_property(piece, "rotation", piece.rotation + side * randf_range(2.0, 5.0), DIE_FADE_TIME)
	tween.tween_property(self, "modulate:a", 0.0, DIE_FADE_TIME).set_ease(Tween.EASE_IN)
	await tween.finished
	death_finished.emit()
	queue_free()


func _on_animation_finished(anim_name: StringName) -> void:
	if dying or anim_name == &"die" or anim_name == &"RESET":
		return
	if one_shot_playing:
		one_shot_playing = false
		var next := base_animation
		base_animation = ""
		play(next)
