extends Node
## Autoload (singleton) "GameSession": loads the campaign (data/campaign.tres)
## and remembers which world and which level the player chose.
## Game, the loading screen and the menus ask it what to play.
## It does not save anything: ProgressRepository is the one that writes in user://.

const LOADING_SCENE := "res://scenes/ui/loading_screen.tscn"

## The 8 semesters, in order.
var campaign: CampaignData = preload("res://data/campaign.tres")
## Position of the chosen world inside campaign.worlds (0 = first semester).
var world_index := 0
## Position of the chosen level inside the world's levels (0 = level 1).
var level_index := 0


func current_world() -> WorldData:
	return campaign.worlds[world_index]


## The LevelData being played (null if the world file has an empty slot).
func current_level() -> LevelData:
	return current_world().levels[level_index]


## Number shown to the player: index 0 is "Nivel 1".
func current_level_number() -> int:
	return level_index + 1


## True if the current world still has a level after the current one.
func has_next_level() -> bool:
	return level_index + 1 < current_world().levels.size()


## Chooses a level and opens the loading screen, which loads it.
func start_level(world: int, level: int) -> void:
	world_index = world
	level_index = level
	SceneTransition.change_scene(LOADING_SCENE)


## "Siguiente nivel" on the Victory panel.
func start_next_level() -> void:
	start_level(world_index, level_index + 1)


## "Jugar" / "Continuar" on Inicio. Until the career map exists (Block 8)
## it plays the saved level of the first world.
func continue_game() -> void:
	start_level(0, ProgressRepository.get_current_level(campaign.worlds[0]) - 1)


## Game calls it when the level is won. It saves the result and returns
## the error of the save so Game can show the notice.
func complete_current_level(grade: int) -> Error:
	return ProgressRepository.complete_level(current_world(), level_index, grade)
