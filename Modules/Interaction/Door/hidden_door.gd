extends Node3D

var closed_position = Vector3.ZERO
var open_position = Vector3(0,0,-1.6)
@onready var door: Node3D = $Door
@onready var anim_player: TimeAnimationPlayer = $TimeAnimationPlayer

var is_open : bool: #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_open",is_open)
		is_open = value
		if value:
			open()
		else:
			close()
			
func open():
	anim_player.play("open")

func close():
	anim_player.play("close")
	
func set_open(value : bool):
	if value:
		open()
	else:
		close()
