class_name BranchAction extends InstantAction

@export_node_path() var object: NodePath
@export var property_name: String = ""
@export var is_false: bool = false
@export var dest_path_id: int

func progress(npc: PathFollower, from: float, to: float):
	var branched = npc.branch_if(self)
	if branched:
		return false
	return true
