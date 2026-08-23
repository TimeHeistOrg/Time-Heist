extends Node3D

func _ready():
	print("starting gameplayd")
	globals.time_manager.restart_time()
	globals.time_manager.start_time()
