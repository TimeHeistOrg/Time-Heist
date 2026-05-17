@tool
extends UI	


const CELL_SIZE = 64  # pixel width and height of each cell
const PIPE_ROW = preload("res://Modules/UI/Game UI/Pipe Game/pipe_row.tscn")
const PIPE_CELL = preload("res://Modules/UI/Game UI/Pipe Game/pipe_cell.tscn")

signal pipe_game_solved

@export var mouse_visible_on_start: bool = false
@export_group("Pipe Board Settings")
@export_range(2, 10) var width: int = 5
@export_range(2, 10) var height: int = 5
@export_tool_button("Generate Board") var gen_board_btn = func(): _gen_board()
@export_group("")

# 2d array PipeCell nodes representing the board
var board: Array = []

# generates the board UI
func _gen_board() -> void:
	print("Generating %dx%d board..." % [width, height])
	
	# clear all children and reset board
	for c in get_children():
		c.free()
	board.clear()
	
	# create background holder
	var background = ColorRect.new()
	background.name = "Background"
	background.color = Color.WHITE
	background.size = Vector2(width * CELL_SIZE, height * CELL_SIZE)
	background.position = Vector2(
		(1920 - width*CELL_SIZE) / 2.0,
		(1080 - height*CELL_SIZE) / 2.0
	)
	add_child(background)
	background.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
	
	# make the rows
	for r in range(height):
		var cur_row = PIPE_ROW.instantiate()
		cur_row.name = "Row %d" % r
		cur_row.position = Vector2(0, r * CELL_SIZE)
		cur_row.size = Vector2(width * CELL_SIZE, CELL_SIZE)
		background.add_child(cur_row)
		cur_row.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
		
		# make the cells within the row
		var row_cells: Array = []
		for c in range(width):
			var cell = PIPE_CELL.instantiate()
			cell.name = "Cell_(%d, %d)" % [r, c]
			cell.position = Vector2(c * CELL_SIZE, 0)
			cell.size = Vector2(CELL_SIZE, CELL_SIZE)
			cell.row = r
			cell.col = c
			cur_row.add_child(cell)
			cell.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else null
			row_cells.append(cell)
			cell.init(r, c)
			if not Engine.is_editor_hint():
				cell.rotation_changed.connect(_on_cell_updated)

		
		# add row to board
		board.append(row_cells)
		
	_build_board_from_scene()

# handler for when a cell emit's its signal when it's rotated
func _on_cell_updated(row: int, col: int) -> void:
	print("cell at (%d, %d) was updated" % [row, col])
	_check_puzzle_solve_state()

# checks if the puzzle is solved, emits signal if solved
func _check_puzzle_solve_state() -> void:
	if board.is_empty():
		print("tried to check puzzle solve but the board is empty")
		return
		
	# find start cell
	var start_cell: Node = null
	for row in board:
		for cell in row:
			if cell.is_start_pipe:
				start_cell = cell
				break
		if start_cell:
			break
	
	if start_cell == null:
		print("couldnt find start cell")
		return
		
	# bfs from start and look if end node is connected
	var visited = {}  # dict since theres no set (value can be whatever)
	var cell_queue = [start_cell]
	
	while not cell_queue.is_empty():
		# check if current cell is visited or add it to visited
		var cur_cell = cell_queue.pop_front()
		var cur_cell_key = "%d %d" % [cur_cell.row, cur_cell.col]
		if visited.has(cur_cell_key):
			continue
		visited[cur_cell_key] = true
		
		# check if current cell is end
		if cur_cell.is_end_pipe:
			pipe_game_solved.emit()
			print("puzzle solved")
			return
			
		# get and add neighbors to queue if not visited
		var cur_cell_neighbors = _get_cell_neighbors(cur_cell)
		for neighbor_cell in cur_cell_neighbors:
			var neighbor_key = "%d %d" % [neighbor_cell.row, neighbor_cell.col]
			if not visited.has(neighbor_key):
				cell_queue.append(neighbor_cell)
	
	# did not find end pipe connection
	print("puzzle is not solved")
		
func _get_cell_neighbors(cell: Node) -> Array:
	var row = cell.row
	var col = cell.col
	var res = []
	
	# list of all directions to check, each subarray represents the following:
	# [row offset, col offset, direction from cell, direction from neighbor]
	# direction numbers: 0 = up, 1 = right, 2 = down, 3 = left
	var directions_to_check = [
		[-1, 0, 0, 2], # up -> cell opens up / neighbor opens down
		[0, 1, 1, 3], # right -> cell opens right / neighbor opens left
		[1, 0, 2, 0], # down -> cell opens down / neighbor opens up
		[0, -1, 3, 1] # left -> cell opens left / neighbor opens right
	]
	
	# go through each direction and check
	for direction in directions_to_check:
		var neighbor_row = row + direction[0]
		var neighbor_col = col + direction[1]
		if neighbor_row < 0 or neighbor_row >= height or neighbor_col < 0 or neighbor_col >= width:
			continue
		var neighbor = board[neighbor_row][neighbor_col]
		var cell_open_sides = cell.get_open_sides()
		var neighbor_open_sides = neighbor.get_open_sides()
		if direction[2] in cell_open_sides and direction[3] in neighbor_open_sides:
			res.append(neighbor)
			
	return res
		

func _ready() -> void:	
	if not Engine.is_editor_hint():
		close()
		if mouse_visible_on_start:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	# the signal get funky since they are made in the editor/before runtime or something
	# so i found this approach to fix it...
	# there's probably a cleaner way but idk
	_build_board_from_scene()

func _build_board_from_scene() -> void:
	board.clear()
	var background = get_child(0)
	
	for row_node in background.get_children():
		var row_cells: Array = []
		for cell in row_node.get_children():
			if not Engine.is_editor_hint():
				cell.rotation_changed.connect(_on_cell_updated)
			row_cells.append(cell)
		board.append(row_cells)
