extends Node3D

@export var clearance_type : globals.Clearances

func interact():
	globals.collect_clearance.emit(clearance_type)
	globals.ui_manager.display_message("Collected " + globals.Clearances.find_key(clearance_type))
	pass
