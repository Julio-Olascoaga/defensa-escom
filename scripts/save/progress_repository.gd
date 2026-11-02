extends Node
## Autoload (singleton) "ProgressRepository": remembers which level is being played
## and saves the progress so it survives closing the app.
## It is the only piece of the game that reads and writes in user://.
## The file is a ConfigFile with one section per world:
##
##     [world_1]
##     current_level=3
##     unlocked_level=3

const SAVE_PATH := "user://progress.cfg"

## The world being played. Its list of levels decides the order.
const WORLD := preload("res://data/worlds/world_1.tres")

## Position of the current level inside WORLD.levels (0 = level 1).
var current_level_index := 0
## Highest level reached in WORLD (0 = level 1). It never goes down,
## not even when the world is completed and the current level returns to 1.
var unlocked_level_index := 0
## Result of the last load_progress(). OK also covers "there was no file yet";
## any other value means the file was damaged or had invalid data
## and the progress started again from level 1.
var load_error := OK
## Debug only: makes save_progress() fail on purpose to test the error notice.
var simulate_save_error := false


func _ready() -> void:
	load_progress()


func get_world() -> WorldData:
	return WORLD


## The LevelData of the level being played (null if the world file has an empty slot).
func get_current_level() -> LevelData:
	return WORLD.levels[current_level_index]


## Number shown to the player: index 0 is "Nivel 1".
func get_current_level_number() -> int:
	return current_level_index + 1


## True if the world still has a level after the current one.
func has_next_level() -> bool:
	return current_level_index + 1 < WORLD.levels.size()


## True once the player has won at least one level (Inicio shows "Continuar").
func has_progress() -> bool:
	return current_level_index > 0 or unlocked_level_index > 0


## Game calls this when the player wins the level.
## Moves on to the next level; after the last one, the world is complete
## and the current level goes back to 1. Then it saves.
## Returns the result of save_progress() so Game can show the error notice.
func complete_level() -> Error:
	if has_next_level():
		current_level_index += 1
	else:
		current_level_index = 0
	unlocked_level_index = maxi(unlocked_level_index, current_level_index)
	return save_progress()


# --- user://progress.cfg ---

## Writes the progress of WORLD. Other sections of the file (future worlds) are kept.
func save_progress() -> Error:
	if simulate_save_error:
		return ERR_FILE_CANT_WRITE
	var config := ConfigFile.new()
	config.load(SAVE_PATH)  # if it fails we simply start from an empty file
	config.set_value(_world_section(), "current_level", current_level_index + 1)
	config.set_value(_world_section(), "unlocked_level", unlocked_level_index + 1)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save %s (error %d)" % [SAVE_PATH, error])
	return error


## Reads the progress of WORLD. If the file does not exist, is damaged or has
## values that do not fit the world, the game starts from level 1 without crashing.
func load_progress() -> void:
	current_level_index = 0
	unlocked_level_index = 0
	load_error = OK
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return  # first launch: nothing saved yet
	if error != OK:
		_reject_file("could not be read (error %d)" % error, error)
		return
	# ConfigFile accepts some garbage without an error (random text, binary data)
	# and simply finds no sections, so a file with no sections is also damaged.
	if config.get_sections().is_empty():
		_reject_file("has no sections", ERR_FILE_CORRUPT)
		return
	if not config.has_section(_world_section()):
		return  # the file only has other worlds: this one starts at level 1
	# A missing key reads as 0, which is not a valid level number.
	var current: Variant = config.get_value(_world_section(), "current_level", 0)
	var unlocked: Variant = config.get_value(_world_section(), "unlocked_level", 0)
	if not _is_valid_level_number(current) or not _is_valid_level_number(unlocked) or current > unlocked:
		_reject_file("has invalid values", ERR_INVALID_DATA)
		return
	current_level_index = current - 1
	unlocked_level_index = unlocked - 1


## Debug only: forgets the progress and deletes the file.
func reset_progress() -> void:
	current_level_index = 0
	unlocked_level_index = 0
	load_error = OK
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Name of the section in the file: the world's id ("world_1").
func _world_section() -> String:
	return WORLD.id


## A level number from the file is valid if it is an integer between 1 and the number of levels.
func _is_valid_level_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT and value >= 1 and value <= WORLD.levels.size()


func _reject_file(reason: String, error: Error) -> void:
	push_warning("%s %s; starting from level 1" % [SAVE_PATH, reason])
	load_error = error
