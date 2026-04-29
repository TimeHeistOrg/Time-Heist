extends Node3D

@export var CAMERA_ROTATION_X : float = -50
@export var CAM_ROT_SPEED : float = 4
@export var CAMERA_DISTANCE_BACK : float = 2
@export var CAMERA_DISTANCE_UP : float = 6

enum Direction { 
	NORTH = 0,
	WEST,
	SOUTH,
	EAST
}

@export var facing_direction : Direction
var previous_facing_direction : Direction

var destination_rotation : int
var current_rotation : float
@onready var spring_arm := $SpringArm3D
@onready var camera := $SpringArm3D/Camera3D
var current_camera_z : float

@onready var color_rect := $CanvasLayer/ColorRect

func _ready() -> void:
	globals.camera = self
	spring_arm.spring_length = CAMERA_DISTANCE_BACK
	current_camera_z = spring_arm.spring_length
	rotation_degrees.x = CAMERA_ROTATION_X
	
	#rotation_degrees.x = X_ROTATION
	
	rotation_degrees.y = facing_direction * 90
	destination_rotation = facing_direction * 90
	pass

func _input(_event: InputEvent) -> void:
	if PlayerInput.is_action_just_pressed("camera_right"):
		step_rotation(-1)
		test_print()
	if PlayerInput.is_action_just_pressed("camera_left"):
		step_rotation(+1)
		test_print()

func step_rotation(change: int):
	#For character input remapping
	globals.player.input_controller.should_update_map = true
	
	destination_rotation = (destination_rotation + change*90)
	previous_facing_direction = facing_direction
	if change == -1:
		facing_direction = (facing_direction + change + 4) % 4 as Direction
	elif change == 1:
		facing_direction = (facing_direction + change) % 4 as Direction
	

#var elapsed = 0.0
func _process(delta: float) -> void:
	color_rect.modulate.a = lerp(color_rect.modulate.a, 1.0 - globals.safe_ratio, 5.0 * delta)
	#print(globals.caught_time_remaining)
	#Centers camera pivot on the parent
	position = globals.player.position + Vector3(0, CAMERA_DISTANCE_UP, 0)
	
	if rotation_degrees.y != float(destination_rotation):
		rotation_degrees.y = lerp(rotation_degrees.y, float(destination_rotation), delta * CAM_ROT_SPEED)
	else:
		rotation_degrees.y = int(rotation_degrees.y) % 360
	pass
	
	var target_z = spring_arm.get_hit_length()
	current_camera_z = lerp(current_camera_z, target_z, delta * 10.0)
	camera.position.z = current_camera_z

func test_print():
	print(facing_direction)
