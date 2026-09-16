@tool
class_name BranchAction extends VertexAction
## If [member condition] evaluates truthy, marks [member target_edge_id] as
## the edge the follower should take when it finishes this vertex's action
## list. Does NOT interrupt the list -- later actions (including other
## BranchActions) still run in order. If multiple BranchActions in the same
## list evaluate true, the LAST one wins (each call to take_branch() simply
## overwrites the previous choice) -- so order them deliberately, most
## general condition first. If none evaluate true, the follower falls back
## to its default edge (the first-created outgoing edge).
##
## target_edge_id renders as a dropdown of the vertex's actual outgoing
## edges in the editor (see BranchActionInspectorPlugin) -- still a plain
## int underneath.

## Expression string evaluated at runtime by the follower/game code.
## Left as a loose string intentionally: the plugin does not validate or
## understand game state, only the game's condition evaluator does.
@export var condition: String = ""

## Id of the PathEdge (see PathEdge.id) to take if the condition is true.
## NOTE: if the referenced edge no longer exists at runtime, this should be
## treated as an error condition requiring user attention, not a silent
## fallback -- the follower is expected to surface that loudly.
@export var target_edge_id: int = -1

## Used ONLY during editor scrub-sync preview (PathFollower.is_editor_preview),
## instead of evaluating the real condition -- there's no live game state to
## evaluate a real expression against during editing. Lets you manually flag
## "pretend this is true" (or false) per BranchAction so you can visually
## check what each branch actually looks like without needing real
## conditions wired up yet.
@export var preview_result: bool = false


func get_display_name() -> String:
	var cond_display := condition if condition != "" else "<no condition>"
	return "Branch if (%s) -> edge %d" % [cond_display, target_edge_id]


func _execute(follower: Object) -> float:
	# Editor scrub preview takes priority over everything below, even an
	# unconfigured/empty condition -- lets you preview a hypothetical
	# branch before you've written the real condition for it.
	if follower.get("is_editor_preview") == true:
		if preview_result and follower.has_method("take_branch"):
			follower.call("take_branch", target_edge_id)
		return 0.0

	if condition == "":
		return 0.0

	var expr := Expression.new()
	var parse_err := expr.parse(condition)
	if parse_err != OK:
		push_error("BranchAction: failed to parse condition '%s': %s" % [condition, expr.get_error_text()])
		return 0.0

	var result: Variant = expr.execute([], follower)
	if expr.has_execute_failed():
		push_error("BranchAction: condition '%s' failed to evaluate: %s" % [condition, expr.get_error_text()])
		return 0.0

	if bool(result) and follower.has_method("take_branch"):
		follower.call("take_branch", target_edge_id)

	return 0.0
