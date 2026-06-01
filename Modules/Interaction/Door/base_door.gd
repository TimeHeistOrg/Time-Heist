@tool
class_name BaseDoor extends Door

@export var mesh: MeshInstance3D
@export var collider: StaticBody3D

func open():
	if is_open: #check to avoid unnecessary call to setter
		return
	is_open = true

func close():
	if is_open: #check to avoid unnecessary call to setter
		is_open = false

func is_open_setter(value:bool): #made so that setter can be overridden in children, value will be set in main setter
	if value:
		mesh.hide()
		collider.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		mesh.show()
		collider.process_mode = Node.PROCESS_MODE_INHERIT

func locked_door_behavior():
	pass
