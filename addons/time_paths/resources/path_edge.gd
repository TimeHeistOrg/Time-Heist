@tool
class_name PathEdge extends Resource
## A single directed connection between two vertices in a PathData graph.
##
## Edges are strictly one-way. Speed lives on the destination vertex
## (PathVertex.speed_override), not here, so this stays deliberately dumb.

## Stable identifier, unique within a PathData. Referenced by BranchAction
## and does not shift if the edges array is reordered or edited.
@export var id: int = -1

## These reference PathVertex.id, NOT array index into PathData.vertices --
## indices shift on delete/reorder, ids don't.
@export var from_vertex: int = -1
@export var to_vertex: int = -1

## True for edges created via the loop/merge gesture (Ctrl+Alt drag onto an
## existing vertex) -- the only edges allowed to point at a vertex that
## already has another incoming edge. Every other edge in the graph implies
## normal tree/subtree structure (deleting a vertex cascades to what it
## points at); a loop edge is just a bare back-reference with no subtree of
## its own, so it should never cascade-delete anything -- it should just be
## dropped silently if either endpoint is removed.
@export var is_loop_edge: bool = false


## id, from_vertex, and to_vertex are all structural and only meant to be
## changed via PathData's mutator methods (which keep the lookup cache in
## sync) -- read-only in any inspector view of a PathEdge.
func _validate_property(property: Dictionary) -> void:
	if property.name in ["id", "from_vertex", "to_vertex"]:
		property.usage |= PROPERTY_USAGE_READ_ONLY
