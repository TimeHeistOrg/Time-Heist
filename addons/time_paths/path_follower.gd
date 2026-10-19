@tool
class_name PathFollower extends Node3D
## Walks a PathData graph over time. Deliberately has ZERO knowledge of any
## time-manipulation system -- it's driven by a single signed delta each
## frame (advance()), fed either by its own _process() or by external code
## (e.g. a game's TimeManager). See the addon's conversation history for the
## full design rationale; the short version:
##
## - advance(delta > 0): real forward simulation. Actions execute, branch
##   conditions are evaluated FRESH every time (so changed game state can
##   send the follower down a different branch than last time -- this is
##   intentional, not a bug). Used for both normal per-frame play AND
##   fast-forward (same code path, just bigger/more frequent deltas).
## - advance(delta < 0): pure position lookup into already-recorded history.
##   Never executes actions, never re-evaluates branches. Whatever undoes
##   the actual side effects of those past actions (a TimeVar system, or
##   whatever else) is expected to happen OUTSIDE this class entirely --
##   the follower only moves its own position backward to match.
## - Resuming forward after a rewind re-simulates fresh from wherever you
##   are, discarding whatever "future" was previously recorded -- it may no
##   longer be valid if branch conditions have since changed.
##
## PathVertex.position is authored as a GLOBAL/world coordinate in the
## editor tool, so this uses global_position throughout, never local
## position -- otherwise the follower would land in the wrong place
## whenever it isn't a direct child of the scene root.
##
## @tool ONLY for the in-editor "snap to the path's start position the
## moment path_data is assigned" convenience (see the path_data setter
## below) -- _ready()/_process() are guarded to never actually simulate
## while running inside the editor.
##
## Side-effecting actions (InteractAction, etc) are NOT gated against
## "have I already done this" -- there's deliberately no visited-vertex
## tracking here. Rewind never re-fires them (pure lookup, see above), and
## fast-forward re-firing them for real, every time, with fresh conditions,
## is the correct behavior for this game's rewind mechanic (see
## conversation). If a different game needs idempotent side effects, that
## belongs in the action's own _execute() logic, not here.

signal vertex_reached(vertex_id: int)
signal action_executed(vertex_id: int, action: VertexAction)
signal edge_entered(edge_id: int)
signal path_finished

## Snaps global_position to path_data's root vertex the moment this is
## assigned in the editor, so you can see/place the follower correctly
## without needing to run the game first. Does nothing at runtime beyond
## the assignment itself -- normal simulation, not this setter, is what
## positions the follower once the game is actually running.
@export var path_data: PathData:
	set(value):
		path_data = value
		# is_inside_tree() guard matters: scene deserialization (loading a
		# .tscn that already has path_data assigned) sets this property
		# BEFORE the node enters the tree, and global_position requires
		# walking the parent chain -- inaccessible at that point. _ready()
		# (which only ever runs once genuinely in the tree) handles the
		# snap for that case; this branch only fires for a LIVE assignment
		# while the node's already in an open, running scene.
		if Engine.is_editor_hint() and path_data != null and is_inside_tree():
			_snap_to_start()
		if Engine.is_editor_hint() and is_inside_tree():
			update_gizmos()

## Per-instance -- NOT on PathData, since the same path can be shared by
## many followers that should each be able to start at a different offset.
@export var start_delay: float = 0.0

## Set true whenever the editor's scrub-sync preview is driving this node
## (see EditorPlugin group-based sync -- this node adds itself to the
## "time_paths_followers" group while in the editor, and the plugin syncs
## every member to the scrub slider's time). BranchAction/InteractAction
## check this to skip evaluating real conditions and skip real side
## effects -- there's no live game state to evaluate against during
## editing, and a blocking InteractAction would hang the preview forever
## since nothing will ever call resume(). WaitAction durations are still
## respected either way, since timing is safe/deterministic and worth
## previewing accurately.
var is_editor_preview: bool = false

## Per-follower opt-out for the editor's scrub-sync preview -- lets you
## narrow a scene with many followers down to watching just one or two at
## a time instead of all of them moving together.
@export var editor_preview_enabled: bool = true

## Shows the currently-assigned path as a quiet, semi-transparent gizmo in
## the 3D viewport (see PathFollowerGizmoPlugin) -- independent of scrub
## preview, this is just "can I see where this thing goes" at a glance.
## Per-follower so a scene with many followers can be narrowed down to just
## the one you're looking at.
@export var show_path_gizmo: bool = true:
	set(value):
		show_path_gizmo = value
		update_gizmos()

## If true, calls start() automatically in _ready().
@export var auto_start: bool = true

## If true, this node drives itself via its own _process(delta). Turn this
## off if external code (a TimeManager) is going to call advance() directly
## instead -- e.g. with a signed, possibly-rewinding delta.
@export var auto_process: bool = true


enum _State { UNSTARTED, PRE_DELAY, DWELLING, MOVING, BLOCKED_EXTERNAL, FINISHED }

var _state: _State = _State.UNSTARTED

var _current_vertex_id: int = -1
var _target_vertex_id: int = -1
var _current_edge_id: int = -1

## +1 = walking outgoing edges normally. -1 = PING_PONG retrace, walking
## edges backward in the exact order they were originally taken (see
## _edge_history) -- NOT a fresh graph traversal via incoming edges, since
## that would be ambiguous wherever branching happened.
var _direction: int = 1

var _action_index: int = 0
## -1.0 = haven't executed the current action yet this pass. >= 0 = mid-wait,
## counting down (only meaningful for actions that returned a duration).
var _action_wait_remaining: float = -1.0

var _pre_delay_remaining: float = 0.0

var _edge_travel_remaining: float = 0.0
var _edge_travel_total: float = 0.0001  # guards div-by-zero in transform lerp

## The edge id a BranchAction wants taken next, set via take_branch(). Reset
## to -1 on arrival at each vertex; whichever BranchAction call happens LAST
## during that vertex's dwell wins (each call just overwrites this).
var _pending_branch_edge_id: int = -1

## Elapsed time since start() (post start_delay). This is the "timeline"
## position -- what advance()/seek() move, and what history is recorded
## against.
var _current_time: float = 0.0

## The furthest _current_time has ever reached via real forward simulation.
## _current_time < _frontier_time means we're currently rewound relative to
## how far we've actually simulated.
var _frontier_time: float = 0.0

## Recorded (time, vertex_id) checkpoints in chronological order, built as
## real forward simulation happens. Rewind interpolates position from this
## directly; a dwell segment is two consecutive entries with the SAME
## vertex_id (arrival, then departure), a travel segment is two with
## DIFFERING vertex_id.
var _keyframes: Array[Dictionary] = []
var _seek_cache_index: int = 0

## (time, edge_id) for each edge actually traversed going forward, in
## order -- consumed (popped) during PING_PONG's backward retrace to know
## exactly which edge to walk back next.
var _edge_history: Array[Dictionary] = []

## The follower's CURRENT facing, smoothly interpolated toward whatever the
## most recent turn target was (see begin_turn()) -- this is what actually
## gets applied to the node's real rotation every _update_transform() call.
## Used to be just a static "direction of the current edge" placeholder;
## now genuinely live.
var _facing_direction: Vector3 = Vector3.FORWARD

## How fast the follower turns, in degrees/second -- used for BOTH the
## automatic "turn toward the next edge as I depart" behavior and any
## explicit FaceAction. "Fast but not a snap" per the design conversation;
## 720 deg/sec means even a full 180-degree reversal only takes 0.25s.
@export var rotation_speed_degrees: float = 720.0

var _turn_from_direction: Vector3 = Vector3.FORWARD
var _turn_to_direction: Vector3 = Vector3.FORWARD
var _turn_duration: float = 0.0
var _turn_elapsed: float = 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		if path_data != null:
			_snap_to_start()
		update_gizmos()
		return
	if auto_start and path_data != null:
		start()


func _enter_tree() -> void:
	# "time_paths_followers" group membership is how the editor plugin
	# finds followers to sync during scrub preview, WITHOUT either side
	# needing a direct reference to the other -- works correctly even
	# across a game-specific subclass, unlike e.g. a static registry tied
	# to this exact script. Never registers outside the editor, so this
	# has zero footprint during real gameplay.
	if Engine.is_editor_hint():
		add_to_group("time_paths_followers")


func _exit_tree() -> void:
	if Engine.is_editor_hint():
		remove_from_group("time_paths_followers")


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if auto_process:
		advance(delta)


## Editor-only convenience: moves the node to path_data's root vertex
## position without touching any simulation state (_state stays UNSTARTED
## until start() actually runs at real game-start). Purely visual, so you
## can see where the NPC will begin without running the game. Also used to
## restore a follower to its authored position when scrub-sync preview is
## turned off, via the public reset_to_start() wrapper below.
func _snap_to_start() -> void:
	if path_data == null:
		return
	var root := path_data.get_start_vertex()
	if root != null:
		global_position = root.position


## Public wrapper for _snap_to_start() -- called by the editor plugin when
## scrub-sync preview is disabled, to put followers back where they were
## rather than leaving them stuck wherever the last scrub position left
## them. Also clears is_editor_preview, since this follower is no longer
## being driven by the preview.
func reset_to_start() -> void:
	is_editor_preview = false
	_snap_to_start()


## The single entry point for driving the follower. Positive = real forward
## simulation (normal play or fast-forward, same code path). Negative =
## pure backward position lookup (rewind). Zero is a no-op.
func advance(delta: float) -> void:
	if path_data == null or _state == _State.UNSTARTED:
		return
	if delta > 0.0:
		_advance_forward(delta)
	elif delta < 0.0:
		_rewind(-delta)
	_update_transform()


## Jumps directly to an absolute timeline position -- equivalent to
## advance(time - current), exposed separately since "seek to a specific
## time" (editor scrub preview, loading into a specific moment while still
## simulating forward from scratch) is a more natural way to think about it
## than computing a delta yourself.
func seek(time: float) -> void:
	advance(time - _current_time)


## Call this to unblock an action that returned VertexAction.BLOCK_EXTERNAL
## (e.g. once whatever external system --dialogue, animation-- is done).
func resume() -> void:
	if _state != _State.BLOCKED_EXTERNAL:
		return
	_action_index += 1
	_action_wait_remaining = -1.0
	_state = _State.DWELLING


## Called by BranchAction. The LAST call during a given vertex's dwell wins
## -- see the class doc on BranchAction for why this doesn't interrupt the
## action list.
func take_branch(edge_id: int) -> void:
	_pending_branch_edge_id = edge_id


## Starts turning toward target_direction, at rotation_speed_degrees.
## Returns the computed duration -- callers decide what to do with it:
## automatic edge-departure turning (see _begin_next_edge) ignores it, since
## that turn happens non-blocking, alongside movement. FaceAction returns
## it as its own blocking wait, matching "turning takes time and it can be
## calculated" -- same duration either way, just different consequences for
## the caller. Progresses via _step_turn(), called every tick regardless of
## what state (moving/dwelling/etc) the follower is currently in, so a turn
## in progress is never frozen or skipped over.
func begin_turn(target_direction: Vector3) -> float:
	if target_direction == Vector3.ZERO:
		return 0.0
	target_direction = target_direction.normalized()

	if _facing_direction == Vector3.ZERO:
		_facing_direction = target_direction
		return 0.0

	var angle := _facing_direction.angle_to(target_direction)
	var duration := 0.0
	if rotation_speed_degrees > 0.0:
		duration = rad_to_deg(angle) / rotation_speed_degrees

	_turn_from_direction = _facing_direction
	_turn_to_direction = target_direction
	_turn_duration = duration
	_turn_elapsed = 0.0
	return duration


func _step_turn(delta: float) -> void:
	if delta <= 0.0 or _turn_elapsed >= _turn_duration:
		return
	_turn_elapsed = minf(_turn_elapsed + delta, _turn_duration)
	var t: float = 1.0 if _turn_duration <= 0.0 else _turn_elapsed / _turn_duration
	_facing_direction = _turn_from_direction.slerp(_turn_to_direction, t).normalized()


func get_elapsed_time() -> float:
	return _current_time


func get_facing_direction() -> Vector3:
	return _facing_direction


func is_finished() -> bool:
	return _state == _State.FINISHED


## (Re)initializes the follower at path_data's root and begins simulating.
## Safe to call again to restart from scratch.
func start() -> void:
	if path_data == null:
		push_warning("[PathFollower] No path_data assigned.")
		return
	var root := path_data.get_start_vertex()
	if root == null:
		push_warning("[PathFollower] path_data has no root vertex (empty graph?).")
		return

	_current_vertex_id = root.id
	_target_vertex_id = -1
	_current_edge_id = -1
	_direction = 1
	_action_index = 0
	_action_wait_remaining = -1.0
	_edge_travel_remaining = 0.0
	_edge_travel_total = 0.0001
	_pending_branch_edge_id = -1
	_current_time = 0.0
	_frontier_time = 0.0
	_edge_history.clear()
	_keyframes.clear()
	_keyframes.append({"time": 0.0, "vertex_id": root.id})
	_seek_cache_index = 0
	_facing_direction = Vector3.FORWARD

	if start_delay > 0.0:
		_state = _State.PRE_DELAY
		_pre_delay_remaining = start_delay
	else:
		_state = _State.DWELLING

	_update_transform()


## Loads a previously-saved traversal state directly, WITHOUT re-simulating
## anything -- for game-load, where the save data (not path re-derivation)
## is the source of truth for what actually happened, including which
## branches were taken. See conversation: re-simulating at load time risks
## double-firing side effects your save system already persisted, and can
## silently diverge if game state differs from when it was first played.
##
## NOTE: only supports restoring to a vertex boundary (DWELLING at
## action_index 0), not mid-edge or mid-action -- if you need finer-grained
## save points than "just arrived at vertex N", this needs extending.
## Restores a full snapshot from get_state() -- works from ANY point the
## follower could have been at (mid-edge, mid-action-wait, mid-turn), not
## just a vertex boundary. Sets every internal field directly rather than
## trying to re-derive a valid state from a simplified summary, so nothing
## resumes/snaps abruptly on load: an in-progress WaitAction picks up with
## exactly its remaining duration, a mid-turn continues interpolating from
## exactly where it left off, etc.
##
## Trusts the caller's data as the source of truth -- doesn't re-simulate
## or re-validate any of it (that's the whole point, see the class doc on
## why re-simulating at load time is the wrong call). One real caveat: if
## the saved state has _state == BLOCKED_EXTERNAL (mid an InteractAction
## waiting on resume()), nothing will call resume() again after loading
## unless your own game logic re-arms whatever was going to call it --
## that's on your side to handle, not something this can generically do.
func restore_state(data: Dictionary) -> void:
	if path_data == null:
		push_warning("[PathFollower] Cannot restore_state with no path_data assigned.")
		return
	var vertex_id: int = data.get("current_vertex_id", -1)
	if path_data.get_vertex_by_id(vertex_id) == null:
		push_warning("[PathFollower] restore_state: vertex_id %s not found in path_data." % str(vertex_id))
		return

	_state = data.get("state", _State.DWELLING)
	_current_vertex_id = vertex_id
	_target_vertex_id = data.get("target_vertex_id", -1)
	_current_edge_id = data.get("current_edge_id", -1)
	_direction = data.get("direction", 1)
	_action_index = data.get("action_index", 0)
	_action_wait_remaining = data.get("action_wait_remaining", -1.0)
	_pre_delay_remaining = data.get("pre_delay_remaining", 0.0)
	_edge_travel_remaining = data.get("edge_travel_remaining", 0.0)
	_edge_travel_total = data.get("edge_travel_total", 0.0001)
	_pending_branch_edge_id = data.get("pending_branch_edge_id", -1)
	_current_time = data.get("current_time", 0.0)
	_frontier_time = _current_time
	_edge_history = data.get("edge_history", [])

	_facing_direction = data.get("facing_direction", Vector3.FORWARD)
	_turn_from_direction = data.get("turn_from_direction", _facing_direction)
	_turn_to_direction = data.get("turn_to_direction", _facing_direction)
	_turn_duration = data.get("turn_duration", 0.0)
	_turn_elapsed = data.get("turn_elapsed", 0.0)

	# No history before a load boundary -- rewind can't go earlier than this.
	_keyframes = [{"time": _current_time, "vertex_id": _current_vertex_id}]
	_seek_cache_index = 0

	_update_transform()


## Companion to restore_state() -- captures EVERY field relevant to
## resuming from exactly this point, whatever state the follower is
## currently in (mid-edge, mid-action-wait, mid-turn, etc). Always
## returns a valid dictionary; there's no state this can be called from
## that it can't represent.
func get_state() -> Dictionary:
	return {
		"state": _state,
		"current_vertex_id": _current_vertex_id,
		"target_vertex_id": _target_vertex_id,
		"current_edge_id": _current_edge_id,
		"direction": _direction,
		"action_index": _action_index,
		"action_wait_remaining": _action_wait_remaining,
		"pre_delay_remaining": _pre_delay_remaining,
		"edge_travel_remaining": _edge_travel_remaining,
		"edge_travel_total": _edge_travel_total,
		"pending_branch_edge_id": _pending_branch_edge_id,
		"current_time": _current_time,
		"edge_history": _edge_history.duplicate(true),
		"facing_direction": _facing_direction,
		"turn_from_direction": _turn_from_direction,
		"turn_to_direction": _turn_to_direction,
		"turn_duration": _turn_duration,
		"turn_elapsed": _turn_elapsed,
	}


# --- forward simulation ------------------------------------------------

func _advance_forward(delta: float) -> void:
	if _current_time < _frontier_time:
		_truncate_to_current_time()

	var remaining := delta
	while remaining > 0.0 and _state != _State.FINISHED and _state != _State.BLOCKED_EXTERNAL:
		var before_step := remaining
		match _state:
			_State.PRE_DELAY:
				remaining = _step_pre_delay(remaining)
			_State.DWELLING:
				remaining = _step_dwelling(remaining)
			_State.MOVING:
				remaining = _step_moving(remaining)
			_:
				break
		_step_turn(before_step - remaining)

	_frontier_time = max(_frontier_time, _current_time)


## Drops any recorded keyframes/edge history beyond where we currently are,
## and snaps the simulation state to match -- re-entering DWELLING at
## action 0 for whatever vertex we're at, even if we'd previously been
## mid-action-list there. Resuming exact mid-action state isn't worth the
## added complexity; a vertex's actions simply restart fresh whenever
## forward simulation resumes past a rewind.
func _truncate_to_current_time() -> void:
	while _keyframes.size() > 1 and _keyframes[-1]["time"] > _current_time:
		_keyframes.pop_back()
	while not _edge_history.is_empty() and _edge_history[-1]["time"] > _current_time:
		_edge_history.pop_back()

	var last: Dictionary = _keyframes[-1]
	_current_vertex_id = last["vertex_id"]
	_target_vertex_id = -1
	_state = _State.DWELLING
	_action_index = 0
	_action_wait_remaining = -1.0
	_edge_travel_remaining = 0.0
	_pending_branch_edge_id = -1
	_frontier_time = _current_time


func _step_pre_delay(remaining: float) -> float:
	var consumed := minf(remaining, _pre_delay_remaining)
	_current_time += consumed
	_pre_delay_remaining -= consumed
	if _pre_delay_remaining <= 0.0:
		_state = _State.DWELLING
	return remaining - consumed


func _step_dwelling(remaining: float) -> float:
	var vertex := path_data.get_vertex_by_id(_current_vertex_id)
	if vertex == null:
		_state = _State.FINISHED
		return remaining

	if _action_index >= vertex.actions.size():
		_begin_next_edge()
		return remaining

	var action: VertexAction = vertex.actions[_action_index]

	if _action_wait_remaining < 0.0:
		# Haven't executed this action yet this pass.
		if action == null or not action.enabled or not _direction_allows(action):
			_action_index += 1
			return remaining

		var block: float = action._execute(self)
		action_executed.emit(_current_vertex_id, action)

		if block == VertexAction.BLOCK_EXTERNAL:
			_state = _State.BLOCKED_EXTERNAL
			return remaining
		elif block <= 0.0:
			_action_index += 1
			return remaining
		else:
			_action_wait_remaining = block
			# fall through to consume time below

	var consumed := minf(remaining, _action_wait_remaining)
	_current_time += consumed
	_action_wait_remaining -= consumed
	if _action_wait_remaining <= 0.0:
		_action_index += 1
		_action_wait_remaining = -1.0
	return remaining - consumed


func _direction_allows(action: VertexAction) -> bool:
	match action.execution_direction:
		VertexAction.ExecutionDirection.FORWARD_ONLY:
			return _direction == 1
		VertexAction.ExecutionDirection.BACKWARD_ONLY:
			return _direction == -1
		_:
			return true


func _begin_next_edge() -> void:
	var edge: PathEdge = null

	if _direction == 1:
		edge = _pick_forward_edge(_current_vertex_id)
		if edge == null:
			_handle_forward_terminal()
			return
		_target_vertex_id = edge.to_vertex
	else:
		# PING_PONG backward retrace: always the exact edge actually taken
		# going forward, popped off the recorded history -- not a fresh
		# graph traversal via incoming edges, which could be ambiguous
		# wherever a branch happened.
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
	_edge_travel_remaining = edge_length / speed if speed > 0.0 else 0.0
	_edge_travel_total = max(_edge_travel_remaining, 0.0001)

	var new_direction := (to_vertex.position - from_vertex.position).normalized()
	if new_direction != Vector3.ZERO and not to_vertex.suppress_incoming_turn:
		# Non-blocking -- the returned duration is ignored on purpose here.
		# Movement proceeds for the edge's own full travel time regardless
		# of how long the (usually much shorter) turn takes; _step_turn()
		# just keeps interpolating in the background until it catches up.
		begin_turn(new_direction)

	edge_entered.emit(_current_edge_id)
	_state = _State.MOVING


func _pick_forward_edge(vertex_id: int) -> PathEdge:
	if _pending_branch_edge_id != -1:
		var chosen := path_data.get_edge_by_id(_pending_branch_edge_id)
		if chosen != null and chosen.from_vertex == vertex_id:
			return chosen
		push_warning("[PathFollower] BranchAction targeted edge %d, which isn't a valid outgoing edge of vertex %d -- falling back to the default edge." % [_pending_branch_edge_id, vertex_id])
	return _pick_default_edge(vertex_id)


## Default when nothing overrides it via BranchAction: the first-created
## outgoing edge (lowest id).
func _pick_default_edge(vertex_id: int) -> PathEdge:
	var outgoing := path_data.get_outgoing_edges(vertex_id)
	if outgoing.is_empty():
		return null
	var best: PathEdge = outgoing[0]
	for e in outgoing:
		if e.id < best.id:
			best = e
	return best


func _handle_forward_terminal() -> void:
	match path_data.path_type:
		PathData.PathType.LOOP:
			var root := path_data.get_start_vertex()
			if root == null:
				_state = _State.FINISHED
				path_finished.emit()
				return
			_current_vertex_id = root.id
			_edge_history.clear()
			_arrive_at_vertex()
		PathData.PathType.PING_PONG:
			# Flip and re-enter this SAME vertex's action list, filtered by
			# direction -- BOTH-direction actions deliberately fire again
			# as the NPC turns around, since this is a fresh real event,
			# not a rewind.
			_direction = -1
			_action_index = 0
			_action_wait_remaining = -1.0
			_pending_branch_edge_id = -1
			_state = _State.DWELLING
		_:  # ONE_SHOT
			_state = _State.FINISHED
			path_finished.emit()


func _handle_backward_terminal() -> void:
	_direction = 1
	_action_index = 0
	_action_wait_remaining = -1.0
	_pending_branch_edge_id = -1
	_state = _State.DWELLING


func _arrive_at_vertex() -> void:
	vertex_reached.emit(_current_vertex_id)
	_keyframes.append({"time": _current_time, "vertex_id": _current_vertex_id})
	_action_index = 0
	_action_wait_remaining = -1.0
	_pending_branch_edge_id = -1
	_state = _State.DWELLING


func _step_moving(remaining: float) -> float:
	var consumed := minf(remaining, _edge_travel_remaining)
	_current_time += consumed
	_edge_travel_remaining -= consumed
	if _edge_travel_remaining <= 0.0:
		if _direction == 1:
			_edge_history.append({"time": _current_time, "edge_id": _current_edge_id})
		_current_vertex_id = _target_vertex_id
		_arrive_at_vertex()
	return remaining - consumed


# --- rewind (pure lookup, never touches simulation state) ------------------

func _rewind(amount: float) -> void:
	_current_time = max(_current_time - amount, 0.0)


func _interpolate_from_keyframes(t: float) -> Vector3:
	if _keyframes.is_empty():
		return position

	if _seek_cache_index >= _keyframes.size():
		_seek_cache_index = _keyframes.size() - 1
	while _seek_cache_index > 0 and _keyframes[_seek_cache_index]["time"] > t:
		_seek_cache_index -= 1
	while _seek_cache_index < _keyframes.size() - 1 and _keyframes[_seek_cache_index + 1]["time"] <= t:
		_seek_cache_index += 1

	var a: Dictionary = _keyframes[_seek_cache_index]
	if _seek_cache_index >= _keyframes.size() - 1:
		var v := path_data.get_vertex_by_id(a["vertex_id"])
		return v.position if v != null else global_position

	var b: Dictionary = _keyframes[_seek_cache_index + 1]
	var va := path_data.get_vertex_by_id(a["vertex_id"])
	var vb := path_data.get_vertex_by_id(b["vertex_id"])
	if va == null or vb == null:
		return global_position
	if a["vertex_id"] == b["vertex_id"]:
		return va.position  # dwell segment -- no movement

	var span: float = b["time"] - a["time"]
	var frac: float = 0.0 if span <= 0.0 else clampf((t - a["time"]) / span, 0.0, 1.0)
	return va.position.lerp(vb.position, frac)


## Pure function of internal state -- never touches global_position, so it
## works correctly even when this PathFollower isn't inside any scene tree
## at all (used by the editor's off-tree scrub preview instance). Returns
## Vector3.ZERO if path_data is unset or something's gone wrong.
func get_computed_position() -> Vector3:
	if path_data == null:
		return Vector3.ZERO

	if _current_time < _frontier_time:
		return _interpolate_from_keyframes(_current_time)

	match _state:
		_State.MOVING:
			var from_vertex := path_data.get_vertex_by_id(_current_vertex_id)
			var to_vertex := path_data.get_vertex_by_id(_target_vertex_id)
			if from_vertex != null and to_vertex != null:
				var t: float = 1.0 - (_edge_travel_remaining / _edge_travel_total)
				return from_vertex.position.lerp(to_vertex.position, clampf(t, 0.0, 1.0))
			return Vector3.ZERO
		_:
			var vertex := path_data.get_vertex_by_id(_current_vertex_id)
			return vertex.position if vertex != null else Vector3.ZERO


## Applies get_computed_position() to the real global_position -- guarded by
## is_inside_tree() since global_position requires walking the parent
## chain, which isn't possible off-tree (the off-tree case is exactly what
## get_computed_position() exists for -- callers that don't need a real
## moving node, like the editor's scrub preview, should call that directly
## and skip this entirely).
func _update_transform() -> void:
	if is_inside_tree():
		global_position = get_computed_position()
		_apply_facing_rotation()


## look_at() assumes Godot's standard -Z-forward convention -- if your NPC
## mesh/root is authored facing a different axis, you'll likely want an
## extra offset rotation somewhere in your own node hierarchy rather than
## here, since that's asset-specific, not something this can generically
## account for.
func _apply_facing_rotation() -> void:
	if _facing_direction == Vector3.ZERO:
		return
	# look_at() needs a forward direction that isn't parallel to the up
	# vector, or its basis construction is undefined -- guard against a
	# (nearly) straight-up/down facing rather than risk that. Shouldn't
	# come up in practice given paths are authored on a roughly horizontal
	# plane, but cheap to guard regardless.
	if absf(_facing_direction.dot(Vector3.UP)) > 0.999:
		return
	look_at(global_position + _facing_direction, Vector3.UP)
