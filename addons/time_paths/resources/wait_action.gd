@tool
class_name WaitAction extends VertexAction
## Pauses the follower at this vertex for a fixed duration.

## Duration to wait on this action for.
@export var duration: float = 1.0


func get_display_name() -> String:
	return "Wait (%.2fs)" % duration


func _execute(follower: Object) -> float:
	return duration
