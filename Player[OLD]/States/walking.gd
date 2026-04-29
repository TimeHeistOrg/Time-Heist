extends State
class_name Walking

#ANY EXPORTS?
@export_category("States")
@export
var idle_state : State
@export 
var sliding_state : State
@export
var running_state : State

func enter() -> void:
	#player.anim_tree.set("parameters/PlayerAnimations/Movement/transition_request","Walking")
	
	if player.is_crouching:
		player.current_max_speed = player.max_speed_crouching
		player.current_acceleration = player.acceleration_crouching
	else:
		player.current_max_speed = player.max_speed_walking
		player.current_acceleration = player.acceleration_walking
	pass
	
func exit() -> void:
	pass
	
func process_input(_event: InputEvent) -> State:
	#if PlayerInput.is_action_just_pressed("player_dash"):
		#return dash_state
	return null
	
func process_physics(delta: float) -> State:
	
	if not player.is_on_floor():
		player.velocity += player.get_gravity() * delta

	var input_dir = input_controller.get_input_direction() # Input direction
	var direction_vector = input_controller.get_direction_vector(input_dir) # Direction vector
	
	player.speed = lerp(player.speed, player.current_max_speed, player.current_acceleration * delta)
	player.velocity = player.speed * direction_vector

	player.move_and_slide()
	
	return null
	
func process_frame(_delta: float) -> State:
	if input_controller.get_input_direction() == Vector2.ZERO:
		return sliding_state
	if PlayerInput.is_action_pressed("player_roll_walk"):
		return null
	#if PlayerInput.is_action_pressed("player_dash"):
		#return dash_state
	
	if player.is_crouching:
		player.current_acceleration = player.deceleration_crouching
		player.current_max_speed = player.max_speed_crouching
	else:
		player.current_acceleration = player.deceleration_walking
		player.current_max_speed = player.max_speed_walking
	if player.speed > player.current_max_speed:
		if player.is_crouching:
			player.current_acceleration = player.deceleration_crouching
		else:
			player.current_acceleration = player.deceleration_walking
	else:
		if player.is_crouching:
			player.current_acceleration = player.acceleration_crouching
		else:
			player.current_acceleration = player.acceleration_walking
	return sliding_state
