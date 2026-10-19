extends Node3D
class_name SecurityCamera

@onready var camera: Camera3D = $Camera

var active : bool = true:
	set(value):
		active = value
		camera.show() if value else camera.hide()
