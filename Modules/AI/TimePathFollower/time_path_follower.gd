@tool
class_name TimePathFollower extends PathFollower

@export var state_label: Label3D

func _state_setter(value):
	if not Engine.is_editor_hint() and globals.time_manager and globals.time_manager.logging:
		globals.time_manager.timelog(self,"_state",_state)
	_state = value
	state_label.text = State.find_key(_state)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		if run_process:
			advance(delta*globals.time_manager.time_multiplier)

#region backward simulation
## Steps backward into the path by [parameter delta] seconds
func _backward_step(delta: float) -> void:
	var remaining := -delta
	while remaining > 0.0 and _state != State.UNSTARTED:
		match _state:
			State.PRE_DELAY:
				remaining = _pre_delay_backward_step(remaining)
			State.DWELLING:
				remaining = _dwelling_backward_step(remaining)
			State.MOVING:
				remaining = _moving_backward_step(remaining)
			_:
				break


## Handles the behavior for a backward step when in the PRE_DELAY state.
func _pre_delay_backward_step(remaining) -> float:
	var consumed := minf(remaining, start_offset - _pre_delay_remaining)
	_path_time -= consumed
	_pre_delay_remaining += consumed
	if _pre_delay_remaining >= start_offset:
		_pre_delay_remaining = start_offset
	return remaining - consumed


## Handles the behavior for a backward step when in the DWELLING state.
func _dwelling_backward_step(remaining) -> float:
	var vertex: PathVertex = path_data.get_vertex_by_id(_current_vertex_id)
	# Scenario where the path is empty. If rewinding on an empty path nothing needs to be undone, but stays here until state change.
	if vertex == null:
		return 0.0
	
	
	if _cur_action_index < 0:
		_begin_previous_edge()
		return remaining
	
	var action: VertexAction = vertex.actions[_cur_action_index]
	
	if action == null or not action.enabled or not _direction_allows(action) or not action.blocks():
		_cur_action_index -= 1
		return remaining
	
	var consumed := minf(remaining, action.get_block_time() - _action_wait_remaining)
	
	_path_time -= consumed
	_action_wait_remaining += consumed
	if _action_wait_remaining > action.get_block_time():
		_cur_action_index -= 1
		_action_wait_remaining = vertex.actions[_cur_action_index].get_block_time()
	return remaining - consumed


## Handles the behavior for a forward step when in the MOVING state.
func _moving_backward_step(remaining: float) -> float:
	var consumed := minf(remaining, _edge_time_length - _edge_time_remaining)
	_path_time -= consumed
	_edge_time_remaining += consumed
	if _edge_time_remaining >= _edge_time_length:
		if not _travelling_backward:
			_edge_history.pop_back()
		_current_vertex_id = _current_vertex_id
		_arrive_at_previous_vertex()
	return remaining - consumed


## (Re)Initializes the edge state variables to begin a previous edge.
func _begin_previous_edge():
	pass
		#var edge: PathEdge
	#
	#if not _travelling_backward:
		#edge = _pick_forward_edge(_current_vertex_id)
		#if edge == null:
			#_handle_forward_terminal()
			#return
		#_target_vertex_id = edge.to_vertex
	#else:
		#if _edge_history.is_empty():
			#_handle_backward_terminal()
			#return
		#var last: Dictionary = _edge_history.pop_back()
		#edge = path_data.get_edge_by_id(last["edge_id"])
		#if edge == null:
			#_handle_backward_terminal()
			#return
		#_target_vertex_id = edge.from_vertex  # walking it in reverse
	#
	#_current_edge_id = edge.id
	#
	#var from_vertex := path_data.get_vertex_by_id(_current_vertex_id)
	#var to_vertex := path_data.get_vertex_by_id(_target_vertex_id)
	#var edge_length := from_vertex.position.distance_to(to_vertex.position)
	#var speed := to_vertex.get_effective_speed(path_data.default_speed)
	#_edge_time_remaining = edge_length / speed if speed > 0.0 else 0.0
	#_edge_time_length = max(_edge_time_remaining, 0.0001)
	#
	#var new_direction := (to_vertex.position - from_vertex.position).normalized()
	#if rotation_enabled and new_direction != Vector3.ZERO and not to_vertex.suppress_incoming_turn:
		#_start_turn(new_direction)
	#
	#edge_entered.emit(_current_edge_id)
	#_state = State.MOVING


## (Re)Initializes the vertex state variables to begin a previous vertex.
func _arrive_at_previous_vertex():
	pass
	#vertex_reached.emit(_current_vertex_id)
	#_cur_action_index = 0
	#_action_wait_remaining = -1.0
	#_branch_edge_id = -1
	#_state = State.DWELLING
