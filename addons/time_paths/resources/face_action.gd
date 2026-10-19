@tool
class_name FaceAction extends VertexAction
## Turns the follower to face a specific direction when this action
## executes -- independent of the automatic "turn toward the next edge"
## behavior that happens as the follower LEAVES a vertex (see
## PathFollower.rotation_speed_degrees), this lets you explicitly orient
## the follower at any point in a vertex's action list, e.g. to face a
## specific direction for a moment before continuing.
##
## Blocks like a WaitAction while turning -- but unlike WaitAction, the
## duration isn't something you set yourself: it's computed fresh each
## time from how far the follower actually needs to turn (the angle
## between its current facing and target_direction, divided by
## PathFollower.rotation_speed_degrees), so it's automatically fast for a
## small turn and slower for a big one, rather than an arbitrary fixed
## pause.
##
## target_direction is a raw (non-normalized-required, normalized
## internally) Vector3 rather than e.g. a yaw angle -- matches how
## PathFollower's own facing state is represented internally. Less
## convenient to hand-author precisely than a single angle would be; worth
## revisiting if that turns out to matter in practice.

@export var target_direction: Vector3 = Vector3.FORWARD


func get_display_name() -> String:
	return "Face (%.2f, %.2f, %.2f)" % [target_direction.x, target_direction.y, target_direction.z]


func _execute(follower: Object) -> float:
	if follower.has_method("begin_turn"):
		return follower.call("begin_turn", target_direction)
	return 0.0
