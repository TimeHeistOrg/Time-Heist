extends Node

func _ready():
	#print("starting gameplay")
	globals.time_manager.restart_time()
	globals.time_manager.start_time()
