extends Node
## Autoload (singleton) "ProgressRepository": remembers which level is being played.
## It survives scene changes and reloads because Godot never frees an Autoload.
## For now the progress lives only in memory (Block 4); in Block 5 this same
## node will also save it in user://progress.cfg with ConfigFile.

## The world being played. Its list of levels decides the order.
const WORLD := preload("res://data/worlds/world_1.tres")

## Position of the current level inside WORLD.levels (0 = level 1).
var current_level_index := 0


func get_world() -> WorldData:
	return WORLD


## The LevelData of the level being played.
func get_current_level() -> LevelData:
	return WORLD.levels[current_level_index]


## Number shown to the player: index 0 is "Nivel 1".
func get_current_level_number() -> int:
	return current_level_index + 1


## True if the world still has a level after the current one.
func has_next_level() -> bool:
	return current_level_index + 1 < WORLD.levels.size()


## Game calls this when the player wins the level.
## Moves on to the next level; after the last one, the world is complete
## and the progress goes back to level 1.
func complete_level() -> void:
	if has_next_level():
		current_level_index += 1
	else:
		current_level_index = 0
