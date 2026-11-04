extends Node
## Autoload (singleton) "ProgressRepository": the only piece of the game that
## reads and writes in user://. It keeps the whole progress in a ConfigFile in
## memory and writes it to user://progress.cfg every time something changes.
##
##     [meta]
##     version=2
##     [world_1]              <- one section per world, named with WorldData.id
##     current_level=3        <- level opened by "Continuar" (1 = first level)
##     unlocked_level=4       <- highest level the player can enter
##     completed=true         <- the last level of the world was won
##     grade_w1_l1=10         <- best grade of each level, named with LevelData.id
##     [seen]
##     dialogues=["w1_intro"] <- conversations already shown (Block 9)
##     [settings]
##     music_volume=0.8
##     sfx_volume=1.0
##     vibration=true
##
## A file saved by the 1.0 (it has no [meta] section) is migrated when it is read.

const SAVE_PATH := "user://progress.cfg"
## Version of the file format. The 1.0 had no version (it counts as 1).
const VERSION := 2
## Values used while the player has not changed the settings.
const DEFAULT_SETTINGS := {"music_volume": 0.8, "sfx_volume": 1.0, "vibration": true}

## Result of the last load_progress(). OK also covers "there was no file yet";
## any other value means the file was damaged or had invalid data
## and the progress started again from zero.
var load_error := OK
## Debug only: makes save_progress() fail on purpose to test the error notice.
var simulate_save_error := false

## Everything that is saved, in memory. save_progress() writes it to SAVE_PATH.
var _config := ConfigFile.new()


func _ready() -> void:
	load_progress()


func _notification(what: int) -> void:
	# The app went to the background (home button, call...): save just in case
	# Android closes it while it is not visible.
	if what == NOTIFICATION_APPLICATION_PAUSED:
		save_progress()


# --- Levels and grades ---

## Level opened by "Continuar" in this world (1 = first level).
func get_current_level(world: WorldData) -> int:
	return _config.get_value(world.id, "current_level", 1)


## Highest level of this world the player can enter (1 = only the first one).
func get_unlocked_level(world: WorldData) -> int:
	return _config.get_value(world.id, "unlocked_level", 1)


## True once the last level of the world has been won.
func is_world_completed(world: WorldData) -> bool:
	return _config.get_value(world.id, "completed", false)


## Best grade of a level (6 to 10), or 0 if it has never been won.
func get_grade(world: WorldData, level_index: int) -> int:
	return _config.get_value(world.id, _grade_key(world, level_index), 0)


## True once the player has won at least one level (Inicio shows "Continuar").
func has_progress() -> bool:
	for world in GameSession.campaign.worlds:
		if _config.has_section(world.id):
			return true
	return false


## GameSession calls this when the player wins a level.
## Moves "Continuar" to the next level (after the last one the world is
## completed and it goes back to level 1), unlocks the next level, keeps the
## grade only if it is better than the saved one, and saves.
## Returns the result of save_progress() so Game can show the error notice.
func complete_level(world: WorldData, level_index: int, grade: int) -> Error:
	var level_count := world.levels.size()
	var next_number := level_index + 2  # number of the next level (index 0 is level 1)
	if next_number > level_count:
		_config.set_value(world.id, "completed", true)
		next_number = 1
	_config.set_value(world.id, "current_level", next_number)
	var unlocked := mini(level_index + 2, level_count)  # the next level, or the last one
	_config.set_value(world.id, "unlocked_level", maxi(get_unlocked_level(world), unlocked))
	if grade > get_grade(world, level_index):
		_config.set_value(world.id, _grade_key(world, level_index), grade)
	return save_progress()


# --- Dialogues (Block 9) ---

func has_seen_dialogue(dialogue_id: String) -> bool:
	return dialogue_id in _config.get_value("seen", "dialogues", [])


func mark_dialogue_seen(dialogue_id: String) -> Error:
	var seen: Array = _config.get_value("seen", "dialogues", [])
	if dialogue_id in seen:
		return OK
	seen.append(dialogue_id)
	_config.set_value("seen", "dialogues", seen)
	return save_progress()


# --- Settings ---

## Reads one of DEFAULT_SETTINGS ("music_volume", "sfx_volume" or "vibration").
func get_setting(key: String) -> Variant:
	return _config.get_value("settings", key, DEFAULT_SETTINGS[key])


func set_setting(key: String, value: Variant) -> Error:
	_config.set_value("settings", key, value)
	return save_progress()


# --- user://progress.cfg ---

## Writes everything in memory to SAVE_PATH.
func save_progress() -> Error:
	if simulate_save_error:
		return ERR_FILE_CANT_WRITE
	_config.set_value("meta", "version", VERSION)
	var error := _config.save(SAVE_PATH)
	if error != OK:
		push_warning("Could not save %s (error %d)" % [SAVE_PATH, error])
	else:
		load_error = OK  # the file now holds good data, so Home stops showing the warning
	return error


## Reads SAVE_PATH. If the file does not exist, is damaged or has values that
## do not fit the campaign, the game starts from zero without crashing.
func load_progress() -> void:
	_config = ConfigFile.new()
	load_error = OK
	var error := _config.load(SAVE_PATH)
	if error == ERR_FILE_NOT_FOUND:
		return  # first launch: nothing saved yet
	if error != OK:
		_reject_file("could not be read (error %d)" % error, error)
		return
	# ConfigFile accepts some garbage without an error (random text, binary data)
	# and simply finds no sections, so a file with no sections is also damaged.
	if _config.get_sections().is_empty():
		_reject_file("has no sections", ERR_FILE_CORRUPT)
		return
	var is_old_format := not _config.has_section("meta")
	if is_old_format:
		_migrate_from_v1()
	if not _has_valid_values():
		_reject_file("has invalid values", ERR_INVALID_DATA)
		return
	if is_old_format:
		save_progress()  # if it fails, the old file stays and is migrated again next time


## Debug option (and the "Borrar progreso" button of Block 8): forgets the
## levels, grades and dialogues, but keeps the settings.
func reset_progress() -> Error:
	for section in _config.get_sections():
		if section != "meta" and section != "settings":
			_config.erase_section(section)
	load_error = OK
	return save_progress()


## The 1.0 saved only [world_1] with level numbers from 1 to 5. The 2.0 put
## the tutorial "Primer día" in front, so every old level moved one place:
## the old level 1 ("Inicio de semestre") is now level 2.
## Values that are not numbers are left as they are, so the validation rejects them.
## It only changes the memory: load_progress() saves it after the validation.
func _migrate_from_v1() -> void:
	for key in ["current_level", "unlocked_level"]:
		var value: Variant = _config.get_value("world_1", key, null)
		if typeof(value) == TYPE_INT:
			_config.set_value("world_1", key, value + 1)
	print("%s migrated from the 1.0 format" % SAVE_PATH)


## Each saved world needs whole level numbers inside the world,
## and current_level cannot be beyond unlocked_level.
func _has_valid_values() -> bool:
	for world in GameSession.campaign.worlds:
		if not _config.has_section(world.id):
			continue
		var current: Variant = _config.get_value(world.id, "current_level", 1)
		var unlocked: Variant = _config.get_value(world.id, "unlocked_level", 1)
		if not _is_level_number(current, world) or not _is_level_number(unlocked, world) or current > unlocked:
			return false
	return true


func _is_level_number(value: Variant, world: WorldData) -> bool:
	return typeof(value) == TYPE_INT and value >= 1 and value <= world.levels.size()


## Name of the grade in the file: "grade_" + the level's id ("grade_w1_l3").
## A level without id uses its position ("grade_world_1_l3").
func _grade_key(world: WorldData, level_index: int) -> String:
	var level := world.levels[level_index]
	if level.id != "":
		return "grade_" + level.id
	return "grade_%s_l%d" % [world.id, level_index + 1]


func _reject_file(reason: String, error: Error) -> void:
	push_warning("%s %s; starting from zero" % [SAVE_PATH, reason])
	_config = ConfigFile.new()
	load_error = error
