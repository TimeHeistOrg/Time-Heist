extends Node3D
class_name GenericInterfaceOpener

@export var interface : UI

func _ready():
	if interface:
		interface.hide()

func interact():
	if interface:
		interface.open()
