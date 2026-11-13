@tool
class_name FaceAction extends VertexAction
## Turns the PathFollower to face the [parameter target_direction]

## Direction to turn the PathFollower to face.
@export var target_direction: Vector3 = Vector3.FORWARD


func get_display_name() -> String:
	return "Face (%.2f, %.2f, %.2f)" % [target_direction.x, target_direction.y, target_direction.z]


func _execute(follower: Object) -> float:
	if follower.has_method("begin_turn"):
		return follower.call("begin_turn", target_direction)
	return 0.0
