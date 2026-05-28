extends Node3D

@onready var start_spot: Marker3D = $"SubViewportContainer/SubViewport/Tutorial/Room 1/StartSpot"
@onready var room_2_area_3d: Area3D = $"SubViewportContainer/SubViewport/Tutorial/Room 2/Room2Area3D"
@onready var room_2_save_spot: Marker3D = $"SubViewportContainer/SubViewport/Tutorial/Room 2/Room2Area3D/Room2SaveSpot"
@onready var room_6_area_3d: Area3D = $"SubViewportContainer/SubViewport/Tutorial/Room 6/Room6Area3D"
@onready var room_6_save_spot: Marker3D = $"SubViewportContainer/SubViewport/Tutorial/Room 6/Room6Area3D/Room6SaveSpot"

var current_respawn : Marker3D

func _ready():
	current_respawn = start_spot
	room_2_area_3d.body_entered.connect(func(): current_respawn = room_2_save_spot)
	room_6_area_3d.body_entered.connect(func(): current_respawn = room_6_save_spot)
	globals.time_manager.start_time()

func _on_area_3d_body_entered(_body):
	SceneManager.change_scene(SceneManager.Scene.HOMEBASE)
	
func reset_to_save():
	if globals.player:
		globals.player.global_position = current_respawn.global_position
