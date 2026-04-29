extends Node

@export var starting_state: State

var current_state: State
var state_string: String
# Called when the node enters the scene tree for the first time.
func init(input_controller: Node) -> void:
	for child in get_children():
		child.player = globals.player
		child.input_controller = input_controller
	
	change_state(starting_state)

func change_state(new_state : State) -> void:
	if current_state:
		current_state.exit()
		
	current_state = new_state
	
	#Update String
	state_string = current_state.get_script().get_global_name()
	#print("Changing to ", state_string)
	
	current_state.enter()
	
func handle_input(event: InputEvent) -> void:
	#if PlayerInput.is_action_just_pressed("player_crouch"):
		#if globals.player.state_machine.is_crouching == true:
			#globals.player.state_machine.is_crouching = false
		#else:
			#globals.player.state_machine.is_crouching = true
	##Pass input to playerinputcontroller first (inputs that dont affect state)
	globals.player.input_controller.process_input(event)
	
	#Now give it to the states
	var new_state = current_state.process_input(event)
	if new_state:
		change_state(new_state)

func handle_physics(delta: float) -> void:
	var new_state = current_state.process_physics(delta)
	if new_state:
		change_state(new_state)
		
func handle_frame(delta: float) -> void:
	var new_state = current_state.process_frame(delta)
	if new_state:
		change_state(new_state)
