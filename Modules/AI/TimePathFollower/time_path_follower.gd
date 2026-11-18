@tool
class_name TimePathFollower extends PathFollower

@export var state_label: Label3D

var _time_finished: float = -1

func _state_setter(value):
	super._state_setter(value)
	state_label.text = State.find_key(value)
	if value == State.FINISHED:
		_time_finished = _path_time


func _branch_edge_id_setter(value):
	if not Engine.is_editor_hint() and globals.time_manager and globals.time_manager.logging:
		globals.time_manager.timelog(self,"_branch_edge_id",_branch_edge_id)
	_branch_edge_id = value

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		if run_process:
			seek(globals.time_manager.cur_time)

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
			State.FINISHED:
				remaining = _finished_backward_step(remaining)
			_:
				break


## Handles the behavior for a backward step when in the PRE_DELAY state.
func _pre_delay_backward_step(remaining) -> float:
	var consumed := minf(remaining, start_offset - _pre_delay_remaining)
	_path_time -= consumed
	_pre_delay_remaining += consumed
	if _pre_delay_remaining >= start_offset:
		_pre_delay_remaining = start_offset
		_state = State.UNSTARTED
	return remaining - consumed


## Handles the behavior for a backward step when in the DWELLING state.
func _dwelling_backward_step(remaining) -> float:
	var vertex: PathVertex = path_data.get_vertex_by_id(_current_vertex_id)
	# Scenario where the path is empty. If rewinding on an empty path nothing needs to be undone, but stays here until state change.
	if vertex == null:
		return 0.0
	
	
	if vertex.actions.is_empty() or _cur_action_index < 0:
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
		_current_vertex_id = _current_vertex_id
		_arrive_at_previous_vertex()
	return remaining - consumed


## (Re)Initializes the edge state variables to begin a previous edge.
func _begin_previous_edge():
	if _edge_history.is_empty():
		_state = State.PRE_DELAY
		return
	var edge: PathEdge = path_data.get_edge_by_id(_edge_history.pop_back())
	
	_current_edge_id = edge.id
	_current_vertex_id = edge.from_vertex
	_target_vertex_id = edge.to_vertex
	
	var from_vertex := path_data.get_vertex_by_id(_current_vertex_id)
	var to_vertex := path_data.get_vertex_by_id(_target_vertex_id)
	var edge_length := from_vertex.position.distance_to(to_vertex.position)
	var speed := to_vertex.get_effective_speed(path_data.default_speed)
	_edge_time_remaining = 0.0
	_edge_time_length = max(edge_length / speed, 0.0001)
	_state = State.MOVING


## (Re)Initializes the vertex state variables to begin a previous vertex.
func _arrive_at_previous_vertex():
	var vertex = path_data.get_vertex_by_id(_target_vertex_id)
	_cur_action_index = vertex.actions.size()-1
	if _cur_action_index > 0:
		_action_wait_remaining = vertex.actions[_cur_action_index].get_block_time()
	else:
		_action_wait_remaining = 0
	_state = State.DWELLING


## Handles the behavior for a forward step when in the FINISHED state.
func _finished_backward_step(remaining):
	var consumed := minf(remaining, _path_time - _time_finished)
	_path_time -= consumed
	if _path_time <= _time_finished:
		_time_finished = -1
		_state = State.DWELLING
	return remaining - consumed
