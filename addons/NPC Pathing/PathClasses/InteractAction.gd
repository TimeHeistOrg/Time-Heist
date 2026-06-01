@tool
class_name InteractAction extends InstantAction

@export_node_path var interactable: NodePath

func progress(npc: PathFollower, from: float, to: float):
	npc.interact_with(interactable)
	return true
