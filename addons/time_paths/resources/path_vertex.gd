@tool
class_name PathVertex extends Resource

## Stable identifier, unique within a PathData. Referenced by PathEdge
## (from_vertex/to_vertex) so edges survive vertex array reordering/deletion
## without silently pointing at the wrong vertex.
@export var id: int = -1

@export var position: Vector3 = Vector3.ZERO

## Ordered list of actions executed when a follower reaches this vertex.
## Order matters -- this is the whole point of the design (e.g. "interact,
## then wait, then maybe branch").
@export var actions: Array[VertexAction] = []

## Speed to use on the edge LEADING INTO this vertex (i.e. the edge whose
## destination this vertex is), NOT edges leaving it. -1 means "use
## PathData.default_speed". Placed on the destination rather than the
## source specifically so a FORK (a vertex with multiple outgoing edges --
## much more common than multiple incoming, given the graph's invariants)
## can give each of its children a distinct speed for their own approach,
## rather than one shared speed applying uniformly to every branch out of
## the fork.
@export var speed_override: float = -1.0

## When true, the follower does NOT turn to face this vertex's direction as
## it departs the PREVIOUS vertex on the edge leading here -- facing just
## stays whatever it already was. Checked at the moment that edge begins
## (see PathFollower._begin_next_edge()), based on the DESTINATION vertex
## rather than the source -- same placement as speed_override, for the
## same reason.
@export var suppress_incoming_turn: bool = false


func get_effective_speed(default_speed: float) -> float:
	return speed_override if speed_override >= 0.0 else default_speed


## id is structural -- edges reference vertices by it, so hand-editing it in
## an inspector would silently break every edge pointing here. Read-only in
## ANY inspector view of a PathVertex, not just our own custom one.
func _validate_property(property: Dictionary) -> void:
	if property.name == "id":
		property.usage |= PROPERTY_USAGE_READ_ONLY
