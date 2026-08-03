extends Node3D
class_name Tutorial

@export var start_spot: Marker3D
@export var room_2_area_3d: Area3D
@export var room_2_save_spot: Marker3D
@export var room_6_area_3d: Area3D
@export var room_6_save_spot: Marker3D

var save_spots

var current_respawn : Marker3D

func _ready():
	save_spots = {
		0 : start_spot,
		1 : room_2_save_spot,
		2 : room_6_save_spot,
	}
	current_respawn = save_spots[globals.tutorial_start_point]
	if globals.player:
		globals.player.global_position = current_respawn.global_position
	
	room_2_area_3d.body_entered.connect(func(body):
		if body == globals.player:
			globals.tutorial_start_point = 1
	)
	room_6_area_3d.body_entered.connect(func(body):
		if body == globals.player:
			globals.tutorial_start_point = 2
	)
	globals.time_manager.start_time()

func _on_area_3d_body_entered(_body):
	SceneManager.change_scene_with_transition(SceneManager.Scene.HOMEBASE)
	globals.in_tutorial = false
