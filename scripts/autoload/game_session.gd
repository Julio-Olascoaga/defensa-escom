extends Node
## Autoload (singleton) "GameSession": loads the campaign (data/campaign.tres),
## remembers which world and which level the player chose, and knows the
## rules of the career: which worlds and levels are open and how a level is graded.
## The menus, the loading screen and Game ask it what to play.
## It does not save anything: ProgressRepository is the one that writes in user://.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const CAREER_MAP_SCENE := "res://scenes/ui/career_map.tscn"
const LEVEL_SELECT_SCENE := "res://scenes/ui/level_select.tscn"
const WORLD_COMPLETE_SCENE := "res://scenes/ui/world_complete.tscn"
const SETTINGS_SCENE := "res://scenes/ui/settings.tscn"
const EXPEDIENTE_SCENE := "res://scenes/ui/expediente.tscn"
const LOADING_SCENE := "res://scenes/ui/loading_screen.tscn"

## Grade of a level won without using any Extraordinario.
const MAX_GRADE := 10
## Lowest passing grade: using many Extraordinarios never goes below it.
const MIN_GRADE := 6

## The 8 semesters, in order.
var campaign: CampaignData = preload("res://data/campaign.tres")
## Position of the chosen world inside campaign.worlds (0 = first semester).
var world_index := 0
## Position of the chosen level inside the world's levels (0 = level 1).
var level_index := 0
## Debug only ("Desbloquear todos los niveles" in the hidden panel of Inicio):
## every world that is built and every level can be entered. It lives only in
## memory, so it is off again every time the game starts. Change it with
## set_debug_unlock_all(), which also stops ProgressRepository from saving.
var debug_unlock_all := false


## Grade of a won level: 10 minus one point per Extraordinario used, never below 6.
static func grade_for(extraordinarios_used: int) -> int:
	return maxi(MAX_GRADE - extraordinarios_used, MIN_GRADE)


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


# --- Locks ---

## A world can be entered when it is available (not "Próximamente") and it is
## the first one or the previous world has been completed (its last level won).
func is_world_unlocked(index: int) -> bool:
	var world := campaign.worlds[index]
	if not world.available or world.levels.is_empty():
		return false
	if debug_unlock_all:
		return true
	return index == 0 or ProgressRepository.is_world_completed(campaign.worlds[index - 1])


## A level can be entered when its world is open and the level is not beyond
## the highest unlocked level of the world.
func is_level_unlocked(world: int, level: int) -> bool:
	if debug_unlock_all:
		return is_world_unlocked(world)
	return is_world_unlocked(world) and level + 1 <= ProgressRepository.get_unlocked_level(campaign.worlds[world])


## Block 12: the previous world is completed, but this one is not built yet
## (available = false or no levels). The career map shows it open, without
## padlock, saying "Próximamente" (World 3 after World 2).
func is_world_coming_soon(index: int) -> bool:
	var world := campaign.worlds[index]
	if world.available and not world.levels.is_empty():
		return false
	return index > 0 and ProgressRepository.is_world_completed(campaign.worlds[index - 1])


## Why a world cannot be entered (the career map shows it). "" = it is open.
func world_lock_reason(index: int) -> String:
	var world := campaign.worlds[index]
	if not world.available or world.levels.is_empty():
		return "%s: Próximamente" % world.display_name
	if not is_world_unlocked(index):
		return "Aprueba %s para abrir %s" % [campaign.worlds[index - 1].display_name, world.display_name]
	return ""


## Why a level cannot be entered (the level select shows it). "" = it is open.
func level_lock_reason(world: int, level: int) -> String:
	if not is_world_unlocked(world):
		return world_lock_reason(world)
	if not is_level_unlocked(world, level):
		return "Gana el nivel %d para abrir el nivel %d" % [level, level + 1]
	return ""


## Debug only: opens (or closes) every level to test the later ones without
## playing the whole game. While it is on, ProgressRepository saves nothing,
## so the real progress in user://progress.cfg is never changed. Turning it
## off reads the file again, which forgets anything won during the test.
## Does nothing in a release build.
func set_debug_unlock_all(on: bool) -> void:
	if not OS.is_debug_build():
		return
	debug_unlock_all = on
	ProgressRepository.debug_dont_save = on
	if not on:
		ProgressRepository.load_progress()


## The last world the player can enter (the career map scrolls to it and Inicio shows it).
func latest_world_index() -> int:
	var latest := 0
	for i in campaign.worlds.size():
		if is_world_unlocked(i):
			latest = i
	return latest


# --- Screens ---

## "Jugar" / "Continuar" on Inicio.
func open_map() -> void:
	SceneTransition.change_scene(CAREER_MAP_SCENE)


## A semester button of the career map: opens the level select of that world.
## It does nothing if the world is locked (the map shows why before calling it).
func open_world(index: int) -> void:
	if not is_world_unlocked(index):
		return
	world_index = index
	SceneTransition.change_scene(LEVEL_SELECT_SCENE)


## Back to the level select of the current world (Pause, Defeat and Victory).
func open_level_select() -> void:
	SceneTransition.change_scene(LEVEL_SELECT_SCENE)


## After the last level of a world is won.
func open_world_complete() -> void:
	SceneTransition.change_scene(WORLD_COMPLETE_SCENE)


## Chooses a level and opens the loading screen, which loads it.
func start_level(world: int, level: int) -> void:
	world_index = world
	level_index = level
	SceneTransition.change_scene(LOADING_SCENE)


## "Siguiente nivel" on the Victory panel.
func start_next_level() -> void:
	start_level(world_index, level_index + 1)


## Plays the saved "next level" of the latest open world.
## Inicio opens the career map since v1.2; this stays for tools and tests.
func continue_game() -> void:
	var world := latest_world_index()
	start_level(world, ProgressRepository.get_current_level(campaign.worlds[world]) - 1)


## Game calls it when the level is won. It saves the result and returns
## the error of the save so Game can show the notice.
func complete_current_level(grade: int) -> Error:
	return ProgressRepository.complete_level(current_world(), level_index, grade)
