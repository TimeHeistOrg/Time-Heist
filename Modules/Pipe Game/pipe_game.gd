@tool
extends Control	

@export_group("Pipe Board Settings")
@export_range(1, 10) var width: int = 5
@export_range(1, 10) var height: int = 5
@export_tool_button("Generate Board") var gen_board_btn = func(): _gen_board()
@export_group("UI Refs")
@export_group("")



# Generates the board UI
func _gen_board() -> void:
	print("Generating %dx%d board..." % [width, height])
	_create_ui()
	
func _create_ui():
	pass

func _ready() -> void:
	_create_board_state()
	
func _create_board_state():
	pass
