@tool
extends TextureRect

enum PipeType { EMPTY, STRAIGHT, ANGLE_90 }

signal rotation_changed(row: int, col: int)

# @export_group("Cell Settings")  # hidden since you have to open it for every cell which got annoying
@export var pipe_type: PipeType = PipeType.EMPTY:
	set(value):
		pipe_type = value
		_update_texture()
@export var random_rotation: bool = false  # set true to randomly rotate pipe cell on game start
@export var is_start_pipe: bool = false:  # set true if this is a starting pipe
	set(value):
		is_start_pipe = value
		_update_texture()
@export var is_end_pipe: bool = false:  # set true if this is an ending pipe
	set(value):
		is_end_pipe = value
		_update_texture()
@export_range(0, 3) var rotation_level: int = 0: # rotation settings: 0 = 0 degrees, 1 = 90 degrees, 2 = 180 degrees, 3 = 270 degreess
	set(value):
		rotation_level = value
		_update_rotation()
@export_group("Pipe Textures")
@export var straight_texture: Texture2D = null
@export var angle_90_texture: Texture2D = null
@export_group("")

var row: int = -1
var col: int = -1

# cell setup based on above settings
func _ready() -> void:
	if random_rotation and pipe_type != PipeType.EMPTY and !is_start_pipe and !is_end_pipe:
		rotation_level = randi_range(0, 3)
	_update_texture()
	_update_rotation()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# cant rotate start or end pipes
			if is_start_pipe or is_end_pipe:
				return
			_rotate_cell()

# rotates the cell and emits signal to notify game
func _rotate_cell() -> void:
	# rotate the cell
	rotation_level = (rotation_level + 1) % 4
	_update_rotation()
	
	# notify game of rotation
	print("emit firing from cell (%d, %d)" % [row, col])
	print("signal has %d connections" % [rotation_changed.get_connections().size()])
	rotation_changed.emit(row, col)

# updates the visible texture based on set pipe type
func _update_texture():
	match pipe_type:
		PipeType.EMPTY:
			texture = null
		PipeType.STRAIGHT:
			texture = straight_texture
		PipeType.ANGLE_90:
			texture = angle_90_texture
			
	# color pipes based on if it is a start or end pipe
	if is_start_pipe:
		modulate = Color(0.6, 1.0, 0.6)
	elif is_end_pipe:
		modulate = Color(1.0, 0.6, 0.6)
	else:
		modulate = Color.WHITE
	
# updates the rotation of the pipe
func _update_rotation():
	var deg = rotation_level * 90.0
	pivot_offset = size / 2
	rotation_degrees = deg

# gets the open sides of the pipe
# 0 = Up, 1 = Right, 2 = Down, 3 = Left
func get_open_sides() -> Array:
	if pipe_type == PipeType.EMPTY:
		return []
		
	var sides: Array
	# first get default open sides
	match pipe_type:
		PipeType.STRAIGHT:
			sides = [1, 3]
		PipeType.ANGLE_90:
			sides = [0, 1]
		_:
			return []
	# then apply rotation (since each rotation adds 1 to the default open side, simply add default side + rot. level)
	return sides.map(func(s): return (s + rotation_level) % 4)

func init(r: int, c: int) -> void:
	row = r
	col = c
