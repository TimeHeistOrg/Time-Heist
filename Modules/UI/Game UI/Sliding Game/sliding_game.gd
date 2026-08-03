@tool
extends Control
class_name SlidingGame

const CELL_SIZE := 64.0

## Must match border grid_cols
@export var grid_cols: int = 6
## Must match border grid_rows
@export var grid_rows: int = 6
# Gap between block visual and cell edge
var gap: float = 4.0
# Pixel offset of the inner grid's (0,0) corner relative to this node.
var inner_grid_offset: Vector2 = Vector2(CELL_SIZE, CELL_SIZE)
# Name of the BoardBorder child node
var border_node_path: NodePath = ^"SlidingBorder"

# Occupancy grid:  _grid[row][col] = SlidingBlock or null
var _grid: Array = []
var _blocks: Array[SlidingBlock] = []
var _target_block: SlidingBlock = null
var _exit_side: int = -1 # 0=Top,1=Bottom,2=Left,3=Right
var _exit_start: int = -1 # which row/col the exit begins (inner grid location)
var _exit_size: int = -1 # how many cells wide/tall the exit is

# emitted when puzzle is solved
signal puzzle_solved

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_init_grid()
	_collect_blocks()
	_read_exit()
	_place_all_blocks()

# create 2d grid array
func _init_grid() -> void:
	_grid = []
	for r in range(grid_rows):
		var row_arr := []
		for c in range(grid_cols):
			row_arr.append(null)
		_grid.append(row_arr)

# iterate through all sliding blocks and save their refs
func _collect_blocks() -> void:
	_blocks.clear()
	_target_block = null
	for child in $BlockHolder.get_children():
		if child is SlidingBlock:
			var sb := child as SlidingBlock
			sb.board = self
			_blocks.append(sb)
			if sb.is_target:
				_target_block = sb

# get exit area information
func _read_exit() -> void:
	var border = get_node_or_null(border_node_path)
	if border == null:
		push_warning("SlidingPuzzle: BoardBorder not found at '%s'" % border_node_path)
		return
	var exit_area = border.get_exit_area()
	_exit_side = exit_area["side"]
	_exit_start = exit_area["start"]
	_exit_size = exit_area["size"]

# update grid with block placements
func _place_all_blocks() -> void:
	for sb in _blocks:
		# Derive grid position from pixel position
		var px := sb.position.x - inner_grid_offset.x
		var py := sb.position.y - inner_grid_offset.y
		sb.grid_col = int(round(px / CELL_SIZE))
		sb.grid_row = int(round(py / CELL_SIZE))
		_occupy(sb, sb.grid_col, sb.grid_row)
		sb.board = self
		sb.queue_redraw()
		snap_block_visual(sb)

# returns true if col and row are in bounds of the grid
func _in_bounds(col: int, row: int) -> bool:
	return col >= 0 and col < grid_cols and row >= 0 and row < grid_rows

# adds block to grid 2d array
func _occupy(block: SlidingBlock, col: int, row: int) -> void:
	for r in range(row, row + block.height):
		for c in range(col, col + block.width):
			if _in_bounds(c, r):
				_grid[r][c] = block

# removes block from grid 2d array
func _vacate(block: SlidingBlock) -> void:
	for r in range(block.grid_row, block.grid_row + block.height):
		for c in range(block.grid_col, block.grid_col + block.width):
			if _in_bounds(c, r):
				_grid[r][c] = null

# returns if a grid cell is free (either open or ignored block is present)
func _is_free(col: int, row: int, ignore_block: SlidingBlock) -> bool:
	if not _in_bounds(col, row):
		return false
	var occ = _grid[row][col]
	return occ == null or occ == ignore_block

# clamps block to a column
func clamp_block_col(block: SlidingBlock, desired_col: int) -> int:
	return clampi(desired_col, 0, grid_cols - block.width)

# clamps block to a row
func clamp_block_row(block: SlidingBlock, desired_row: int) -> int:
	return clampi(desired_row, 0, grid_rows - block.height)

# Try to move block to new col and new row, only works if the path is unobstructed
func try_move_block(block: SlidingBlock, new_col: int, new_row: int) -> void:
	if new_col == block.grid_col and new_row == block.grid_row:
		return

	var target_col := new_col
	var target_row := new_row

	# Horizontal move
	if new_col != block.grid_col:
		var step: int = sign(new_col - block.grid_col)
		var safe_col := block.grid_col
		var test_col := block.grid_col + step
		while test_col != new_col + step:
			if not _path_free_h(block, test_col):
				break
			safe_col = test_col
			test_col += step
		target_col = safe_col
		target_row = block.grid_row

	# Vertical move
	elif new_row != block.grid_row:
		var step: int = sign(new_row - block.grid_row)
		var safe_row := block.grid_row
		var test_row := block.grid_row + step
		while test_row != new_row + step:
			if not _path_free_v(block, test_row):
				break
			safe_row = test_row
			test_row += step
		target_row = safe_row
		target_col = block.grid_col

	if target_col == block.grid_col and target_row == block.grid_row:
		return   # no movement possible

	# remove block from old spot and move it to new spot
	_vacate(block)
	block.grid_col = target_col
	block.grid_row = target_row
	_occupy(block, target_col, target_row)
	snap_block_visual(block)

	_check_escape(block)

# Move block's visual position to match its grid coordinates
func snap_block_visual(block: SlidingBlock) -> void:
	block.position = inner_grid_offset + Vector2(
		block.grid_col * CELL_SIZE,
		block.grid_row * CELL_SIZE
	)


# Check if horizontal path is open
func _path_free_h(block: SlidingBlock, new_col: int) -> bool:
	if new_col < 0 or new_col + block.width - 1 >= grid_cols:
		return false
	var col_face := new_col if new_col < block.grid_col else new_col + block.width - 1
	for r in range(block.grid_row, block.grid_row + block.height):
		if not _is_free(col_face, r, block):
			return false
	return true

# Check if vertical path is open
func _path_free_v(block: SlidingBlock, new_row: int) -> bool:
	if new_row < 0 or new_row + block.height - 1 >= grid_rows:
		return false
	var row_face := new_row if new_row < block.grid_row else new_row + block.height - 1
	for c in range(block.grid_col, block.grid_col + block.width):
		if not _is_free(c, row_face, block):
			return false
	return true

# Checks if the target block has escaped
func _check_escape(block: SlidingBlock) -> void:
	if not block.is_target:
		return
	if _exit_side < 0:
		return

	var escaped := false

	match _exit_side:
		0:  # Top
			if block.grid_row == 0:
				escaped = _block_aligns_exit(block)
		1:  # Bottom
			if block.grid_row + block.height - 1 == grid_rows - 1:
				escaped = _block_aligns_exit(block)
		2:  # Left
			if block.grid_col == 0:
				escaped = _block_aligns_exit(block)
		3:  # Right
			if block.grid_col + block.width - 1 == grid_cols - 1:
				escaped = _block_aligns_exit(block)

	if escaped:
		_on_puzzle_solved(block)

# Check that the exit position overlaps with the block along the perpendicular axis.
func _block_aligns_exit(block: SlidingBlock) -> bool:
	var block_start: int
	var block_size: int
	if _exit_side == 0 or _exit_side == 1: # top/bottom compare columns
		block_start = block.grid_col
		block_size = block.width
	else:
		block_start = block.grid_row
		block_size = block.height 
	
	return block_start >= _exit_start and \
		   block_start+block_size <= _exit_start+_exit_size

func _on_puzzle_solved(block: SlidingBlock) -> void:
	print("Puzzle solved")
	emit_signal("puzzle_solved")
	_slide_block_exit(block)

# slide the block away (temp for visualization)
func _slide_block_exit(block: SlidingBlock) -> void:
	var tween := create_tween()
	var end := Vector2.ZERO
	match _exit_side:
		0:
			end = Vector2(0, -2*CELL_SIZE)
		1:
			end = Vector2(0, 2*CELL_SIZE)
		2:
			end = Vector2(-2*CELL_SIZE, 0)
		3:
			end = Vector2(2*CELL_SIZE, 0)
	tween.tween_property(block, "position", block.position + end, 1.0)
	
