extends State
class_name Rolling

@export_category("States")
@export
var walking_state : State
@export
var idle_state : State
@export
var running_state : State
@export
var sliding_state : State

var roll_timer : float
#var crouching_on_enter
var roll_speed

func enter() -> void:
	#player.anim_tree.set("parameters/PlayerAnimations/Roll/request",AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	player.can_rotate = false
	
	#saves if crouching state
	#crouching_on_enter = player.is_crouching
	if not player.is_crouching:
		#input_controller.crouch_on()
		roll_speed = player.roll_speed
	else:
		roll_speed = player.crouch_roll_speed
	
	player.anim_tree.set("parameters/roll/TimeScale/scale",roll_speed/2.5)
		
	roll_timer = 0.0
	
	#If inputing roll towards that, if not roll towards facing direction
	if input_controller.get_input_direction() != Vector2.ZERO:
		player.velocity = input_controller.get_direction_vector(input_controller.get_input_direction()) * roll_speed
	else:
		player.velocity = player.get_direction_facing() * roll_speed
	pass
	
func exit() -> void:
	#Return can rotate to true
	player.can_rotate = true
	##Returns crouch state back to what it was
	#if not crouching_on_enter:
		#input_controller.crouch_off()
	pass
	
func process_input(_event: InputEvent) -> State:
	return null
	
func process_physics(_delta: float) -> State:
	player.move_and_slide()

	return null
	
func process_frame(delta: float) -> State:
	roll_timer = roll_timer + delta
	if roll_timer >= player.roll_duration:
		if input_controller.get_input_direction() != Vector2.ZERO:
			if PlayerInput.is_action_pressed("player_roll_walk"):
				return walking_state
			return running_state
		return idle_state #maybe sliding instead?
	if player.velocity == Vector3.ZERO:
		return idle_state
	return null
