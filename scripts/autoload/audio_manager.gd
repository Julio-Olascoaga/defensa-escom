extends Node
## Autoload (singleton) "AudioManager": one AudioStreamPlayer for the music
## (bus "Music") and a small group of players for the sound effects (bus "SFX").
## The buses are in default_bus_layout.tres. The volumes come from
## ProgressRepository, so they survive closing the app.
## Block 7 built the pieces; Ajustes (Block 8) moves the volumes. The songs and
## effects arrive in Block 11.

## How many effects can sound at the same time.
const SFX_PLAYER_COUNT := 6
## Seconds of the fade when the song changes.
const MUSIC_FADE_TIME := 0.5

var _music_player := AudioStreamPlayer.new()
var _sfx_players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # music keeps playing in the pause menu
	_music_player.bus = "Music"
	add_child(_music_player)
	for i in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	_apply_volume("Music", ProgressRepository.get_setting("music_volume"))
	_apply_volume("SFX", ProgressRepository.get_setting("sfx_volume"))


## Plays a song. If another one is playing, it fades out first.
## The same song is not restarted. null = stop the music.
func play_music(stream: AudioStream) -> void:
	if stream == _music_player.stream and _music_player.playing:
		return
	if _music_player.playing:
		var fade_out := create_tween()
		fade_out.tween_property(_music_player, "volume_db", -40.0, MUSIC_FADE_TIME)
		await fade_out.finished
	_music_player.stop()
	_music_player.stream = stream
	_music_player.volume_db = 0.0
	if stream:
		_music_player.play()


## Plays a sound effect in the first free player
## (if all are busy, it cuts the first one).
func play_sfx(stream: AudioStream) -> void:
	var player := _sfx_players[0]
	for candidate in _sfx_players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.play()


## Volume from 0.0 (silence) to 1.0 (full). The sliders of Ajustes call these.
func set_music_volume(volume: float) -> void:
	_apply_volume("Music", volume)
	ProgressRepository.set_setting("music_volume", volume)


func set_sfx_volume(volume: float) -> void:
	_apply_volume("SFX", volume)
	ProgressRepository.set_setting("sfx_volume", volume)


## Buses work in decibels: linear_to_db() converts 0.0–1.0 to dB.
## At 0 the bus is muted, because linear_to_db(0) is minus infinity.
func _apply_volume(bus_name: String, volume: float) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	AudioServer.set_bus_volume_db(bus, linear_to_db(volume))
	AudioServer.set_bus_mute(bus, volume <= 0.0)


## Short vibration of the phone (the Extraordinario uses it). Only on phones,
## and only if "Vibración" is on in Ajustes. Android needs the VIBRATE
## permission in the export preset.
func vibrate(milliseconds: int = 150) -> void:
	if ProgressRepository.get_setting("vibration") and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)
