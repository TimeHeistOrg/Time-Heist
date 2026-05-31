extends Node3D

var closed_position = Vector3.ZERO
var open_position = Vector3(0,0,-1.6)
@onready var door: Node3D = $Door

var is_open : bool: #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_open",is_open)
		is_open = value
		if value:
			door.position = open_position
		else:
			door.position = closed_position
			
func open():
	door.position = open_position

func close():
	door.position = closed_position
