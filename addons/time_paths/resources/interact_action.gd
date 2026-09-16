@tool
class_name InteractAction extends VertexAction
## Triggers a game-defined interaction by id. The plugin does not know what
## "interact_id" means semantically -- the game's own follower/NPC logic
## interprets it (e.g. play an animation, fire a signal, open a door).

@export var interact_id: String = ""

## Whether the follower should wait for the interaction to signal completion
## before continuing, or fire-and-forget.
@export var blocking: bool = true


func get_display_name() -> String:
	return "Interact (%s)" % (interact_id if interact_id != "" else "<unset>")


func _execute(follower: Object) -> float:
	# Editor scrub preview: never fire a real side effect, and never block
	# -- nothing will ever call resume() during a scrub, which would hang
	# the preview forever. See PathFollower.is_editor_preview.
	if follower.get("is_editor_preview") == true:
		return 0.0

	if follower.has_method("trigger_interaction"):
		follower.call("trigger_interaction", interact_id)
	return BLOCK_EXTERNAL if blocking else 0.0
