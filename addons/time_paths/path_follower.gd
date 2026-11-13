@tool
class_name PathFollower extends Node3D

const MISSING_ANIMATION_PLAYER_WARNING: String = "An AnimationPlayer needs to be assingned for rotation of the PathFollower"
const MISSING_CW_ANIMATION_WARNING: String = "No track name assigned for clockwise rotation"
const MISSING_CCW_ANIMATION_WARNING: String = "No track name assigned for counter-clockwise rotation"
const DEFAULT_ANIMATION_LIBRARY_NAME: String = "DEFAULT_ROTATION_ANIMATION_LIBRARY"
const DEFAULT_CW_ANIMATION_PATH: String = "res://addons/time_paths/resources/clockwise_default_animation.tres"
const DEFAULT_CW_ANIMATION_NAME: String = "DEFAULT_CLOCKWISE_ANIMATION"
const DEFAULT_CCW_ANIMATION_PATH: String = "res://addons/time_paths/resources/counter_clockwise_default_animation.tres"
const DEFAULT_CCW_ANIMATION_NAME: String = "DEFAULT_COUNTER_CLOCKWISE_ANIMATION"

signal vertex_reached(vertex_id: int)
signal action_executed(vertex_id: int, action: VertexAction)
signal edge_entered(edge_id: int)
signal path_finished

enum State { UNSTARTED, PRE_DELAY, DWELLING, MOVING, FINISHED}

## The [PathData] that this [PathFollower] will follow.
@export var path_data: PathData:
	set(value):
		path_data = value
		if Engine.is_editor_hint() and is_inside_tree():
			if path_data != null:
				_snap_to_start()
			update_gizmos()

## The time offset that the path follower will be following the path off of. [br]
## If start_offset > 0, the follower will begin the path at start_offset seconds. [br]
## If start_offset < 0, the follower will begin at start_offset seconds into the path.
@export var start_offset: float = 0.0

## If true, the [PathFollower] will be moved with the Time Paths Plugin preview scrubber.
@export var editor_preview_enabled: bool = true

## If true, a preview of the assigned path will be displayed in the 3D editor.
@export var show_path_gizmo: bool = true:
	set(value):
		show_path_gizmo = value
		update_gizmos()

## If true, calls [method PathFollower.start] automatically in _ready().
@export var auto_start: bool = true

## If true, the [PathFollower] will drive itself using built-in process. [br]
## Set false if external code will be calling [method PathFollower.advance] directly.
@export var run_process: bool = true

@export_category("Rotation")
## Whether rotation should be enabled for the path follower. [br]
## If so, will use default rotation animations to turn towards the direction of movement.
@export var rotation_enabled: bool = false:
	set(value):
		rotation_enabled = value
		update_configuration_warnings()
		notify_property_list_changed()


## Export button to automatically add an animation player (if one is not assigned) and add the default animations to the player (either the assigned or newly created one) 
@export_tool_button("Add Default Animations") var add_default_animations: Callable = _add_default_animations


## The animation player that will be used for animating the rotation of the follower as it follows the path. [br]
## Implemented as an animation player to allow for more control on how rotations behave. [br]
@export var rotation_animation_player: AnimationPlayer:
	set(value):
		if value != rotation_animation_player:
			if rotation_animation_player:
				rotation_animation_player.animation_list_changed.disconnect(notify_property_list_changed)
			if value:
				value.animation_list_changed.connect(notify_property_list_changed)
		rotation_animation_player = value
		update_configuration_warnings()
		notify_property_list_changed()

## Animation to play when the follower is turning clockwise. [br]
## Uses default animations if unset. 1 Second = 1 degree of rotation, 0 degrees is facing the -Z axis. Animation should loop.
@export var clockwise_animation: StringName:
	set(value):
		clockwise_animation = value
		update_configuration_warnings()

## Animation to play when the follower is turning counter-clockwise. [br]
## Uses default animations if unset. 1 Second = 1 degree of rotation, 0 degrees is facing the -Z axis. Animation should loop.
@export var counter_clockwise_animation: StringName:
	set(value):
		counter_clockwise_animation = value
		update_configuration_warnings()

## Speed of clockwise rotation in degrees per second.
@export var clockwise_rotation_speed: float = 1

## Speed of counter-clockwise rotation in degrees per second.
@export var counter_clockwise_rotation_speed: float = 1

## The current [enum PathFollower.State] of the [PathFollower]
var _state: State = State.UNSTARTED

## Whether the [PathFollower] is [i]travelling[/i] backwards or forwards along the path. [br]
## Not to be confused with rewinding. This is used purely for Ping Pong paths.
var _travelling_backward: bool = false

## If [member PathFollower._state] is State.DWELLING or State.BLOCKED_EXTERNAL, represents the vertex that the [PathFollower] is dwelling at. [br]
## If [member PathFollower._state] == State.MOVING, represents the vertex that the [PathFollower] is travelling [i]from[/i]. [br]
## In all other states, _current_vertex_id is undefined.
var _current_vertex_id: int = -1

## If [member PathFollower._state] == State.MOVING, represents the vertex that the [PathFollower] is travelling [i]to[/i]. [br]
## In all other states, _current_vertex_id is undefined.
var _target_vertex_id: int = -1

## If [member PathFollower._state] == State.MOVING, represents the edge that the [PathFollower] is travelling along. [br]
## In all other states, _current_vertex_id is undefined.
var _current_edge_id: int = -1

## The current action that is being executed during vertex dwell. -1 whenever not dwelling.
var _cur_action_index: int = -1

## Represents how much longer to wait while dwelling on a vertex.
var _action_wait_remaining: float = 0

## How much time is left in State.PRE_DELAY. [br]
## When in State.UNSTARTED should be equal to [member start_offset] and 0 when in State.PRE_DELAY.
var _pre_delay_remaining: float = 0

## The amount of time left moving along the current [PathEdge].
## -1 if not in State.MOVING.
var _edge_time_remaining: float = 0

## The total amount time that it takes to move along the current [PathEdge] (from start vertex to end vertex).
## -1 if not in State.MOVING.
var _edge_time_length: float = 0.0001

## The id of the [PathEdge] that will be taken due to [BranchAction]s. [br]
## -1 if there are no [BranchAction]s 
var _branch_edge_id: int = -1

## Elapsed time since [method PathFollower.start]. Includes [member time_offset]. 
var _path_time: float = 0

## Array of [PathEdge] ids in the order that they are taken. Consumed during Ping Pong backward retrace.
var _edge_history: Array[int]

#region preview
## Set true by the Time Paths preview scrubber when it is driving this node. [br]
## Used when executing a [VertexAction] that would need real conditions (i.e. [BranchAction], [InteractAction])
var is_preview_driving: bool = false
#endregion


#region rotation
## Goal time of current rotation animation. Undefined if not animating.
var _rotation_goal: float = 0
## A flag for whether the rotation track needs to loop before it has actually reached its goal.
var _needs_loop_before_goal: bool = false
#endregion


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		add_to_group("time_path_followers")


func _ready() -> void:
	if Engine.is_editor_hint():
		if path_data != null:
			_snap_to_start()
		update_gizmos()
	else:
		if rotation_animation_player:
			rotation_animation_player.root_node = rotation_animation_player.get_path_to(self)
		if auto_start and path_data != null:
			start()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		pass
	else:
		if run_process:
			advance(delta)


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		add_to_group("time_path_followers")


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	if rotation_enabled:
		if rotation_animation_player == null:
			warnings.append(MISSING_ANIMATION_PLAYER_WARNING)
		if rotation_animation_player and clockwise_animation == "":
			warnings.append(MISSING_CW_ANIMATION_WARNING)
		if rotation_animation_player and counter_clockwise_animation == "":
			warnings.append(MISSING_CCW_ANIMATION_WARNING)
	return warnings


func _validate_property(property: Dictionary) -> void:
	if property.name in [&"rotation_animation_player",&"clockwise_rotation_speed",&"counter_clockwise_rotation_speed",&"add_default_animations"]:
		if not rotation_enabled:
			property.usage &= ~PROPERTY_USAGE_EDITOR
			return
	elif property.name in [&"clockwise_animation",&"counter_clockwise_animation"]:
		if not rotation_enabled or not rotation_animation_player:
			property.usage &= ~PROPERTY_USAGE_EDITOR
			return
		else:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = ",".join(rotation_animation_player.get_animation_list())


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_gizmos()


# Moves the node to the path_data's root vertex (starting point)
func _snap_to_start():
	if path_data == null:
		return
	var root := path_data.get_start_vertex()
	if root != null:
		global_position = root.position


## Called by Time Paths plugin when preview scrubbing is disabled to return followers to start.
func reset_to_start() -> void:
	is_preview_driving = false
	_snap_to_start()


## Move through the path delta seconds. Will only accept delta >= 0.
func advance(delta: float) -> void:
	if path_data == null or _state == State.UNSTARTED:
		return
	elif delta > 0:
		_forward_step(delta)
	elif delta < 0:
		_backward_step(delta)
	_update_transform()


## Seeks to the position in the path at [parameter time] after path start.
func seek(time: float) -> void:
	advance(time - _path_time)


## Sets the branch to take next after the current vertex. Will be overridden by subsequent set_branch_to_take calls.
func set_branch_to_take(edge_id: int) -> void:
	_branch_edge_id = edge_id


## Begins rotation toward the target direction. Uses shortest path for turn direction. [br]
## [parameter target_direction] will be projected onto the xz plane to get direction.
func start_turn(target_direction: Vector3):
	if Engine.is_editor_hint():
		return
	if not rotation_animation_player:
		push_warning("No rotation animation player assigned for path follower! Cannot rotate.")
		return
	var current: float = rotation.y
	var target: float = Vector3.FORWARD.signed_angle_to(Vector3(target_direction.x,0,target_direction.z),Vector3.UP)
	# Represents amount and direction of turn in radians. Positive -> CCW, Negative CW (when viewed from above)
	var turn_value: float = fposmod(target-current, 2*PI)
	if turn_value > PI:
		turn_value -= 2*PI
	var current_rotation: float
	if turn_value < 0: #clockwise
		_rotation_goal = 360 - fposmod(rad_to_deg(target),360)
		current_rotation = 360-fposmod(rad_to_deg(current),360)
		begin_rotation_animation(true,current_rotation)
	elif turn_value > 0: #counter-clockwise
		_rotation_goal = fposmod(rad_to_deg(target),360)
		current_rotation = fposmod(rad_to_deg(current),360)
		begin_rotation_animation(false,current_rotation)
	if current_rotation > _rotation_goal:
		_needs_loop_before_goal = true

## Begins the rotation animation player. [br]
## If [paramter clockwise] is true, rotates clockwise, else rotates counter-clockwise
## See [property clockwise_animations] or [property counter_clockwise_animations] for interpretation of [parameter start_time]
## This function and can be overridden if custom animation players are used.
func begin_rotation_animation(clockwise:bool, start_time: float):
	if clockwise:
		rotation_animation_player.play(clockwise_animation,-1,clockwise_rotation_speed)
	else:
		rotation_animation_player.play(counter_clockwise_animation,-1,counter_clockwise_rotation_speed)
	rotation_animation_player.seek(start_time,true)

## Used by the [property add_default_animations] export button to add an animation player (if one is not assigned) and add the default animations to it (or to the assigned AnimationPlayer).
func _add_default_animations() -> void:
	if not rotation_animation_player:
		var new_player: AnimationPlayer = AnimationPlayer.new()
		new_player.name = "AnimationPlayer"
		var undo_redo: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
		undo_redo.create_action("Create Default Rotation AnimationPlayer")
		undo_redo.add_do_method(self,"add_child",new_player)
		undo_redo.add_do_property(new_player,"owner",get_tree().edited_scene_root)
		undo_redo.add_do_property(self,"rotation_animation_player",new_player)
		undo_redo.add_do_reference(new_player)
		undo_redo.add_undo_method(self,"remove_child",new_player)
		undo_redo.add_undo_property(self,"rotation_animation_player",rotation_animation_player)
		undo_redo.commit_action()
	if rotation_animation_player.has_animation_library(DEFAULT_ANIMATION_LIBRARY_NAME):
		return
	var animation_library: AnimationLibrary = AnimationLibrary.new()
	if rotation_animation_player.has_animation(DEFAULT_CW_ANIMATION_NAME):
		push_warning("The animation player already has the default clockwise animation added.")
	else:
		animation_library.add_animation(DEFAULT_CW_ANIMATION_NAME,load(DEFAULT_CW_ANIMATION_PATH))
	if rotation_animation_player.has_animation(DEFAULT_CCW_ANIMATION_PATH):
		push_warning("The animation player already has the default counter clockwise animation added.")
	else:
		animation_library.add_animation(DEFAULT_CCW_ANIMATION_NAME,load(DEFAULT_CCW_ANIMATION_PATH))
	if not animation_library.get_animation_list().is_empty():
		rotation_animation_player.add_animation_library(DEFAULT_ANIMATION_LIBRARY_NAME,animation_library)
	clockwise_animation = DEFAULT_ANIMATION_LIBRARY_NAME + "/" + DEFAULT_CW_ANIMATION_NAME
	counter_clockwise_animation = DEFAULT_ANIMATION_LIBRARY_NAME + "/" + DEFAULT_CCW_ANIMATION_NAME

## Returns how long the follower has been following the path. Accounts for start offset. See [method get_current_time] to get the current time along the path. Does not account for any re-traversing of the path.
func get_elapsed_time() -> float:
	return _path_time - start_offset


## Returns how far into the path the follower is in seconds. Does not account for start offset. See [method get_elapsed_time] to get amount of time follower has been following path.
func get_current_time() -> float:
	return _path_time


## Returns true if the follower is finished with the path.
func is_finished() -> bool:
	return _state == State.FINISHED


## Initializes the follower at path_data's root and begins simulating. Reinitializes if already initialized.
## Safe to call again to restart from scratch.
func start() -> void:
	if path_data == null:
		push_warning("[PathFollower] No path_data assigned.")
		return
	var root: PathVertex = path_data.get_start_vertex()
	if root == null:
		push_warning("[PathFollower] path_data has no root vertex (empty graph?).")
		return
	
	_current_vertex_id = root.id
	_target_vertex_id = -1
	_current_edge_id = -1
	_travelling_backward = false
	_cur_action_index = 0
	_action_wait_remaining = -1.0
	_edge_time_remaining = -1
	_edge_time_length = 0.0001
	_branch_edge_id = -1
	_path_time = 0.0
	_edge_history.clear()
	
	if start_offset > 0.0:
		_state = State.PRE_DELAY
		_pre_delay_remaining = start_offset
	else:
		_state = State.DWELLING
	
	_update_transform()

#region Forward Simulation

## Steps forward into the path by [parameter delta] seconds
func _forward_step(delta: float) -> void:
	var remaining := delta
	while remaining > 0.0 and _state != State.FINISHED:
		var before_step := remaining
		match _state:
			State.PRE_DELAY:
				remaining = _pre_delay_forward_step(remaining)
			State.DWELLING:
				remaining = _dwelling_forward_step(remaining)
			State.MOVING:
				remaining = _moving_forward_step(remaining)
			_:
				break
		if rotation_animation_player and rotation_animation_player.is_playing():
			if _needs_loop_before_goal:
				if rotation_animation_player.current_animation_position < _rotation_goal:
					_needs_loop_before_goal = false
			elif rotation_animation_player.current_animation_position >= _rotation_goal:
				rotation_animation_player.seek(_rotation_goal,true)
				rotation_animation_player.pause()


## Handles the behavior for a forward step when in the PRE_DELAY state.
func _pre_delay_forward_step(remaining) -> float:
	var consumed := minf(remaining, _pre_delay_remaining)
	_path_time += consumed
	_pre_delay_remaining -= consumed
	if _pre_delay_remaining <= 0.0:
		_pre_delay_remaining = 0.0
		_state = State.DWELLING
	return remaining - consumed


## Handles the behavior for a forward step when in the DWELLING state.
func _dwelling_forward_step(remaining) -> float:
	var vertex: PathVertex = path_data.get_vertex_by_id(_current_vertex_id)
	if vertex == null:
		_state = State.FINISHED
		return remaining
	
	if _cur_action_index >= vertex.actions.size():
		_begin_next_edge()
		return remaining
	
	var action: VertexAction = vertex.actions[_cur_action_index]
	
	if _action_wait_remaining < 0.0:
		# Haven't executed this action yet this pass.
		if action == null or not action.enabled or not _direction_allows(action):
			_cur_action_index += 1
			return remaining
	
		var wait_time: float = action._execute(self)
		action_executed.emit(_current_vertex_id, action)
	
		if wait_time <= 0.0:
			_cur_action_index += 1
			return remaining
		else:
			_action_wait_remaining = wait_time
			# fall through to consume time below
	
	var consumed := minf(remaining, _action_wait_remaining)
	_path_time += consumed
	_action_wait_remaining -= consumed
	if _action_wait_remaining <= 0.0:
		_cur_action_index += 1
		_action_wait_remaining = -1.0
	return remaining - consumed


## Handles the behavior for a forward step when in the MOVING state.
func _moving_forward_step(remaining: float) -> float:
	var consumed := minf(remaining, _edge_time_remaining)
	_path_time += consumed
	_edge_time_remaining -= consumed
	if _edge_time_remaining <= 0.0:
		if not _travelling_backward:
			_edge_history.append(_current_edge_id)
		_current_vertex_id = _target_vertex_id
		_arrive_at_vertex()
	return remaining - consumed


## Returns whether the action can be executed in the current direction.
func _direction_allows(action: VertexAction) -> bool:
	match action.execution_direction:
		VertexAction.ExecutionDirection.FORWARD_ONLY:
			return not _travelling_backward
		VertexAction.ExecutionDirection.BACKWARD_ONLY:
			return _travelling_backward
		_:
			return true


## Call to begin the next edge from a vertex. If there is a branch, uses [parameter _branch_edge_id] to choose which to take.
func _begin_next_edge() -> void:
	var edge: PathEdge
	
	if not _travelling_backward:
		edge = _pick_forward_edge(_current_vertex_id)
		if edge == null:
			_handle_forward_terminal()
			return
		_target_vertex_id = edge.to_vertex
	else:
		if _edge_history.is_empty():
			_handle_backward_terminal()
			return
		var last: Dictionary = _edge_history.pop_back()
		edge = path_data.get_edge_by_id(last["edge_id"])
		if edge == null:
			_handle_backward_terminal()
			return
		_target_vertex_id = edge.from_vertex  # walking it in reverse
	
	_current_edge_id = edge.id
	
	var from_vertex := path_data.get_vertex_by_id(_current_vertex_id)
	var to_vertex := path_data.get_vertex_by_id(_target_vertex_id)
	var edge_length := from_vertex.position.distance_to(to_vertex.position)
	var speed := to_vertex.get_effective_speed(path_data.default_speed)
	_edge_time_remaining = edge_length / speed if speed > 0.0 else 0.0
	_edge_time_length = max(_edge_time_remaining, 0.0001)
	
	var new_direction := (to_vertex.position - from_vertex.position).normalized()
	if rotation_enabled and new_direction != Vector3.ZERO and not to_vertex.suppress_incoming_turn:
		start_turn(new_direction)
	
	edge_entered.emit(_current_edge_id)
	_state = State.MOVING


## Returns the [class PathEdge] that should be taken from the current vertex. Uses [parameter _branch_edge_id] or picks default if unset.
func _pick_forward_edge(vertex_id: int) -> PathEdge:
	if _branch_edge_id != -1:
		var chosen := path_data.get_edge_by_id(_branch_edge_id)
		if chosen != null and chosen.from_vertex == vertex_id:
			return chosen
		push_warning("[PathFollower] BranchAction targeted edge %d, which isn't a valid outgoing edge of vertex %d -- falling back to the default edge." % [_branch_edge_id, vertex_id])
	return _pick_default_edge(vertex_id)


## Returns the default [class PathEdge] from the current vertex.
func _pick_default_edge(vertex_id: int) -> PathEdge:
	var outgoing := path_data.get_outgoing_edges(vertex_id)
	if outgoing.is_empty():
		return null
	var best: PathEdge = outgoing[0]
	for e in outgoing:
		if e.id < best.id:
			best = e
	return best


## Deals with what happens when follower reaches the end of the path.
func _handle_forward_terminal() -> void:
	match path_data.path_type:
		PathData.PathType.LOOP:
			var root := path_data.get_start_vertex()
			if root == null:
				_state = State.FINISHED
				path_finished.emit()
				return
			_current_vertex_id = root.id
			_edge_history.clear()
			_arrive_at_vertex()
		PathData.PathType.PING_PONG:
			_travelling_backward = true
			_cur_action_index = 0
			_action_wait_remaining = -1.0
			_branch_edge_id = -1
			_state = State.DWELLING
		_:  
			_state = State.FINISHED
			path_finished.emit()


## Handles what happens when the follower reaches the beginning of the path again when in PING-PONG mode.
func _handle_backward_terminal() -> void:
	_travelling_backward = false
	_cur_action_index = 0
	_action_wait_remaining = -1.0
	_branch_edge_id = -1
	_state = State.DWELLING


## Handles the follower reaching a vertex at the end of the edge.
func _arrive_at_vertex() -> void:
	vertex_reached.emit(_current_vertex_id)
	_cur_action_index = 0
	_action_wait_remaining = -1.0
	_branch_edge_id = -1
	_state = State.DWELLING
#endregion

## Computes the position of the follower given its current state variables.
func get_computed_position() -> Vector3:
	if path_data == null:
		return Vector3.ZERO

	match _state:
		State.MOVING:
			var from_vertex := path_data.get_vertex_by_id(_current_vertex_id)
			var to_vertex := path_data.get_vertex_by_id(_target_vertex_id)
			if from_vertex != null and to_vertex != null:
				var t: float = 1.0 - (_edge_time_remaining / _edge_time_length)
				return from_vertex.position.lerp(to_vertex.position, clampf(t, 0.0, 1.0))
			return Vector3.ZERO
		_:
			var vertex := path_data.get_vertex_by_id(_current_vertex_id)
			return vertex.position if vertex != null else Vector3.ZERO


## Updates the followers transform to be in the correct position.
func _update_transform() -> void:
	if is_inside_tree():
		global_position = get_computed_position()

#region Backward Simulation (Unimplemented)

## Called when the follower should take a step of [parameter delta] seconds backwards in its path. Unimplemented, but left to be overridden to implement backtravelling.
func _backward_step(delta: float):
	push_warning("Backward step is unimplemented for this PathFollower")
#endregion
