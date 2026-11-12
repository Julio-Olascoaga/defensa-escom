extends Node2D
## Root of the game scene.
## It owns the energy and the phase of the match (playing, victory, defeat),
## connects the signals between entities and UI, places and removes defenders,
## spawns the enemies WaveManager asks for, runs the Extraordinarios,
## counts how many were used (that is the grade) and handles play time and pause.
## The level it plays comes from the GameSession Autoload, which also
## saves the progress (through ProgressRepository) when the level is won.
## Block 9: before the first wave the Director talks (LevelData.intro_dialogue)
## and, in the tutorial level, the Tutorial guides the player; after the last
## wave he talks again (outro_dialogue) before the Victory panel.
## Block 10: the camera shakes when the boss enters and when it enters phase 2;
## energy orbs fly to the energy counter of the top bar.
## Block 11: the music of the world (the boss brings its own song), the
## effects of placing, shooting and losing a defender, the victory and defeat
## jingles, the phone vibration, and the time of day of the level (Scenery).
## Block 12: instant cards (Ctrl+Z) free their cell when they go off; a boss
## may bring its own phase 2 banner (EnemyType.phase2_text).

const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")
const EXTRAORDINARIO_SCENE := preload("res://scenes/game/extraordinario.tscn")

enum Phase { PLAYING, VICTORY, DEFEAT }

## Camera shake: pixels and seconds when the boss enters and when it enters phase 2.
const BOSS_ENTRY_SHAKE := 14.0
const BOSS_ENTRY_SHAKE_TIME := 0.7
const BOSS_PHASE2_SHAKE := 10.0
const BOSS_PHASE2_SHAKE_TIME := 0.5
## Seconds between two positions of a shake.
const SHAKE_STEP := 0.05
## Milliseconds the phone vibrates when the boss enters (longer than the rest).
const BOSS_VIBRATION_MS := 400
## Camera shake when an instant card (Ctrl+Z) goes off.
const INSTANT_SHAKE := 6.0
const INSTANT_SHAKE_TIME := 0.25

## The player selected a card (the Tutorial listens to these three signals).
signal card_selected(type: DefenderType)
## A defender was placed in a cell.
signal defender_placed(type: DefenderType, lane: int, column: int)
## The player collected an energy orb.
signal orb_collected(amount: int)

## Data of the level being played (name, start energy, defenders and waves).
var level: LevelData
## Seconds of play. It stops while the game is paused because this node
## uses the default process mode (Inherit -> Pausable).
var elapsed_time := 0.0
var energy := 0
var phase := Phase.PLAYING
## One Extraordinario per lane (index = lane), only if the level uses them.
var extraordinarios: Array[Extraordinario] = []
## How many Extraordinarios ran in this match. Grade = 10 - this, minimum 6.
var extraordinarios_used := 0
var camera_tween: Tween

@onready var background: Sprite2D = $Background
@onready var scenery: Scenery = $Scenery
@onready var board: Board = $Board
@onready var defenders: Node2D = $Defenders
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var orbs: Node2D = $Orbs
@onready var extraordinarios_node: Node2D = $Extraordinarios
@onready var hud: Hud = $UI/HUD
@onready var hint: Label = $UI/Hint
@onready var notice: Notice = $UI/Notice
@onready var wave_banner: Notice = $UI/WaveBanner
@onready var boss_bar: PanelContainer = $UI/BossBar
@onready var boss_name_label: Label = %BossName
@onready var boss_health_bar: ProgressBar = %BossHealth
@onready var pause_menu: PauseMenu = $UI/PauseMenu
@onready var defeat_panel: DefeatPanel = $UI/DefeatPanel
@onready var victory_panel: VictoryPanel = $UI/VictoryPanel
@onready var save_error_panel: SaveErrorPanel = $UI/SaveErrorPanel
@onready var wave_manager: WaveManager = $WaveManager
@onready var dialogue_box: DialogueBox = $DialogueBox
@onready var tutorial: Tutorial = $Tutorial
@onready var camera: Camera2D = $Camera


func _ready() -> void:
	level = GameSession.current_level()
	energy = level.start_energy
	_apply_background()
	scenery.setup(GameSession.current_world(), level.time_of_day)
	AudioManager.play_music(GameSession.current_world().music)
	hud.set_level_name(GameSession.current_level_number(), level.display_name)
	hud.set_wave(1, level.waves.size())  # the wave that comes first, while the Director talks
	hud.create_cards(level.defenders)  # one card per defender available in this level
	var margins := _safe_side_margins()
	hud.set_side_margins(margins.x, margins.y)
	DisplayServer.screen_set_keep_on(true)  # the phone does not turn its screen off while playing
	if level.use_extraordinarios:
		_create_extraordinarios()

	board.cell_tapped.connect(_on_board_cell_tapped)
	hud.pause_pressed.connect(pause_game)
	hud.card_pressed.connect(_on_card_pressed)
	hud.eraser_toggled.connect(_on_eraser_toggled)
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.exit_requested.connect(_on_exit_requested)
	defeat_panel.retry_requested.connect(_on_restart_requested)
	defeat_panel.home_requested.connect(_on_exit_requested)
	victory_panel.next_requested.connect(_on_next_level_requested)
	victory_panel.home_requested.connect(_on_exit_requested)
	save_error_panel.retry_requested.connect(_on_save_retry_requested)
	wave_manager.spawn_requested.connect(spawn_enemy)
	wave_manager.wave_warning.connect(wave_banner.show_message)
	wave_manager.wave_started.connect(hud.set_wave)
	wave_manager.wave_progress.connect(hud.set_wave_progress)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	hud.set_energy(energy)
	_update_hint()
	_begin_level()


## The Director talks (only the first time), the tutorial runs if the level
## has one and has not been done yet, and then the first wave starts.
## Until wave_manager.start() is called, WaveManager does nothing.
func _begin_level() -> void:
	ProgressRepository.mark_known("cards", level.defenders)  # the Expediente shows the cards of the bar
	hint.hide()  # while the Director talks, the hint would be under the dialogue box
	await dialogue_box.play_once(level.intro_dialogue)
	var tutorial_id := "tutorial_" + level.id
	if level.is_tutorial and not ProgressRepository.has_seen_dialogue(tutorial_id):
		await tutorial.run(self)  # the Director explains it in the tutorial bubble
		ProgressRepository.mark_dialogue_seen(tutorial_id)
	_update_hint()
	wave_manager.start(level.waves)


func _exit_tree() -> void:
	DisplayServer.screen_set_keep_on(false)  # menus let the phone sleep again


## The level's own background, or else its world's. If neither has one,
## the background drawn in game.tscn stays (the one of the 1.0).
## Backgrounds are 2560 x 1440 px, like the 1.0 one (the node is scaled to 0.5).
func _apply_background() -> void:
	var texture := level.background
	if texture == null:
		texture = GameSession.current_world().background
	if texture:
		background.texture = texture


## Android notch and round corners: how many pixels of the left and right
## edges of the game are hidden. The game keeps its 16:9 picture (stretch aspect
## "keep"), so on long phones the black side bars already cover the notch and
## both margins are 0. On PC it is always 0.
func _safe_side_margins() -> Vector2:
	if not OS.has_feature("mobile"):
		return Vector2.ZERO
	var screen := Vector2(DisplayServer.screen_get_size())
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var view := get_viewport_rect().size
	var screen_scale := minf(screen.x / view.x, screen.y / view.y)  # screen pixels per game pixel
	var picture_left := (screen.x - view.x * screen_scale) / 2.0   # where the game picture starts
	var picture_right := picture_left + view.x * screen_scale
	var left := maxf(0.0, safe.position.x - picture_left) / screen_scale
	var right := maxf(0.0, picture_right - safe.end.x) / screen_scale
	return Vector2(left, right)


func _process(delta: float) -> void:
	elapsed_time += delta
	hud.set_time(elapsed_time)


# --- Energy ---

func add_energy(amount: int) -> void:
	energy += amount
	hud.set_energy(energy)


func spend_energy(amount: int) -> void:
	energy -= amount
	hud.set_energy(energy)


# --- Cards and placement ---

func _on_card_pressed(card: DefenderCard) -> void:
	var type := card.defender_type
	hud.set_eraser_active(false)  # choosing a card puts the eraser away
	if card == hud.selected_card:
		hud.clear_selection()  # tapping the selected card again cancels it
	elif card.is_recharging():
		notice.show_message("%s se está recargando" % type.display_name)
	elif energy < type.cost:
		notice.show_message("Energía insuficiente: faltan %d" % (type.cost - energy))
	else:
		hud.select_card(card)
		card_selected.emit(type)


func _on_board_cell_tapped(lane: int, column: int) -> void:
	board.highlight_cell(lane, column)
	if hud.eraser_active:
		_erase_at(lane, column)
		return
	var card := hud.selected_card
	if card == null:
		notice.show_message("Primero toca una tarjeta de defensor")
		return
	var type := card.defender_type
	# Invalid moves: show why and do NOT take any energy.
	if board.is_occupied(lane, column):
		notice.show_message("Esa casilla ya está ocupada")
		return
	if energy < type.cost:
		notice.show_message("Energía insuficiente: faltan %d" % (type.cost - energy))
		return
	if not tutorial.allows_placement(type, lane):
		notice.show_message("Ponla en el carril que marca la flecha")
		return
	if type.behavior_scene == null:
		push_error("DefenderType '%s' has no behavior_scene" % type.display_name)
		notice.show_message("Datos inválidos: %s no tiene escena" % type.display_name)
		return

	place_defender(type, lane, column)
	card.start_cooldown()
	hud.clear_selection()
	board.clear_highlight()


## Creates the defender's behavior scene in a free cell and pays its cost.
func place_defender(type: DefenderType, lane: int, column: int) -> void:
	var defender: Defender = type.behavior_scene.instantiate()
	defender.setup(type, lane, column)
	defenders.add_child(defender)
	# Cells -> pixels only to draw the node on screen.
	defender.global_position = board.cell_to_pixel(lane, column)
	defender.died.connect(_on_defender_died)
	if defender is GeneratorDefender:
		defender.orb_produced.connect(_on_orb_produced)
	elif defender is ShooterDefender:
		defender.shot_fired.connect(_on_shot_fired)
	elif defender is InstantDefender:
		defender.used.connect(_on_instant_used)

	board.occupy_cell(lane, column, defender)
	spend_energy(type.cost)
	AudioManager.play_sfx(AudioManager.SFX_PLACE)
	_update_hint()
	defender_placed.emit(type, lane, column)


# --- "Dar de baja" (eraser) ---

func _on_eraser_toggled(active: bool) -> void:
	if active:
		hud.clear_selection()
		notice.show_message("Toca un defensor para darlo de baja")


## With the eraser active, a tap on a defender removes it (no energy back)
## and puts the eraser away. A tap on an empty cell only says what to do.
func _erase_at(lane: int, column: int) -> void:
	if not board.is_occupied(lane, column):
		notice.show_message("Toca un defensor para darlo de baja")
		return
	remove_defender(lane, column)
	hud.set_eraser_active(false)
	board.clear_highlight()


## Removes the defender of a cell and frees the cell. Its cost is not returned.
func remove_defender(lane: int, column: int) -> void:
	var defender := board.get_defender(lane, column)
	if defender == null:
		return
	board.free_cell(lane, column)
	defender.queue_free()
	_update_hint()


## Ctrl+Z went off: its cell is free again (it is not a loss: no vibration).
func _on_instant_used(defender: InstantDefender, _hits: int) -> void:
	if board.get_defender(defender.lane, defender.column) == defender:
		board.free_cell(defender.lane, defender.column)
	AudioManager.play_sfx(AudioManager.SFX_EXTRAORDINARIO, 1.3)
	shake_camera(INSTANT_SHAKE, INSTANT_SHAKE_TIME)
	_update_hint()


func _on_defender_died(defender: Defender) -> void:
	board.free_cell(defender.lane, defender.column)
	AudioManager.play_sfx(AudioManager.SFX_DIE, 0.7)  # the same "poof", lower
	AudioManager.vibrate()
	_update_hint()


## The empty-board hint is visible only while there are no defenders
## (and not during the tutorial, where the Director explains it).
func _update_hint() -> void:
	hint.visible = board.is_empty() and not tutorial.is_running()


# --- Energy orbs ---

func _on_orb_produced(orb: EnergyOrb) -> void:
	orbs.add_child(orb)
	# The orb's position is its top-left corner, so we subtract half its size to center it.
	orb.global_position = board.cell_to_pixel(orb.lane, orb.column) - orb.size / 2.0
	orb.fly_target = hud.energy_label.get_global_rect().get_center()  # the HUD is on screen pixels
	orb.collected.connect(add_energy)
	orb.collected.connect(orb_collected.emit)


# --- Projectiles ---

func _on_shot_fired(projectile: Projectile) -> void:
	projectile.board = board  # the projectile uses it to draw itself
	projectiles.add_child(projectile)
	AudioManager.play_sfx_varied(AudioManager.SFX_SHOOT)


# --- Enemies and waves ---

## WaveManager asks for each enemy through its spawn_requested signal (they enter
## at Enemy.SPAWN_COLUMN). The boss asks for its summons with summon_requested,
## which also sends the column where they must appear.
func spawn_enemy(type: EnemyType, lane: int, column: float = Enemy.SPAWN_COLUMN) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type, lane, board, column)
	enemy.reached_safe_zone.connect(_on_enemy_reached_safe_zone)
	enemy.summon_requested.connect(spawn_enemy)
	enemies.add_child(enemy)
	if type == level.featured_enemy and not ProgressRepository.is_known("enemies", type):
		notice.show_message("¡Cuidado! Ahí viene: %s" % type.display_name)
	ProgressRepository.mark_known("enemies", [type])  # it saves only the first time
	if type.is_boss:
		_show_boss_bar(enemy)
		enemy.phase_changed.connect(_on_boss_phase_changed)
		shake_camera(BOSS_ENTRY_SHAKE, BOSS_ENTRY_SHAKE_TIME)
		AudioManager.play_music(AudioManager.BOSS_MUSIC)
		AudioManager.vibrate(BOSS_VIBRATION_MS)


# --- Camera shake ---

## Moves the camera (only its offset, so cells and taps keep their place)
## to random points that get smaller, then back to the center.
func shake_camera(strength: float, duration: float) -> void:
	if camera_tween:
		camera_tween.kill()
	camera_tween = create_tween()
	var steps := maxi(1, roundi(duration / SHAKE_STEP))
	for i in steps:
		var power := strength * (1.0 - float(i) / steps)
		camera_tween.tween_property(camera, "offset", Vector2(randf_range(-power, power), randf_range(-power, power)), SHAKE_STEP)
	camera_tween.tween_property(camera, "offset", Vector2.ZERO, SHAKE_STEP)


# --- Extraordinarios ---

## One per lane, waiting at the left edge of the board.
func _create_extraordinarios() -> void:
	for lane in Board.LANES:
		var extraordinario: Extraordinario = EXTRAORDINARIO_SCENE.instantiate()
		extraordinario.setup(lane, board)
		extraordinarios_node.add_child(extraordinario)
		extraordinarios.append(extraordinario)


## Grade the player would get if the level ended now.
func current_grade() -> int:
	return GameSession.grade_for(extraordinarios_used)


# --- Boss health bar ---

func _show_boss_bar(boss: Enemy) -> void:
	boss_name_label.text = boss.enemy_type.display_name
	boss_health_bar.max_value = boss.enemy_type.health
	boss_health_bar.value = boss.health
	boss.damaged.connect(_on_boss_damaged)
	boss.died.connect(_on_boss_died)
	boss_bar.show()


func _on_boss_damaged(boss: Enemy) -> void:
	boss_health_bar.value = boss.health


## The boss reached half of its health: it turns red and bigger (Enemy) and
## the screen says it, with a shake.
func _on_boss_phase_changed(boss: Enemy) -> void:
	shake_camera(BOSS_PHASE2_SHAKE, BOSS_PHASE2_SHAKE_TIME)
	var text := boss.enemy_type.phase2_text
	if text == "":
		text = "¡%s está furioso!" % boss.enemy_type.display_name
	wave_banner.show_message(text)


func _on_boss_died(_boss: Enemy) -> void:
	boss_bar.hide()


## Victory: every wave has appeared and no enemy is left alive (WaveManager checks it).
func _on_all_waves_cleared() -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.VICTORY
	get_tree().paused = true  # freezes the board behind the panel
	AudioManager.play_jingle(AudioManager.VICTORY_MUSIC)
	var grade := current_grade()
	var previous_grade := ProgressRepository.get_grade(GameSession.current_world(), GameSession.level_index)
	# The progress moves on and is saved right away (the grade only if it is better).
	var save_error := GameSession.complete_current_level(grade)
	ProgressRepository.mark_known("cards", [level.reward_card])  # null is ignored
	await dialogue_box.play_once(level.outro_dialogue)  # the game stays paused after it
	victory_panel.show_victory(GameSession.current_level_number(), level.display_name, grade,
			previous_grade, not GameSession.has_next_level())
	if save_error != OK:
		save_error_panel.show_error()  # drawn on top of the Victory panel


## "Reintentar" on the save error notice.
func _on_save_retry_requested() -> void:
	if ProgressRepository.save_progress() == OK:
		save_error_panel.hide()
	else:
		save_error_panel.show_retry_failed()


## An enemy entered the safe zone. If its lane still has its Extraordinario,
## the Extraordinario runs along the lane (or is already running and will
## remove it); otherwise, or if the level does not use them (rule of the 1.0), defeat.
func _on_enemy_reached_safe_zone(enemy: Enemy) -> void:
	if phase != Phase.PLAYING:
		return
	if enemy and not extraordinarios.is_empty():
		var extraordinario := extraordinarios[enemy.lane]
		if extraordinario.state == Extraordinario.State.READY:
			extraordinario.trigger()
			extraordinarios_used += 1
			AudioManager.play_sfx(AudioManager.SFX_EXTRAORDINARIO)
			AudioManager.vibrate()
			notice.show_message("¡Extraordinario! Calificación máxima: %d" % current_grade())
			return
		if extraordinario.can_save():
			return  # it is already running along this lane and will remove the enemy
	phase = Phase.DEFEAT
	get_tree().paused = true  # freezes the board behind the panel
	AudioManager.play_jingle(AudioManager.DEFEAT_MUSIC)
	defeat_panel.show()       # it keeps working: its mode is "When Paused"


# --- Pause ---

func pause_game() -> void:
	get_tree().paused = true  # every Pausable node stops (_process, Timers and input)
	pause_menu.show()         # the menu keeps working: its mode is "When Paused"


func resume_game() -> void:
	pause_menu.hide()
	get_tree().paused = false


## The scene stays paused behind the fade; SceneTransition unpauses it
## right before the change, so the new scene does not start paused.
func _on_restart_requested() -> void:
	SceneTransition.reload_scene()


## "Siguiente nivel", or "Continuar" after the last level of the world.
func _on_next_level_requested() -> void:
	if GameSession.has_next_level():
		GameSession.start_next_level()
	else:
		GameSession.open_world_complete()


## Pause, Defeat and Victory go back to the level select of this world.
func _on_exit_requested() -> void:
	GameSession.open_level_select()


func _notification(what: int) -> void:
	# Notifications arrive even while paused.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# The app went to the background (call, home button...): pause it.
		# ProgressRepository saves at the same moment.
		if phase == Phase.PLAYING and not get_tree().paused:
			pause_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if SceneTransition.is_changing:
			return  # the screen is already changing
		if dialogue_box.is_open():
			dialogue_box.finish()  # back = "Saltar"
			return
		if phase == Phase.PLAYING:
			# Android back button: opens or closes the pause menu.
			if get_tree().paused:
				resume_game()
			else:
				pause_game()
		else:
			# After a victory or a defeat it works like "Selección de nivel".
			# The progress was already saved (or kept in memory) when the level was won.
			_on_exit_requested()
