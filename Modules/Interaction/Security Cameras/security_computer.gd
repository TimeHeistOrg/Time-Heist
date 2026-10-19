extends Node3D
class_name SecurityComputer

@export var security_ui : PackedScene
@export var floor_cameras : Node

func _ready() -> void:
	if not security_ui or not floor_cameras:
		push_error("Computer UI not hooked up")
		#assert(false)
	#computer_ui.close()
	
func interact():
	globals.ui_manager.desktop_viewer.display_security(security_ui, floor_cameras)
	
