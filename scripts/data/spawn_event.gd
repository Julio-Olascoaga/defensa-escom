class_name SpawnEvent
extends Resource
## One enemy appearing in a wave: WHEN, in WHICH lane and WHAT enemy.
## A WaveData is just a list of these events.

## Second at which the enemy appears, counted from the start of its wave
## (after the wave's start_delay).
@export var time: float = 0.0
## Lane where it appears, from 0 (top) to 4 (bottom).
@export_range(0, 4) var lane: int = 0
## Which enemy appears (a file from data/enemies/).
@export var enemy_type: EnemyType
