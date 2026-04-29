@tool
class_name Player2 extends CharacterBody3D

@onready var mesh: Node3D = $Mesh
@onready var camera_pivot: Node3D = $"Camera Pivot"
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var detection_point: Marker3D = $DetectionPoint

@export_category("Camera")
@export var camera_up: float = 5.798:
	set(value):
		camera_up = value
		if Engine.is_editor_hint():
			$"Camera Pivot/Camera3D".position.y = value
@export var camera_back: float = 1.928:
	set(value):
		camera_back = value
		if Engine.is_editor_hint():
			$"Camera Pivot/Camera3D".position.z = value
@export var camera_angle: float = -60:
	set(value):
		camera_angle = value
		if Engine.is_editor_hint():
			$"Camera Pivot/Camera3D".rotation.x = deg_to_rad(value)

@export_category("Movement Exports")
@export var turn_weight: float = 0.5
@export var deceleration: float = 6
@export_group("Walking")
@export var max_walk_speed: float = 2.5
@export var walk_acceleration: float = 2.5
@export_group("Running")
@export var max_run_speed: float = 5
@export var run_acceleration: float = 5
@export_group("Crouching")
@export var max_crouch_speed: float = 2.2
@export var crouch_acceleration: float = 2.2
@export_group("Rolling")
@export var roll_speed: float = 5
@export var roll_duration: float = 0.75

var camera_locked: bool = true

enum MoveStates {RUN, WALK, CROUCH, ROLL}
var state: MoveStates
var state_move: Callable

#movement variables
var destination_rotation: float
var roll_timer: float = 0
var defer_crouch: bool = false #this is for if the player presses crouch during roll, will be placed in crouch mode after roll is complete
var player_facing: Vector3 #represents the direction the player should be facing (is set based on input, and not on where mesh is in rotation)
var current_speed: float
var destination_velocity: Vector3
var current_acceleration: float
var move_acceleration: float

#inventory
@onready var inven_wheel: Node2D = $"SubViewport/Inventory Wheel"

func _ready():
	globals.player2 = self
	run_enter()

func _process(delta): #This process is for things that should occur regardless of whether the player has control of input
	if not Engine.is_editor_hint():
		if not is_equal_approx(mesh.rotation.y, destination_rotation):
			mesh.rotation.y = lerp_angle(mesh.rotation.y, destination_rotation, turn_weight)
		else:
			mesh.rotation.y = destination_rotation
		
		if not state == MoveStates.ROLL:
			if not velocity.is_equal_approx(destination_velocity):
				velocity = lerp(velocity, destination_velocity, current_acceleration * delta)
			else:
				velocity = destination_velocity
		current_speed = velocity.length()

func pan_camera_horizontally(angle):
	camera_pivot.rotate(Vector3.UP, angle)

func unlock_camera():
	camera_locked = false

func lock_camera():
	camera_locked = true

func toggle_crouch(): #input manager interface function
	if state == MoveStates.ROLL:
		defer_crouch = true
	elif state == MoveStates.CROUCH:
		run_enter()
	else:
		crouch_enter()

func set_walk(val: bool): #input manager interface function
	if val and state == MoveStates.RUN:
		walk_enter()
	elif not val and state == MoveStates.WALK:
		run_enter()

func roll(): #input manager interface function
	if state != MoveStates.ROLL:
		roll_enter()

func move(input_dir: Vector2, delta): #input manager calls this every physics_process frame with the pertinent input information
	#anything that should happen for all states should go here
	state_move.call(input_dir,delta)
	move_and_slide()

func _default_move(input_dir: Vector2, speed: float): #This function is the default movement, used for run, walk, and crouch movement
	if input_dir.is_zero_approx():
		current_acceleration = deceleration
		destination_velocity = Vector3.ZERO
	else:
		current_acceleration = move_acceleration
		destination_velocity = (Vector3(input_dir.x, 0, input_dir.y).normalized() * speed).rotated(Vector3.UP,camera_pivot.rotation.y)
		destination_rotation = Vector3.FORWARD.signed_angle_to(velocity, Vector3.UP)
		player_facing = destination_velocity.normalized()

func speed_to_blend_value(speed: float) -> float:
	if speed > max_walk_speed:
		return (max_run_speed - max_walk_speed - speed)/-(max_run_speed - max_walk_speed)
	else:
		return (max_walk_speed - speed)/-max_walk_speed

#region run
func run_enter():
	state = MoveStates.RUN
	state_move = run_move
	move_acceleration = run_acceleration
	animation_tree["parameters/MoveStates/transition_request"] = "RunWalk"

func run_move(input_dir: Vector2, _delta: float):
	_default_move(input_dir, max_run_speed)
	animation_tree["parameters/RunWalkBlend/blend_position"].y = speed_to_blend_value(current_speed)
#endregion

#region walk
func walk_enter():
	state = MoveStates.WALK
	state_move = walk_move
	move_acceleration = walk_acceleration
	animation_tree["parameters/MoveStates/transition_request"] = "RunWalk"

func walk_move(input_dir: Vector2, _delta: float):
	_default_move(input_dir, max_walk_speed)
	animation_tree["parameters/RunWalkBlend/blend_position"].y = speed_to_blend_value(current_speed)
#endregion

#region crouch
func crouch_enter():
	state = MoveStates.CROUCH
	state_move = crouch_move
	move_acceleration = crouch_acceleration
	animation_tree["parameters/MoveStates/transition_request"] = "Crouch"

func crouch_move(input_dir: Vector2, _delta: float):
	_default_move(input_dir, max_crouch_speed)
	animation_tree["parameters/CrouchBlendSpace/blend_position"] = 1 - (max_crouch_speed - current_speed)/max_crouch_speed
#endregion

#region roll
func roll_enter():
	state = MoveStates.ROLL
	state_move = roll_move
	roll_timer = roll_duration
	velocity = player_facing * roll_speed
	animation_tree["parameters/MoveStates/transition_request"] = "Roll"

func roll_move(_input_dir: Vector2, delta: float):
	if roll_timer <= 0:
		if defer_crouch:
			defer_crouch = false
			crouch_enter()
		else:
			run_enter()
	else:
		roll_timer -= delta
#endregion


#player.speed = lerp(player.speed, player.current_max_speed, player.current_acceleration * delta)
