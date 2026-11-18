@tool
@abstract
class_name VertexAction extends Resource
## Base class for actions that execute when an NPC reaches a path vertex.
##
## This can be extended to create custom vertex actions.

enum ExecutionDirection { FORWARD_ONLY, BACKWARD_ONLY, BOTH }

## If disabled this action will be skipped during execution.
@export var enabled: bool = true
## Used for PING-PONG paths. Specifies whether this action should be executed when moving forward on the path, backward on the path, or both.
@export var execution_direction: ExecutionDirection = ExecutionDirection.FORWARD_ONLY
## How long (if at all) to block/wait on this action
@export_range(0,100,0.001,"or_greater") var block_time: float = 0

## Get the display name for this vertex action. Returns class name if not overridden.
func get_display_name() -> String:
	return get_script().get_global_name() if get_script() else "VertexAction"


## Returns the block_time of this action
func get_block_time() -> float:
	return block_time


## Returns if the action blocks the path for some amount of time.
func blocks() -> bool:
	return block_time != 0

## Called by the PathFollower when it reaches this vertex action while dwelling on a PathVertex.
## Returns an amount of time to block (stop following the path) for.
@abstract func _execute(follower: PathFollower) -> float
