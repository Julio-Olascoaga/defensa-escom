class_name WorldData
extends Resource
## One world: its name and its ordered list of levels.
## Adding a level to the world = adding its LevelData file to this list.

## Name of the world ("Mundo 1").
@export var display_name: String = ""
## Levels in the order they are played.
@export var levels: Array[LevelData] = []
