class_name WaveManager
extends Node
## Reads the waves of a LevelData and says when each enemy must appear.
## It does not create enemies itself: it emits spawn_requested and Game spawns them.
##
## How a wave works:
##   1. Calm: start_delay seconds with no enemies.
##   2. Each SpawnEvent fires when its time (counted after the calm) arrives.
##   3. When every event has fired AND no enemy is left alive, the next wave starts.
## Time is counted with delta in _process, so everything freezes during pause.

## An enemy must appear now in this lane.
signal spawn_requested(enemy_type: EnemyType, lane: int)
## A new wave begins (wave_number starts at 1). The HUD shows "Oleada X de Y".
signal wave_started(wave_number: int, wave_count: int)
## Another enemy of the current wave has appeared. The HUD fills its bar.
signal wave_progress(spawned: int, total: int)
## The last wave has fully appeared and no enemy is alive: the level is won.
signal all_waves_cleared

var waves: Array[WaveData] = []
## Position of the current wave in the list. Equal to waves.size() = finished.
var wave_index := 0
## Events of the current wave, sorted by time.
var events: Array[SpawnEvent] = []
## Index of the next event to fire in the current wave.
var next_event := 0
## Seconds since the current wave began (its calm included).
var wave_time := 0.0


## Game calls this once, with the waves of the level.
func start(level_waves: Array[WaveData]) -> void:
	waves = level_waves
	_start_wave(0)


func is_finished() -> bool:
	return wave_index >= waves.size()


func _process(delta: float) -> void:
	if is_finished():
		return
	if next_event < events.size():
		# The wave is still appearing.
		wave_time += delta
		var wave := waves[wave_index]
		while next_event < events.size() and wave_time >= wave.start_delay + events[next_event].time:
			_fire(events[next_event])
			next_event += 1
			wave_progress.emit(next_event, events.size())
	elif get_tree().get_nodes_in_group("enemies").is_empty():
		# Every enemy of this wave has appeared and none is alive: next wave.
		_start_wave(wave_index + 1)


func _start_wave(index: int) -> void:
	wave_index = index
	next_event = 0
	wave_time = 0.0
	if is_finished():
		all_waves_cleared.emit()
		return
	# A copy sorted by time, so the order in the Inspector does not matter.
	events = waves[wave_index].events.duplicate()
	events.sort_custom(func(a: SpawnEvent, b: SpawnEvent) -> bool: return a.time < b.time)
	wave_started.emit(wave_index + 1, waves.size())
	wave_progress.emit(0, events.size())


func _fire(event: SpawnEvent) -> void:
	if event.enemy_type == null:
		push_error("SpawnEvent at %.1f s in wave %d has no enemy_type" % [event.time, wave_index + 1])
		return
	spawn_requested.emit(event.enemy_type, event.lane)
