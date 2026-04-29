extends Node
class_name PlayerInput

@export var rotation_speed : float = 15.0
@export var sneak_state : State
@export var rolling_state : State
@onready var roll_window := $roll_window
@onready var anim_tree: AnimationTree = $"../Mesh/AnimationTree"

var face_to_move = {
	0 : ["player_left", "player_right", "player_up", "player_down"],
	1 : ["player_up", "player_down", "player_right", "player_left"],
	2 : ["player_right", "player_left", "player_down", "player_up"],
	3 : ["player_down", "player_up", "player_left", "player_right"],
}

var input_map
var should_update_map : bool = true

func _ready() -> void:
	input_map = face_to_move[0] # Initally set input map
	#mat = globals.player.mesh.get_surface_override_material(0) #Testing for crouch

#region Static Function to check player control
# States us these to check if the player is in control
static func player_is_in_control():
	return globals.controller_of_input == globals.InputController.GAMEPLAY

static func is_action_just_pressed(action : StringName):
	if player_is_in_control():
		return Input.is_action_just_pressed(action)
	return false
	
static func is_action_pressed(action : StringName):
	if player_is_in_control():
		return Input.is_action_pressed(action)
	return false
	
static func is_action_just_released(action : StringName):
	if player_is_in_control():
		return Input.is_action_just_released(action)
	return false
#endregion

#region Input Direction
func get_input_direction() -> Vector2:
	if not player_is_in_control():
		return Vector2.ZERO
	# Get input (based on mapping from direction it is facing)
	var input_dir := Input.get_vector(input_map[0],input_map[1],input_map[2],input_map[3])
	# Update maping (only if should)
	if should_update_map and input_dir != globals.player.previous_input:
		input_map = face_to_move[globals.camera.facing_direction]
		should_update_map = false
	
	if input_dir != globals.player.previous_input:
		globals.player.previous_input = input_dir # Stores previous input (for the above check)
		
	return input_dir

func get_direction_vector(input_dir : Vector2) -> Vector3:
	var direction_facing = get_parent().get_direction_facing()
	return (direction_facing * Vector3(abs(input_dir.x), 0, abs(input_dir.y))).normalized()
#endregion

func crouch_on():
	print("\tcrouch going on")
	anim_tree.set("parameters/conditions/is_crouching", true)
	anim_tree.set("parameters/conditions/not_crouching", false)
	globals.player.is_crouching = true
	#globals.player.collision.shape.height -= 0.8
	#globals.player.collision.position.y -= 0.4
	globals.player.current_rotation_speed = globals.player.crouch_rotation_speed
	globals.player.detection_point.position.y = 0.7
	#globals.player.mesh.position.y -= 0.8
	#globals.player.material.albedo_color = Color(0.982, 0.502, 1.0, 1.0)
	
func crouch_off():
	print("\tcrouch going off")
	anim_tree.set("parameters/conditions/is_crouching", false)
	anim_tree.set("parameters/conditions/not_crouching", true)
	globals.player.is_crouching = false
	#globals.player.collision.shape.height += 0.8
	#globals.player.collision.position.y += 0.4
	globals.player.current_rotation_speed = globals.player.rotation_speed
	globals.player.detection_point.position.y = 1.5
	#globals.player.mesh.position.y += 0.8
	#globals.player.material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)
	
func toggle_crouch():
	@warning_ignore("standalone_ternary")
	crouch_off() if globals.player.is_crouching else crouch_on()

func process_input(_event: InputEvent):
	#region Crouch
	if PlayerInput.is_action_just_pressed("player_crouch"):
		if globals.player.state_machine.current_state != $"../state_machine/rolling":
			toggle_crouch()
		return
	#endregion
	#region Roll
	if PlayerInput.is_action_just_pressed("player_roll_walk"):
		if roll_window.is_stopped():
			roll_window.start()
			#print("starting roll timer")
	if PlayerInput.is_action_just_released("player_roll_walk"):
		if not roll_window.is_stopped():
			globals.player.state_machine.change_state(rolling_state)
			roll_window.stop()
		#else:
			#print("missed it")
		return
	#endregion
	#region Tools
	if PlayerInput.is_action_just_pressed("player_tool1"):
		#globals.player.tool1.use_tool()
		#TEST
		document_database.get_document(0)._print()
	if PlayerInput.is_action_just_pressed("player_tool2"):
		#globals.player.tool2.use_tool()
		#TEST
		document_database.get_document(1)._print()
	#endregion
		
