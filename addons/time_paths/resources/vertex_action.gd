@tool
class_name VertexAction extends Resource
## Base class for actions that execute when an NPC reaches a path vertex.
##
## Extend this to create new action types (e.g. PlaySoundAction, SetAnimationAction)
## without modifying the plugin itself. The editor's action-list UI treats any
## Resource of this type generically, so custom subclasses show up automatically.

## Whether this action runs at all. Lets users disable an action without deleting it.
@export var enabled: bool = true

## Governs whether this action executes during a PING_PONG follower's
## backward retrace through the graph -- independent of rewind/fast-forward
## (which is game-time direction, a completely separate axis from which way
## the NPC is currently walking the path).
##
## Defaults to FORWARD_ONLY: at a ping-pong turnaround vertex, the action
## list genuinely runs a second time as the follower flips direction and
## departs the way it came (see PathFollower._handle_forward_terminal /
## _handle_backward_terminal) -- FORWARD_ONLY keeps that second pass a
## no-op by default, so double-firing on turnaround is opt-in per action
## (set to BACKWARD_ONLY or BOTH) rather than automatic.
enum ExecutionDirection { FORWARD_ONLY, BACKWARD_ONLY, BOTH }
@export var execution_direction: ExecutionDirection = ExecutionDirection.FORWARD_ONLY

## Sentinel return value from _execute(): block until something external
## calls follower.resume(), rather than a fixed duration.
const BLOCK_EXTERNAL := -1.0


## Override to provide a short label used in the vertex action-list UI.
## Defaults to the class name if not overridden.
func get_display_name() -> String:
	return get_script().get_global_name() if get_script() else "VertexAction"


## Called by PathFollower when it genuinely reaches this vertex during real
## forward simulation (delta > 0) -- never during a rewind lookup, which is
## pure position interpolation with no action execution at all.
##
## Return value controls how the follower proceeds:
##   0.0            -- instant, continue to the next action immediately
##   > 0.0          -- block for this many seconds before continuing
##   BLOCK_EXTERNAL -- block until follower.resume() is called externally
##
## [param follower] is expected to expose whatever context actions need
## (take_branch(), resume(), etc). Left untyped here so the follower's API
## can evolve without forcing changes to every action.
func _execute(follower: Object) -> float:
	push_warning("VertexAction._execute() not implemented for %s" % get_display_name())
	return 0.0
