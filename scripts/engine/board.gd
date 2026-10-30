class_name Board
extends Node2D
## The 5x9 game board.
## It draws the grid, converts between cells and pixels,
## and knows which cells are occupied by a defender.
## Game logic always talks in cells (lane, column); pixels are only for drawing.
## The node's position is the top-left corner of the grid.

## Emitted when the player taps (or clicks) a cell of the grid.
signal cell_tapped(lane: int, column: int)

const LANES := 5          # rows, counted from top (0) to bottom (4)
const COLUMNS := 9        # counted from left (0) to right (8)
const CELL_SIZE := 120.0  # size of one square cell, in pixels
const SAFE_ZONE_WIDTH := 80.0  # strip on the left that enemies must not reach

const COLOR_CELL_A := Color("1f1a3d")
const COLOR_CELL_B := Color("262049")
const COLOR_GRID_LINE := Color("3a3366")
const COLOR_SAFE_ZONE := Color("6d3fe0", 0.35)
const COLOR_ENTRY_LINE := Color("f4f2ff", 0.4)
const COLOR_HIGHLIGHT := Color("ffd43b")

## Cell currently highlighted. x = column, y = lane. (-1, -1) means none.
var highlighted_cell := Vector2i(-1, -1)

## Occupied cells. Key: Vector2i(column, lane). Value: the defender standing there.
var occupied_cells: Dictionary[Vector2i, Defender] = {}


## Returns the center of a cell in global (screen) pixels.
## Accepts decimals, so an enemy at column 6.4 is drawn between cells 6 and 7.
func cell_to_pixel(lane: float, column: float) -> Vector2:
	var local_position := Vector2((column + 0.5) * CELL_SIZE, (lane + 0.5) * CELL_SIZE)
	return to_global(local_position)


## Returns the cell under a global pixel position. x = column, y = lane.
## The result can be outside the board; check it with is_inside().
func pixel_to_cell(global_position_px: Vector2) -> Vector2i:
	var local_position := to_local(global_position_px)
	var column := floori(local_position.x / CELL_SIZE)
	var lane := floori(local_position.y / CELL_SIZE)
	return Vector2i(column, lane)


func is_inside(lane: int, column: int) -> bool:
	return lane >= 0 and lane < LANES and column >= 0 and column < COLUMNS


func highlight_cell(lane: int, column: int) -> void:
	highlighted_cell = Vector2i(column, lane)
	queue_redraw()  # asks Godot to call _draw() again


func clear_highlight() -> void:
	highlighted_cell = Vector2i(-1, -1)
	queue_redraw()


func is_occupied(lane: int, column: int) -> bool:
	return occupied_cells.has(Vector2i(column, lane))


func is_empty() -> bool:
	return occupied_cells.is_empty()


## Registers a defender in a cell. Game calls it right after placing one.
func occupy_cell(lane: int, column: int, defender: Defender) -> void:
	occupied_cells[Vector2i(column, lane)] = defender


## Frees a cell (for example, when its defender dies).
func free_cell(lane: int, column: int) -> void:
	occupied_cells.erase(Vector2i(column, lane))


func _unhandled_input(event: InputEvent) -> void:
	# A finger tap arrives here as a left mouse click thanks to the project
	# setting "Emulate Mouse From Touch", so the same code works on PC and phone.
	# Taps on buttons never get here, because the UI consumes them first.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := pixel_to_cell(event.position)
		if is_inside(cell.y, cell.x):
			cell_tapped.emit(cell.y, cell.x)
			get_viewport().set_input_as_handled()


func _draw() -> void:
	var board_width := COLUMNS * CELL_SIZE
	var board_height := LANES * CELL_SIZE

	# Safe zone on the left of the grid.
	draw_rect(Rect2(-SAFE_ZONE_WIDTH, 0, SAFE_ZONE_WIDTH, board_height), COLOR_SAFE_ZONE)

	# Cells in a checkerboard pattern, so the player can tell them apart.
	for lane in LANES:
		for column in COLUMNS:
			var color := COLOR_CELL_A if (lane + column) % 2 == 0 else COLOR_CELL_B
			draw_rect(Rect2(column * CELL_SIZE, lane * CELL_SIZE, CELL_SIZE, CELL_SIZE), color)

	# Grid lines.
	for lane in LANES + 1:
		draw_line(Vector2(0, lane * CELL_SIZE), Vector2(board_width, lane * CELL_SIZE), COLOR_GRID_LINE, 2.0)
	for column in COLUMNS + 1:
		draw_line(Vector2(column * CELL_SIZE, 0), Vector2(column * CELL_SIZE, board_height), COLOR_GRID_LINE, 2.0)

	# Dashed line on the right, where enemies will come in.
	draw_dashed_line(Vector2(board_width, 0), Vector2(board_width, board_height), COLOR_ENTRY_LINE, 3.0, 12.0)

	# Highlighted cell (false = only the outline, not filled).
	if is_inside(highlighted_cell.y, highlighted_cell.x):
		var rect := Rect2(highlighted_cell.x * CELL_SIZE, highlighted_cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE)
		draw_rect(rect.grow(-4), COLOR_HIGHLIGHT, false, 6.0)
