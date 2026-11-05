extends Node2D
## Performance test of Block 10 (plan, section 7.2): the real board with
## BENCH_ENEMIES animated enemies always on screen, defenders that shoot,
## produce orbs and get bitten (damage stages, smoke, falling pieces), and all
## the particles of the block. After WARMUP seconds it measures for DURATION
## seconds and shows the average fps and the "1 % low" (the slowest frames).
## Goal: average >= TARGET_FPS on the weakest phone of the team.
##
## Open it from the hidden debug panel of Inicio (tap the logo 5 times, debug
## builds only) or, on PC, run this scene (F6). With "-- --benchmark-quit" on
## the command line it prints the result and closes (for automated runs).

const BENCH_ENEMIES := 30
const WARMUP := 2.0
const DURATION := 20.0
const TARGET_FPS := 50.0
const ENEMY_TYPES: Array[EnemyType] = [
	preload("res://data/enemies/tarea_infinita.tres"),
	preload("res://data/enemies/examen_sorpresa.tres"),
	preload("res://data/enemies/diapositivas.tres"),
]
const CAFE := preload("res://data/defenders/cafe.tres")
const LAPTOP := preload("res://data/defenders/laptop.tres")
const FIREWALL := preload("res://data/defenders/firewall.tres")
const ENEMY_SCENE := preload("res://scenes/entities/enemy.tscn")
const MENU_SCENE := "res://scenes/ui/main_menu.tscn"

var elapsed := 0.0
var measuring := false
var frame_times: PackedFloat32Array = []
var spawned := 0
var done := false

@onready var board: Board = $Board
@onready var defenders: Node2D = $Defenders
@onready var enemies: Node2D = $Enemies
@onready var projectiles: Node2D = $Projectiles
@onready var orbs: Node2D = $Orbs
@onready var result_label: Label = %ResultLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	back_button.pressed.connect(func(): SceneTransition.change_scene(MENU_SCENE))
	for lane in Board.LANES:
		_place(CAFE, lane, 0)
		_place(LAPTOP, lane, 1)
		_place(FIREWALL, lane, 3)
	for i in BENCH_ENEMIES:
		_spawn(randf_range(3.6, Enemy.SPAWN_COLUMN))
	result_label.text = "Preparando… (%d enemigos)" % BENCH_ENEMIES


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	# keep BENCH_ENEMIES on screen and the walls standing
	while enemies.get_child_count() - _dying_enemies() < BENCH_ENEMIES:
		_spawn(Enemy.SPAWN_COLUMN)
	for lane in Board.LANES:
		if not board.is_occupied(lane, 3):
			_place(FIREWALL, lane, 3)
	if elapsed < WARMUP:
		return
	if not measuring:
		measuring = true
		elapsed = WARMUP
	frame_times.append(delta)
	result_label.text = "Midiendo… %d s · %d fps" % [ceili(WARMUP + DURATION - elapsed), Engine.get_frames_per_second()]
	if elapsed >= WARMUP + DURATION:
		_finish()


func _dying_enemies() -> int:
	var n := 0
	for enemy in enemies.get_children():
		if enemy.is_queued_for_deletion():
			n += 1
	return n


func _spawn(column: float) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.setup(ENEMY_TYPES[spawned % ENEMY_TYPES.size()], spawned % Board.LANES, board, column)
	spawned += 1
	enemy.reached_safe_zone.connect(func(e: Enemy): e.queue_free())
	enemies.add_child(enemy)


func _place(type: DefenderType, lane: int, column: int) -> void:
	var defender: Defender = type.behavior_scene.instantiate()
	defender.setup(type, lane, column)
	defenders.add_child(defender)
	defender.global_position = board.cell_to_pixel(lane, column)
	defender.died.connect(func(d: Defender): board.free_cell(d.lane, d.column))
	if defender is GeneratorDefender:
		defender.orb_produced.connect(_on_orb_produced)
	elif defender is ShooterDefender:
		defender.shot_fired.connect(_on_shot_fired)
	board.occupy_cell(lane, column, defender)


func _on_orb_produced(orb: EnergyOrb) -> void:
	orbs.add_child(orb)
	orb.global_position = board.cell_to_pixel(orb.lane, orb.column) - orb.size / 2.0


func _on_shot_fired(projectile: Projectile) -> void:
	projectile.board = board
	projectiles.add_child(projectile)


## Average fps = frames / seconds. "1 % low" = fps of the slowest 1 % of the frames.
func _finish() -> void:
	done = true
	var total := 0.0
	for t in frame_times:
		total += t
	var sorted := frame_times.duplicate()
	sorted.sort()
	var worst := sorted.slice(int(sorted.size() * 0.99))
	var worst_avg := 0.0
	for t in worst:
		worst_avg += t
	worst_avg /= maxi(worst.size(), 1)
	var avg_fps := frame_times.size() / total
	var low_fps := 1.0 / worst_avg if worst_avg > 0.0 else 0.0
	var ok := avg_fps >= TARGET_FPS
	result_label.text = "%d enemigos · %d s\nFPS medio: %.1f · 1 %% más lento: %.1f\nObjetivo ≥ %d: %s" % [
			BENCH_ENEMIES, DURATION, avg_fps, low_fps, TARGET_FPS, "CUMPLE" if ok else "NO CUMPLE"]
	print("BENCHMARK enemies=%d seconds=%d frames=%d avg_fps=%.1f low1_fps=%.1f target=%d %s renderer=%s device=%s" % [
			BENCH_ENEMIES, DURATION, frame_times.size(), avg_fps, low_fps, TARGET_FPS, "PASS" if ok else "FAIL",
			RenderingServer.get_current_rendering_driver_name(), OS.get_model_name()])
	if "--benchmark-quit" in OS.get_cmdline_user_args():
		get_tree().quit()
