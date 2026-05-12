extends Node3D
class_name GenericInterfaceOpener

@export var interface : UI

func interact():
	if interface:
		interface.open()
