class_name State
extends Node

#ANY EXPORTS?

var player: Player
var input_controller: Node

func enter() -> void:
	pass
	
func exit() -> void:
	pass
	
func process_input(_event: InputEvent) -> State: #return the state you should swap to
	return null
	
func process_physics(_delta: float) -> State:
	return null
	
func process_frame(_delta: float) -> State:
	return null
