@tool
extends Control
class_name SlidingBlock

# Represents a slidable block

## Width of the block (1, 2, 3)
@export_range(1, 3) var width: int = 1:
	set(v):
		width = v
		queue_redraw()
## Height of the block (1, 2, 3)
@export_range(1, 3) var height: int = 1:
	set(v):
		height = v
		queue_redraw()
## Which axes can be slid upon
@export_flags("Horizontal", "Vertical") var slide_axes: int = 1 # default horizontal only
## Used to indicate the target block that must be freed
@export var is_target: bool = false
## Visual color for block
@export var block_color: Color = Color(0.85, 0.55, 0.25)
@export var target_color: Color = Color(0.85, 0.1, 0.1)

# Column of block's top left cell
var grid_col: int = 0
# Row of block's top left cell
var grid_row: int = 0
 
# Refrence to board
var board: Node = null
const CELL_SIZE := 64.0
const GAP := 4.0
 
# Vars for dragging related behavior
var _dragging: bool = false
var _drag_start_mouse: Vector2 = Vector2.ZERO
var _drag_start_col: int = 0
var _drag_start_row: int = 0
var _drag_axis: int = 0   # 0 = undecided, 1 = H, 2 = V
const AXIS_THRESHOLD := 8.0   # pixels before axis is locked
 
# Returns true if it can slide horizontally
func can_slide_horizontal() -> bool:
	return (slide_axes & 1) != 0

# Returns true if it can slide vertically
func can_slide_vertical() -> bool:
	return (slide_axes & 2) != 0 
 
func _ready() -> void:
	queue_redraw()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()

# Create visual color of the block
func _draw() -> void:
	if board == null and not Engine.is_editor_hint():
		return
	
	var rect := Rect2(GAP * 0.5, GAP * 0.5,
					  width * CELL_SIZE - GAP,
					  height * CELL_SIZE - GAP)
	var color := target_color if is_target else block_color
	draw_rect(rect, color, true)
	# border
	draw_rect(rect, color.darkened(0.3), false, 2.0)

# Handles input for dragging
func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or board == null:
		return
 
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_try_start_drag(mb.global_position)
			else:
				_end_drag()
 
	elif event is InputEventMouseMotion:
		if _dragging:
			_update_drag((event as InputEventMouseMotion).global_position)
 
# Check if mouse is inside this block
func _try_start_drag(mouse_pos: Vector2) -> void:
	var cell = board.CELL_SIZE
	var top_left = global_position
	var bot_right = top_left + Vector2(width * cell, height * cell)
	if mouse_pos.x >= top_left.x and mouse_pos.x <= bot_right.x \
	and mouse_pos.y >= top_left.y and mouse_pos.y <= bot_right.y:
		_dragging = true
		_drag_start_mouse = mouse_pos
		_drag_start_col = grid_col
		_drag_start_row = grid_row
		_drag_axis = 0
		get_viewport().set_input_as_handled()
 
# Updates block based on drag information
func _update_drag(mouse_pos: Vector2) -> void:
	var delta := mouse_pos - _drag_start_mouse
	var cell = board.CELL_SIZE
 
	# Lock axis once threshold is passed
	if _drag_axis == 0:
		if abs(delta.x) > AXIS_THRESHOLD and can_slide_horizontal():
			_drag_axis = 1
		elif abs(delta.y) > AXIS_THRESHOLD and can_slide_vertical():
			_drag_axis = 2
		else:
			return
 
	if _drag_axis == 1:   # Horizontal
		var col_offset := int(round(delta.x / cell))
		var target_col := _drag_start_col + col_offset
		target_col = board.clamp_block_col(self, target_col)
		if target_col != grid_col:
			board.try_move_block(self, target_col, grid_row)
	elif _drag_axis == 2: # Vertical
		var row_offset := int(round(delta.y / cell))
		var target_row := _drag_start_row + row_offset
		target_row = board.clamp_block_row(self, target_row)
		if target_row != grid_row:
			board.try_move_block(self, grid_col, target_row)

# Ends drag and snaps block
func _end_drag() -> void:
	_dragging = false
	_drag_axis = 0
	# Snap visual position to grid
	if board:
		board.snap_block_visual(self)
