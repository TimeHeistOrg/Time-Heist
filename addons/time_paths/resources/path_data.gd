@tool
class_name PathData extends Resource
## A directed graph of vertices/edges defining an NPC path, plus path-wide
## playback properties. This is the saved asset the editor tool edits and
## PathFollower nodes consume at runtime.
##
## Vertices and edges are referenced by stable ids (see PathVertex.id,
## PathEdge.id), never by array index -- indices shift on delete/reorder,
## ids don't. Use the helper methods below rather than editing the arrays
## directly to keep ids consistent.

enum PathType { ONE_SHOT, LOOP, PING_PONG }

@export var vertices: Array[PathVertex] = []
@export var edges: Array[PathEdge] = []

@export var default_speed: float = 1
@export var path_type: PathType = PathType.ONE_SHOT

# start_delay intentionally NOT here -- it's per-instance follower behavior,
# not shared path data. Lives on the PathFollower node instead.


## vertices/edges are structural data meant to be edited only through the
## mutator methods below (which keep the lookup cache in sync) -- hidden
## entirely from any inspector (not just read-only) so a "path properties"
## panel showing default_speed/path_type doesn't get buried under two huge
## structural arrays, and so there's no temptation to hand-edit them raw.
func _validate_property(property: Dictionary) -> void:
	if property.name in ["vertices", "edges"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR


# --- caches (not exported, lazily rebuilt, NOT persisted) --------------------
#
# vertices/edges arrays remain the actual source of truth (exported, saved).
# These are pure lookup acceleration on top of them:
#   _vertex_by_id : id -> PathVertex
#   _edge_by_id   : id -> PathEdge
#   _outgoing_by_vertex : vertex_id -> Array[PathEdge]   (adjacency)
#
# IMPORTANT: this cache is only guaranteed correct if the arrays are mutated
# through add_vertex/remove_vertex/add_edge/remove_edge below. If you ever
# edit `vertices` or `edges` directly (including via the raw Inspector array
# UI), call invalidate_cache() afterward or lookups may return stale results.

var _vertex_by_id: Dictionary = {}
var _edge_by_id: Dictionary = {}
var _outgoing_by_vertex: Dictionary = {}
var _cache_valid: bool = false


func invalidate_cache() -> void:
	_cache_valid = false


func _ensure_cache() -> void:
	if _cache_valid:
		return
	_vertex_by_id.clear()
	_edge_by_id.clear()
	_outgoing_by_vertex.clear()
	for v in vertices:
		_vertex_by_id[v.id] = v
	for e in edges:
		_edge_by_id[e.id] = e
		if not _outgoing_by_vertex.has(e.from_vertex):
			_outgoing_by_vertex[e.from_vertex] = [] as Array[PathEdge]
		_outgoing_by_vertex[e.from_vertex].append(e)
	_cache_valid = true


# --- vertex lookup / mutation -------------------------------------------------

func get_vertex_by_id(vertex_id: int) -> PathVertex:
	_ensure_cache()
	return _vertex_by_id.get(vertex_id, null)


func add_vertex(position: Vector3) -> PathVertex:
	var v := PathVertex.new()
	v.id = _next_free_id(vertices.map(func(x): return x.id))
	v.position = position
	vertices.append(v)
	invalidate_cache()
	return v


## Used by undo/redo: re-inserts an ALREADY-EXISTING PathVertex object
## (never constructs a new one) -- critical for undo/redo of creation/
## deletion. If we reconstructed a fresh object here instead, any OTHER
## undo/redo entry that references this specific vertex (most commonly
## Godot's own automatic per-field inspector undo, e.g. "Set speed_override")
## would end up pointing at an orphaned instance the moment this one gets
## rebuilt -- the property would silently fail to reapply on redo. Once a
## vertex is removed from `vertices`, nothing else can mutate it (our own
## mutator methods only ever operate via get_vertex_by_id, which can't find
## it), so it's safe to just hold onto and reinsert the same instance.
func insert_vertex(vertex: PathVertex) -> void:
	vertices.append(vertex)
	invalidate_cache()


## Same reasoning as insert_vertex(), for edges.
func insert_edge(edge: PathEdge) -> void:
	edges.append(edge)
	invalidate_cache()


## Removes a vertex AND any edges that reference it (dangling edges left
## behind would silently break BranchAction lookups later, so we clean up
## eagerly rather than leaving that for the caller to remember).
func remove_vertex(vertex_id: int) -> void:
	vertices = vertices.filter(func(v): return v.id != vertex_id)
	edges = edges.filter(func(e): return e.from_vertex != vertex_id and e.to_vertex != vertex_id)
	invalidate_cache()


## Removes ONLY the vertex, no edge cascade -- for undo/redo registrations
## that already precisely track which edges to touch (repoint vs remove)
## themselves. Using the cascading remove_vertex() there would risk
## incorrectly sweeping up an edge that's only TEMPORARILY pointing at this
## vertex mid-undo (e.g. a repointed edge whose field hasn't been reverted
## yet), since which order same-action undo operations execute in isn't
## something to depend on.
func remove_vertex_only(vertex_id: int) -> void:
	vertices = vertices.filter(func(v): return v.id != vertex_id)
	invalidate_cache()


# --- edge lookup / mutation ---------------------------------------------------

func get_edge_by_id(edge_id: int) -> PathEdge:
	_ensure_cache()
	return _edge_by_id.get(edge_id, null)


func add_edge(from_vertex_id: int, to_vertex_id: int) -> PathEdge:
	assert(get_vertex_by_id(from_vertex_id) != null, "add_edge: from_vertex_id does not exist")
	assert(get_vertex_by_id(to_vertex_id) != null, "add_edge: to_vertex_id does not exist")
	var e := PathEdge.new()
	e.id = _next_free_id(edges.map(func(x): return x.id))
	e.from_vertex = from_vertex_id
	e.to_vertex = to_vertex_id
	edges.append(e)
	invalidate_cache()
	return e


func remove_edge(edge_id: int) -> void:
	edges = edges.filter(func(e): return e.id != edge_id)
	invalidate_cache()


## Repoints an existing edge's origin, preserving its id/identity (used when
## a fork gets pushed down onto a newly-inserted vertex -- the child edges
## keep being "the same edge", just originating somewhere else now).
func set_edge_from_vertex(edge_id: int, new_from_vertex_id: int) -> void:
	var e := get_edge_by_id(edge_id)
	if e == null:
		return
	e.from_vertex = new_from_vertex_id
	invalidate_cache()


## Repoints an existing edge's destination, preserving its id/identity (used
## when inserting a vertex into an existing A->C edge to get A->B->C).
func set_edge_to_vertex(edge_id: int, new_to_vertex_id: int) -> void:
	var e := get_edge_by_id(edge_id)
	if e == null:
		return
	e.to_vertex = new_to_vertex_id
	invalidate_cache()


func get_outgoing_edges(vertex_id: int) -> Array[PathEdge]:
	_ensure_cache()
	return _outgoing_by_vertex.get(vertex_id, [] as Array[PathEdge])


func get_incoming_edges(vertex_id: int) -> Array[PathEdge]:
	# Not cached separately -- incoming lookups are expected to be rare
	# (mainly editor-side, e.g. "can I delete this vertex safely") compared
	# to outgoing lookups, which happen on every branch decision at runtime.
	var result: Array[PathEdge] = []
	for e in edges:
		if e.to_vertex == vertex_id:
			result.append(e)
	return result


## Computes when a follower would ARRIVE at and DEPART from this vertex,
## for display in the editor (not used by PathFollower itself). Since every
## vertex except a loop-merge target has EXACTLY ONE non-loop incoming
## edge, the path from root to any given vertex is uniquely determined --
## this walks backward from vertex_id to the root via that single edge
## each time, rather than needing to simulate forward through the whole
## graph picking branches.
##
## Matches the same assumptions as the editor's scrub preview, for the same
## reasons:
##   - the DEFAULT (first-created) edge is assumed at every fork -- there's
##     no live game state here to evaluate a real BranchAction condition
##     against.
##   - only WaitAction durations count toward dwell time -- other action
##     types don't have deterministic timing without real execution.
##   - loop edges are never part of the path TO a vertex (only structural
##     edges are walked).
##   - start_delay is NOT included -- that's a per-follower-INSTANCE
##     property, not part of the path itself, matching how
##     PathFollower.get_elapsed_time() also only starts counting once
##     start_delay has already elapsed.
##
## Returns {"reachable": bool, "arrival": float, "departure": float}.
## "reachable" is only false if the graph is malformed (a cycle in the
## non-loop incoming-edge chain) -- shouldn't be possible given the
## invariants the editor tool enforces, but this guards against looping
## forever on a corrupted resource rather than assuming it can't happen.
func compute_vertex_timing(vertex_id: int) -> Dictionary:
	var chain: Array[int] = []
	var visited: Dictionary = {}
	var current_id := vertex_id

	while true:
		if visited.has(current_id):
			return {"reachable": false, "arrival": 0.0, "departure": 0.0}
		visited[current_id] = true
		chain.append(current_id)

		var incoming := get_incoming_edges(current_id).filter(func(e): return not e.is_loop_edge)
		if incoming.is_empty():
			break  # reached the root
		current_id = incoming[0].from_vertex

	chain.reverse()  # was target -> root, now root -> ... -> target

	var time := 0.0
	var arrival := 0.0
	for i in chain.size():
		var vertex := get_vertex_by_id(chain[i])
		if vertex == null:
			return {"reachable": false, "arrival": 0.0, "departure": 0.0}

		if i > 0:
			var prev_vertex := get_vertex_by_id(chain[i - 1])
			var edge_length := prev_vertex.position.distance_to(vertex.position)
			var speed := vertex.get_effective_speed(default_speed)
			time += edge_length / speed if speed > 0.0 else 0.0

		arrival = time

		for action in vertex.actions:
			if action == null or not action.enabled:
				continue
			if action.execution_direction == VertexAction.ExecutionDirection.BACKWARD_ONLY:
				continue
			if action is WaitAction:
				time += action.duration

	return {"reachable": true, "arrival": arrival, "departure": time}


## Returns the graph's root -- the unique vertex with no *non-loop* incoming
## edges. Loop edges are explicitly exempt from this: a loop edge dragged
## back onto the root is meaningful (e.g. "return to start") and does not
## affect uniqueness, since only non-loop edges count toward the invariant
## that every other vertex has exactly one incoming (non-loop) edge.
##
## O(V*E) worst case (uncached) -- fine for editor-time use and expected
## small graphs; a runtime caller like a follower node should cache this
## once rather than call it every frame.
func get_start_vertex() -> PathVertex:
	for v in vertices:
		var non_loop_incoming := get_incoming_edges(v.id).filter(func(e): return not e.is_loop_edge)
		if non_loop_incoming.is_empty():
			return v
	return null


# --- internal ------------------------------------------------------------

func _next_free_id(existing_ids: Array) -> int:
	var max_id := -1
	for id in existing_ids:
		max_id = max(max_id, id)
	return max_id + 1
