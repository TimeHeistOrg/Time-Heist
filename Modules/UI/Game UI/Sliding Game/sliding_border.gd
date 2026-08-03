@tool
extends Control
class_name SlidingBorder

# Represents the collection of border tiles that come together and make the border for the game

## Number of rows INSIDE the border
@export var grid_rows: int = 6:
	set(v):
		grid_rows = max(1, v)
## Number of columns INSIDE the border
@export var grid_cols: int = 6:
	set(v):
		grid_cols = max(1, v)
# Exit specification (based on inner grid inside the border)
## 0=Top, 1=Bottom, 2=Left, 3=Right
@export var exit_side: int = 3 
## which row/col the exit begins (inner grid location) (0-indexed)
@export var exit_start: int = 2 
## how many cells wide/tall the exit is
@export var exit_size: int = 2 
# Press button to generate the border
@export_tool_button("Generate Border") var gen_border_btn = func(): _generate_border()

const CELL_SIZE := 64.0
const BORDER_TILE := preload("res://Modules/UI/Game UI/Sliding Game/sliding_border_tile.tscn")

# Get the current cell size
func get_cell_size() -> float:
	return CELL_SIZE

# Return grid position (col, row) of the exit tile or (-1, -1) if it doesn't exist
func get_exit_grid_pos() -> Vector2i:
	for c: Control in get_children():
		if c.get("is_exit"):
			var px := c.position.x
			var py := c.position.y
			var col := int(round(px / CELL_SIZE)) - 1
			var row := int(round(py / CELL_SIZE)) - 1
			return Vector2i(col, row)
	print("ERROR: Couldn't find is_exit as true on any children")
	return Vector2i(-1, -1)
	
# Get the side the exit is on (0 = Top, 1 = Bottom, 2 = Left, 3 = Right, -1 = Error)
func get_exit_side() -> int:
	for c in get_children():
		if c.get("is_exit"):
			return c.get("side") if c.get("side") != null else -1
	return -1

# Creates the border
func _generate_border() -> void:
	# Get rid of old children
	for c in get_children():
		c.free()
		
	# Border occupies col 0, col grid_cols+1, row 0, row grid_rows+1
	# Game area occupies col 1...grid_cols, row 1...grid_rows
	var total_cols := grid_cols + 2
	var total_rows := grid_rows + 2

	# Create each border tile
	for r in range(total_rows):
		for c in range(total_cols):
			# check if border cell
			if r != 0 and r != total_rows-1 and c != 0 and c != total_cols-1:
				continue

			# create tile
			var tile: Control = BORDER_TILE.instantiate()
			tile.name = "BorderTile_%d_%d" % [c, r]
			tile.position = Vector2(c * CELL_SIZE, r * CELL_SIZE)

			# set the side
			var side := 0
			if r == 0: side = 0 # top
			elif r == total_rows-1: side = 1 # bottom
			elif c == 0: side = 2 # left
			else: side = 3 # right
			if tile.get("side") != null:
				tile.side = side

			# exit setting
			var loc := (c - 1) if (side == 0 or side == 1) else (r - 1)
			var is_exit_tile := (side == exit_side) and \
								(loc >= exit_start) and \
								(loc < exit_start + exit_size)
			if tile.get("is_exit") != null:
				tile.is_exit = is_exit_tile

			# add child
			add_child(tile)
			tile.owner = get_tree().edited_scene_root if Engine.is_editor_hint() else owner

	print("Created %dx%d border (play size %d, %d)" % [total_rows, total_cols, grid_rows, grid_cols])

# get exit region stats
func get_exit_area() -> Dictionary:
	return {
		"side": exit_side,
		"start": exit_start,
		"size": exit_side
	}
