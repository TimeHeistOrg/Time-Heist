@tool
class_name WaitAction extends VertexAction
## Pauses the follower at this vertex for a fixed duration.


func get_display_name() -> String:
	return "Wait (%.2fs)" % block_time


func _execute(follower: Object) -> float:
	return block_time
