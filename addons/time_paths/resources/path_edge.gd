@tool
class_name PathEdge extends Resource
## Class that represents a single edge of the path.

## Unique ID of this edge.
@export var id: int = -1
## Vertex that the edge is coming from.
@export var from_vertex: int = -1
## Vertex that the edge is going to.
@export var to_vertex: int = -1
## Whether this edge creates a loop.
@export var is_loop_edge: bool = false


func _validate_property(property: Dictionary) -> void:
	if property.name in ["id", "from_vertex", "to_vertex"]:
		property.usage |= PROPERTY_USAGE_READ_ONLY
