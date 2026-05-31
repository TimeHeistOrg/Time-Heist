@tool
class_name Door extends Node3D

@export var mesh: MeshInstance3D
@export var collider: StaticBody3D

@export var is_open: bool = false : #TIMEVAR
	set(value):
		#print("set is_open to ", value)
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_open",is_open)
		is_open_set(value)
		is_open = value

@export var is_locked: bool = false : #TIMEVAR
	set(value):
		#print("set is_locked to ", value)
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_locked",is_locked)
		is_locked_set(value)
		is_locked = value

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func is_open_set(value:bool): #made so that setter can be overridden in children, value will be set in main setter
	pass

func is_locked_set(value:bool): #made so that setter can be overridden in children, value will be set in main setter
	pass
