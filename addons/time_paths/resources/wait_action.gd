@tool
class_name WaitAction extends VertexAction
## Pauses the follower at this vertex for a fixed duration.

@export var duration: float = 1.0


func get_display_name() -> String:
	return "Wait (%.2fs)" % duration


func _execute(follower: Object) -> float:
	return duration
