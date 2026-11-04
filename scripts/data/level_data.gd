class_name LevelData
extends Resource
## One level: its name, the starting energy, the defenders the player can use
## and its waves. A new level is a new file of this type
## (data/worlds/world_N/levels/), created from the Inspector without touching any script.
## Every field added in 2.0 has a default value, so an old file still works.

## Unique id of the level ("w1_l3"). ProgressRepository saves its best grade
## with this name, so do not change it once players have saved progress.
@export var id: String = ""
## Name shown in the top bar and in the Victory panel ("Inicio de semestre").
@export var display_name: String = ""
## Energy the player has when the level starts.
@export var start_energy: int = 50
## Defenders available in this level. The top bar creates one card for each, in this order.
@export var defenders: Array[DefenderType] = []
## Waves of the level, played in order.
@export var waves: Array[WaveData] = []

@export_group("Look")
## Optional: background only for this level. Empty = the background of its world.
@export var background: Texture2D

@export_group("Story")
## Conversation shown before the first wave (Block 9).
@export var intro_dialogue: DialogueData
## Conversation shown when the level is won (Block 9).
@export var outro_dialogue: DialogueData
## Card the player receives when this level is won (Block 9). Empty = none.
@export var reward_card: DefenderType
## New enemy presented by the Director in this level (Block 9). Empty = none.
@export var featured_enemy: EnemyType

@export_group("Rules")
## true = each lane has an "Extraordinario" that saves it once (Block 8).
## false = the first enemy that reaches the safe zone causes the defeat (rule of the 1.0).
@export var use_extraordinarios: bool = false
## true = the level is the guided tutorial of the Director (Block 9).
@export var is_tutorial: bool = false
