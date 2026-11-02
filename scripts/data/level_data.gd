class_name LevelData
extends Resource
## One level: its name, the starting energy, the defenders the player can use
## and its waves. A new level is a new file of this type (data/worlds/levels/),
## created from the Inspector without touching any script.

## Name shown in the top bar and in the Victory panel ("Inicio de semestre").
@export var display_name: String = ""
## Energy the player has when the level starts.
@export var start_energy: int = 50
## Defenders available in this level. The top bar creates one card for each, in this order.
@export var defenders: Array[DefenderType] = []
## Waves of the level, played in order.
@export var waves: Array[WaveData] = []
