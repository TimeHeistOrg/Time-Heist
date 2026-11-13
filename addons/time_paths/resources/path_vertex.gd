@tool
class_name PathVertex extends Resource
## Class that represents a single Vertex of the path.

## Unique ID for this vertex.
@export var id: int = -1
## Position of this vertex in the global space
@export var position: Vector3 = Vector3.ZERO
## List of actions to execute when dwelling at this vertex.
@export var actions: Array[VertexAction] = []
## Overrides the speed of the follower along the edge coming INTO this vertex.
@export var speed_override: float = -1.0
## If true, the follower does not turn to face this vertex when starting the edge INTO this vertex.
@export var suppress_incoming_turn: bool = false


## Get the speed the PathFollower should have coming into this vertex.
func get_effective_speed(default_speed: float) -> float:
	return speed_override if speed_override >= 0.0 else default_speed


func _validate_property(property: Dictionary) -> void:
	if property.name == "id":
		property.usage |= PROPERTY_USAGE_READ_ONLY
