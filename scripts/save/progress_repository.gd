extends Node
## Autoload (singleton) "ProgressRepository": the only piece of the game that
## reads and writes in user://. It keeps the whole progress in a ConfigFile in
## memory and writes it to user://progress.cfg every time something changes.
##
##     [meta]
##     version=3
##     [world_1]              <- one section per world, named with WorldData.id
##     current_level=3        <- next level to play (1 = first level)
##     unlocked_level=4       <- highest level the player can enter
##     completed=true         <- the last level of the world was won
##     grade_w1_l1=10         <- best grade of each level, named with LevelData.id
##     [seen]                 <- Block 9
##     dialogues=["w1_intro"] <- conversations (and the tutorial) already shown
##     cards=["cafe"]         <- cards and enemies met, shown in the Expediente
##     enemies=["tarea_infinita"]
##     [settings]
##     music_volume=0.8
##     sfx_volume=1.0
##     vibration=true
##
## A file saved by the 1.0 (no [meta] section) or by the v1.1 (version=2)
## is migrated when it is read (see _migrate_legacy()).

const SAVE_PATH := "user://progress.cfg"
## Version of the file format. The 1.0 had no version (it counts as 1),
## the v1.1 wrote 2. Version 3 (v1.2) keeps the same keys, but a finished
## world is always marked completed and its won levels always have a grade.
const VERSION := 3
## Grade given to the levels won in the 1.0 (it had no grades): the minimum
## passing grade. Winning the level again saves the real grade, which is always >= 6.
const LEGACY_GRADE := 6
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


## Average of the best grades of the levels already won in this world
## (levels never won do not count). 0.0 if no level has a grade yet.
func get_world_average(world: WorldData) -> float:
	var total := 0
	var count := 0
	for i in world.levels.size():
		var grade := get_grade(world, i)
		if grade > 0:
			total += grade
			count += 1
	return float(total) / count if count > 0 else 0.0


## True once the player has won at least one level (Inicio shows "Continuar").
func has_progress() -> bool:
	for world in GameSession.campaign.worlds:
		if _config.has_section(world.id):
			return true
	return false


## GameSession calls this when the player wins a level.
## Moves "Continuar" to the next level, unlocks it, keeps the grade only if
## it is better than the saved one, and saves. Winning the last level marks
## the world completed (that opens the next world) and, unlike the 1.0,
## does not send the progress back to level 1.
## Returns the result of save_progress() so Game can show the error notice.
func complete_level(world: WorldData, level_index: int, grade: int) -> Error:
	var level_count := world.levels.size()
	var next_number := mini(level_index + 2, level_count)  # number of the next level (index 0 is level 1)
	if level_index + 1 >= level_count:
		_config.set_value(world.id, "completed", true)
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


# --- Expediente (Block 9) ---

## True once the player has met this card (kind "cards") or enemy (kind "enemies").
func is_known(kind: String, type: Resource) -> bool:
	return _known_id(type) in _config.get_value("seen", kind, [])


## Remembers that the player met these cards or enemies: a card when it is in
## the bar of a level or the Director presents it, an enemy when it enters the
## board or the Director presents it. It saves only if something is new.
func mark_known(kind: String, types: Array) -> Error:
	var known: Array = _config.get_value("seen", kind, [])
	var changed := false
	for type: Resource in types:
		if type and not _known_id(type) in known:
			known.append(_known_id(type))
			changed = true
	if not changed:
		return OK
	_config.set_value("seen", kind, known)
	return save_progress()


## Name saved for a card or an enemy: the name of its file ("cafe" for
## data/defenders/cafe.tres). A resource made in code (tests) uses its display_name.
func _known_id(type: Resource) -> String:
	if type.resource_path != "":
		return type.resource_path.get_file().get_basename()
	return str(type.get("display_name"))


# --- Settings ---

## Reads one of DEFAULT_SETTINGS ("music_volume", "sfx_volume" or "vibration").
## A value of the wrong type in the file is ignored (the default is used),
## and volumes are kept between 0.0 and 1.0.
func get_setting(key: String) -> Variant:
	var default: Variant = DEFAULT_SETTINGS[key]
	var value: Variant = _config.get_value("settings", key, default)
	if typeof(default) == TYPE_FLOAT and typeof(value) == TYPE_INT:
		value = float(value)  # "music_volume=0" is written as a whole number
	if typeof(value) != typeof(default):
		return default
	if typeof(value) == TYPE_FLOAT:
		return clampf(value, 0.0, 1.0)
	return value


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
	var file_version: Variant = _config.get_value("meta", "version", 1)  # no [meta] = 1.0
	if typeof(file_version) != TYPE_INT or file_version > VERSION:
		_reject_file("has an unknown version", ERR_INVALID_DATA)
		return
	if file_version == 1:
		_migrate_from_v1()
	if not _has_valid_values():
		_reject_file("has invalid values", ERR_INVALID_DATA)
		return
	if file_version < VERSION:
		_migrate_legacy()
		save_progress()  # if it fails, the old file stays and is migrated again next time


## Debug option (and the "Borrar progreso" button of Block 8): forgets the
## levels, grades, dialogues and the Expediente, but keeps the settings.
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


## Files written by the 1.0 (already moved one level by _migrate_from_v1) and
## by the v1.1 (version 2) do not mark a world finished in the 1.0 as
## completed, and the 1.0 had no grades. Both versions only played the levels
## in order, and "current_level" went below "unlocked_level" only after the
## last level was won (it went back to level 1). So, in world_1:
##   - current_level < unlocked_level  ->  the world was finished: every level
##     is unlocked and the world is marked completed (it opens world 2).
##   - every level from 2 that was won (all of them if finished, else those
##     before unlocked_level) and has no grade gets LEGACY_GRADE (6).
## "Primer día" (level 1) did not exist in the 1.0, so it gets no grade: it
## stays open to be played. Grades saved by the v1.1 are kept.
## Runs after the validation, so the values are whole level numbers.
func _migrate_legacy() -> void:
	var world: WorldData = GameSession.campaign.worlds[0]
	if not _config.has_section(world.id):
		return
	var level_count := world.levels.size()
	var current := get_current_level(world)
	var unlocked := get_unlocked_level(world)
	var finished := current < unlocked or is_world_completed(world)
	if finished:
		_config.set_value(world.id, "unlocked_level", level_count)
		_config.set_value(world.id, "completed", true)
	var last_won := level_count if finished else unlocked - 1  # level numbers
	for number in range(2, last_won + 1):
		if get_grade(world, number - 1) == 0:
			_config.set_value(world.id, _grade_key(world, number - 1), LEGACY_GRADE)
	print("%s migrated to version %d" % [SAVE_PATH, VERSION])


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
