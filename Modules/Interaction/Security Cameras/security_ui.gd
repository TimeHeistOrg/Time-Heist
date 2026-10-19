extends UI
class_name SecurityUI

@export var camera_array : Array[SecurityCamera]
@onready var camera_grid: GridContainer = $ColorRect/MarginContainer/GridContainer
var security_camera_feed : PackedScene = preload("res://Modules/Interaction/Security Cameras/security_camera_feed.tscn")

func set_cameras(cameras : Array[Node]):
	for camera in cameras:
		if camera is Camera3D:
			var feed = security_camera_feed.instantiate()
			camera_grid.add_child(feed)
			feed.set_camera(camera)
