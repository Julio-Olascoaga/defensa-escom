extends Node
## Autoload (singleton) "AudioManager": the music (bus "Music") and the sound
## effects (bus "SFX"). The buses are in default_bus_layout.tres. The volumes
## come from ProgressRepository, so they survive closing the app.
## Block 7 built the pieces; Ajustes (Block 8) moves the volumes.
## Block 11: the songs and effects (audio/, made by tools/audio_src/make_audio.py),
## a crossfade between songs, a click on every button and the vibration.
##
## Any script plays a sound like this:
##     AudioManager.play_music(AudioManager.MENU_MUSIC)
##     AudioManager.play_sfx(AudioManager.SFX_PLACE)

# --- Songs (menu, boss, victory and defeat; each world has its own in WorldData.music) ---
const MENU_MUSIC := preload("res://audio/music/menu.ogg")
const BOSS_MUSIC := preload("res://audio/music/boss.ogg")
const VICTORY_MUSIC := preload("res://audio/music/victory.ogg")  # it does not loop
const DEFEAT_MUSIC := preload("res://audio/music/defeat.ogg")    # it does not loop

# --- Effects ---
const SFX_PLACE := preload("res://audio/sfx/place.wav")
const SFX_COLLECT := preload("res://audio/sfx/collect.wav")
const SFX_SHOOT := preload("res://audio/sfx/shoot.wav")
const SFX_HIT := preload("res://audio/sfx/hit.wav")
const SFX_BITE := preload("res://audio/sfx/bite.wav")
const SFX_DIE := preload("res://audio/sfx/die.wav")
const SFX_EXTRAORDINARIO := preload("res://audio/sfx/extraordinario.wav")
const SFX_BUTTON := preload("res://audio/sfx/button.wav")
const SFX_DIRECTOR_BIP := preload("res://audio/sfx/director_bip.wav")

## How many effects can sound at the same time.
const SFX_PLAYER_COUNT := 8
## The same effect is not repeated before this many seconds (ten Laptops
## shooting in the same frame would sound like one loud noise).
const SFX_MIN_GAP := 0.06
## Seconds of the crossfade when the song changes.
const MUSIC_FADE_TIME := 0.8
## Volume (dB) of a song that is "silent" during the crossfade.
const SILENT_DB := -40.0

## Two music players: while one fades out, the other fades in (crossfade).
var _music_players: Array[AudioStreamPlayer] = []
## Index (0 or 1) of the player with the current song.
var _current := 0
var _fade_tween: Tween
var _sfx_players: Array[AudioStreamPlayer] = []
## Last time (in seconds) each effect sounded. Key: the AudioStream.
var _last_played: Dictionary[AudioStream, float] = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # music keeps playing in the pause menu
	for i in 2:
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		add_child(player)
		_music_players.append(player)
	for i in SFX_PLAYER_COUNT:
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		add_child(player)
		_sfx_players.append(player)
	_apply_volume("Music", ProgressRepository.get_setting("music_volume"))
	_apply_volume("SFX", ProgressRepository.get_setting("sfx_volume"))
	# Every button that enters any scene makes a click when it is pressed.
	get_tree().node_added.connect(_on_node_added)


# --- Music ---

## Plays a song with a crossfade: the old one goes down while the new one
## comes up. The same song is not restarted. null = fade out to silence.
func play_music(stream: AudioStream) -> void:
	var old_player := _music_players[_current]
	if stream == old_player.stream and old_player.playing:
		return
	if _fade_tween:
		_fade_tween.kill()  # a crossfade that was still running ends here
	var new_player := _music_players[1 - _current]
	new_player.stop()
	_current = 1 - _current
	_fade_tween = create_tween().set_parallel()
	_fade_tween.tween_property(old_player, "volume_db", SILENT_DB, MUSIC_FADE_TIME)
	if stream:
		if stream is AudioStreamOggVorbis:
			stream.loop = true  # the songs of the menus, the worlds and the boss repeat forever
		new_player.stream = stream
		new_player.volume_db = SILENT_DB
		new_player.play()
		_fade_tween.tween_property(new_player, "volume_db", 0.0, MUSIC_FADE_TIME)
	_fade_tween.chain().tween_callback(old_player.stop)


## Plays a song at once, without crossfade (the victory and defeat jingles
## must start on the beat). The previous song stops.
func play_jingle(stream: AudioStream) -> void:
	if _fade_tween:
		_fade_tween.kill()
	for player in _music_players:
		player.stop()
	var player := _music_players[_current]
	if stream is AudioStreamOggVorbis:
		stream.loop = false  # a jingle sounds only once
	player.stream = stream
	player.volume_db = 0.0
	player.play()


## Fades the music out to silence.
func stop_music() -> void:
	play_music(null)


# --- Effects ---

## Plays an effect in the first free player (if all are busy, it cuts the
## first one). pitch changes the tone a little: 1.0 = as recorded,
## 0.8 = lower, 1.2 = higher.
func play_sfx(stream: AudioStream, pitch: float = 1.0) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - _last_played.get(stream, -1.0) < SFX_MIN_GAP:
		return  # the same effect just sounded
	_last_played[stream] = now
	var player := _sfx_players[0]
	for candidate in _sfx_players:
		if not candidate.playing:
			player = candidate
			break
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


## Same effect, with a random pitch between low and high, so a sound that
## repeats a lot (hits, the Director's voice) does not sound like a machine.
func play_sfx_varied(stream: AudioStream, low: float = 0.92, high: float = 1.08) -> void:
	play_sfx(stream, randf_range(low, high))


## A button entered the scene tree: it clicks when pressed. The energy orbs
## are buttons too, but they have their own sound (SFX_COLLECT).
## (A node can leave the tree and enter again: it is connected only once.)
func _on_node_added(node: Node) -> void:
	if node is BaseButton and not node is EnergyOrb and not node.pressed.is_connected(_play_click):
		node.pressed.connect(_play_click)


func _play_click() -> void:
	play_sfx(SFX_BUTTON)


# --- Volume ---

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


# --- Vibration ---

## Short vibration of the phone: when a defender is lost, when an
## Extraordinario runs and when the boss arrives. Only on phones, and only if
## "Vibración" is on in Ajustes. Android needs the VIBRATE permission in the
## export preset.
func vibrate(milliseconds: int = 150) -> void:
	if ProgressRepository.get_setting("vibration") and OS.has_feature("mobile"):
		Input.vibrate_handheld(milliseconds)
