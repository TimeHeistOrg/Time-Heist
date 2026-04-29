#class_name OldPlayer
extends CharacterBody3D

@onready
var state_machine = $state_machine
@onready
var input_controller = $input_controller
@onready
var animation_player : AnimationPlayer = $Mesh/AnimationPlayer
@onready
var anim_tree : AnimationTree = $Mesh/AnimationTree
@onready
var detection_point: Marker3D = $DetectionPoint


@onready var collision := $CollisionShape3D
@onready var mesh : MeshInstance3D = $Mesh/Armature/Skeleton3D/Body

var previous_input : Vector2
var is_crouching := false
var can_rotate := true
var is_hidden := false

var can_move: bool = true
var can_be_seen: bool = true
var can_open_any_door: bool = false

#region Movement Export Variables
var speed : float
var current_max_speed : float
var current_acceleration : float
var current_rotation_speed : float
@export
var rotation_speed : float = 15.0
@export
var crouch_rotation_speed : float = 6

@export_category("State Speeds")
#region Walking Variables
@export_group("Walking")
@export
var max_speed_walking : float
@export
var acceleration_walking : float
@export
var deceleration_walking : float
#endregion
#region Crouching Variables
@export_group("Crouching")
@export
var max_speed_crouching : float
@export
var acceleration_crouching : float
@export
var deceleration_crouching : float
#endregion
#region Sliding Variables
@export_group("Sliding")
@export
var max_speed_sliding : float
@export
var deceleration_sliding : float
#endregion
#region Dash Variables
@export_group("Running")
@export
var max_speed_running : float
@export
var acceleration_running : float
@export
var deceleration_running : float
#endregion
#region Roll Variables
@export_group("Rolling")
@export
var roll_speed : float
@export
var crouch_roll_speed : float
@export
var roll_duration : float
#endregion

var tool1 : Tool
var tool2 : Tool

func _ready() -> void:
	#globals.player = self
	state_machine.init(input_controller)
	
	current_rotation_speed = rotation_speed
	input_controller.crouch_off()
	
	anim_tree.set("parameters/Movement/transition_request", "Idle")
	
	pass

func _unhandled_input(event: InputEvent) -> void:
	state_machine.handle_input(event)
	pass

func _physics_process(delta: float) -> void:
	state_machine.handle_physics(delta)
	
func _process(delta: float) -> void:
	state_machine.handle_frame(delta)
	
	var input_dir = input_controller.get_input_direction() # Input direction
	if can_rotate and input_dir:
		rotation.y = lerp_angle(rotation.y, atan2(-input_dir.x, -input_dir.y), delta * current_rotation_speed)
	
func get_direction_facing() -> Vector3:
	return -get_global_transform().basis.z
