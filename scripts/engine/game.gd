extends Node2D
## Root of the game scene.
## It owns the energy and the phase of the match (playing, victory, defeat),
## connects the signals between entities and UI, places defenders,
## spawns the enemies WaveManager asks for, and handles play time and pause.
## The level it plays comes from the ProgressRepository Autoload.

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")

enum Phase { PLAYING, VICTORY, DEFEAT }

## Data of the level being played (name, start energy, defenders and waves).
var level: LevelData
## Seconds of play. It stops while the game is paused because this node
## uses the default process mode (Inherit -> Pausable).
var elapsed_time := 0.0
var energy := 0
var phase := Phase.PLAYING

@onready var board: Board = $Board
@onready var defenders: Node2D = $Defenders
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var orbs: Node2D = $Orbs
@onready var hud: Hud = $UI/HUD
@onready var hint: Label = $UI/Hint
@onready var notice: Notice = $UI/Notice
@onready var pause_menu: PauseMenu = $UI/PauseMenu
@onready var defeat_panel: DefeatPanel = $UI/DefeatPanel
@onready var victory_panel: VictoryPanel = $UI/VictoryPanel
@onready var wave_manager: WaveManager = $WaveManager


func _ready() -> void:
	level = ProgressRepository.get_current_level()
	energy = level.start_energy
	hud.set_level_name(ProgressRepository.get_current_level_number(), level.display_name)
	hud.create_cards(level.defenders)  # one card per defender available in this level

	board.cell_tapped.connect(_on_board_cell_tapped)
	hud.pause_pressed.connect(pause_game)
	hud.card_pressed.connect(_on_card_pressed)
	pause_menu.resume_requested.connect(resume_game)
	pause_menu.restart_requested.connect(_on_restart_requested)
	pause_menu.exit_requested.connect(_on_exit_requested)
	defeat_panel.retry_requested.connect(_on_restart_requested)
	defeat_panel.home_requested.connect(_on_exit_requested)
	victory_panel.next_requested.connect(_on_next_level_requested)
	victory_panel.home_requested.connect(_on_exit_requested)
	wave_manager.spawn_requested.connect(spawn_enemy)
	wave_manager.wave_started.connect(hud.set_wave)
	wave_manager.wave_progress.connect(hud.set_wave_progress)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	hud.set_energy(energy)
	_update_hint()
	wave_manager.start(level.waves)


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
	if card == hud.selected_card:
		hud.clear_selection()  # tapping the selected card again cancels it
	elif card.is_recharging():
		notice.show_message("%s se está recargando" % type.display_name)
	elif energy < type.cost:
		notice.show_message("Energía insuficiente: faltan %d" % (type.cost - energy))
	else:
		hud.select_card(card)


func _on_board_cell_tapped(lane: int, column: int) -> void:
	board.highlight_cell(lane, column)
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

	board.occupy_cell(lane, column, defender)
	spend_energy(type.cost)
	_update_hint()


func _on_defender_died(defender: Defender) -> void:
	board.free_cell(defender.lane, defender.column)
	_update_hint()


## The empty-board hint is visible only while there are no defenders.
func _update_hint() -> void:
	hint.visible = board.is_empty()


# --- Energy orbs ---

func _on_orb_produced(orb: EnergyOrb) -> void:
	orbs.add_child(orb)
	# The orb's position is its top-left corner, so we subtract half its size to center it.
	orb.global_position = board.cell_to_pixel(orb.lane, orb.column) - orb.size / 2.0
	orb.collected.connect(add_energy)


# --- Projectiles ---

func _on_shot_fired(projectile: Projectile) -> void:
	projectile.board = board  # the projectile uses it to draw itself
	projectiles.add_child(projectile)


# --- Enemies and waves ---

## WaveManager asks for each enemy through its spawn_requested signal.
func spawn_enemy(type: EnemyType, lane: int) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(type, lane, board)
	enemy.reached_safe_zone.connect(_on_enemy_reached_safe_zone)
	enemies.add_child(enemy)


## Victory: every wave has appeared and no enemy is left alive (WaveManager checks it).
func _on_all_waves_cleared() -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.VICTORY
	get_tree().paused = true  # freezes the board behind the panel
	var level_number := ProgressRepository.get_current_level_number()
	var has_next := ProgressRepository.has_next_level()
	ProgressRepository.complete_level()  # the progress moves on right away
	if has_next:
		victory_panel.show_level_cleared(level_number, level.display_name)
	else:
		victory_panel.show_world_cleared(ProgressRepository.get_world().display_name)


func _on_enemy_reached_safe_zone(_enemy: Enemy) -> void:
	if phase != Phase.PLAYING:
		return
	phase = Phase.DEFEAT
	get_tree().paused = true  # freezes the board behind the panel
	defeat_panel.show()       # it keeps working: its mode is "When Paused"


# --- Pause ---

func pause_game() -> void:
	get_tree().paused = true  # every Pausable node stops (_process, Timers and input)
	pause_menu.show()         # the menu keeps working: its mode is "When Paused"


func resume_game() -> void:
	pause_menu.hide()
	get_tree().paused = false


func _on_restart_requested() -> void:
	get_tree().paused = false  # the new scene must not start paused
	get_tree().reload_current_scene()


## ProgressRepository already points to the next level,
## so reloading the scene starts it.
func _on_next_level_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_requested() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _notification(what: int) -> void:
	# Notifications arrive even while paused.
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		# The app went to the background (call, home button...): pause it.
		if not get_tree().paused:
			pause_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST and phase == Phase.PLAYING:
		# Android back button: opens or closes the pause menu
		# (not after a victory or a defeat: their panel must stay on screen).
		if get_tree().paused:
			resume_game()
		else:
			pause_game()
