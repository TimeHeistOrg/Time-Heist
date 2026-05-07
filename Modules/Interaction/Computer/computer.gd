# computer.gd
extends Node3D
class_name Computer

@export var data: ComputerData

func interact():
	if not data:
		push_warning("Computer has no ComputerData resource")
		return
	globals.ui_manager.desktop_viewer.display_computer(data)
