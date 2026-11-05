class_name WorldData
extends Resource
## One world (one semester of the career): its name, its place in the IPN
## and its ordered list of levels (from 6 to 8).
## Adding a level to the world = adding its LevelData file to this list.
## Every field added in 2.0 has a default value, so an old file still works.

## Unique id of the world. ProgressRepository uses it as the section name
## in user://progress.cfg, so do not change it once players have saved progress.
@export var id: String = ""
## Name of the world ("Primer semestre").
@export var display_name: String = ""
## Levels in the order they are played.
@export var levels: Array[LevelData] = []

@export_group("Career map")
## Number of the semester, from 1 to 8.
@export var semester: int = 1
## Place of the IPN where the world happens ("Escuela Superior de Cómputo").
@export var location_name: String = ""
## false = the world is shown on the career map as "Próximamente" and cannot be played.
@export var available: bool = true
## Small picture of the world on the career map (Block 8).
@export var map_icon: Texture2D

@export_group("Look and sound")
## Background of the game screen for every level of this world.
## Empty = the background of game.tscn (the one of the 1.0).
@export var background: Texture2D
## Music played during the levels of this world (Block 11). Empty = silence.
@export var music: AudioStream
## Animated decorations of the world (Block 11): a scene with up to 6
## decorations (pigeons, clouds, leaves, papers, lights) and the foreground.
## Game puts it on top of the background. Empty = no decorations.
@export var scenery: PackedScene

@export_group("Story")
## Conversation shown the first time the world is entered (Block 9).
@export var intro_dialogue: DialogueData
## Conversation shown when the last level of the world is won (Block 9).
@export var outro_dialogue: DialogueData
