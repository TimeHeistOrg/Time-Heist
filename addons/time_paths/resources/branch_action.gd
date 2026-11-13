@tool
class_name BranchAction extends VertexAction
## Action that represents a potential branch in the path.


## Expression string evaluated at runtime. Is evaluated on the follower that executes this action.
@export var condition: String = ""

## Id of the edge to be branched to if the condition is true.
@export var target_edge_id: int = -1

## Used by Time Paths preview scrubber to view what the path looks like with different branch conditions.
@export var preview_result: bool = false


func get_display_name() -> String:
	var cond_display := condition if condition != "" else "<no condition>"
	return "Branch if (%s) -> edge %d" % [cond_display, target_edge_id]


func _execute(follower: Object) -> float:
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
