@tool
class_name InteractAction extends VertexAction

@export_node_path("Node3D") var interactable: NodePath:
	set(value):
		interactable = value
		if Engine.is_editor_hint():
			print(EditorInterface.get_current_path())
			interactable_root_node_name = get_local_scene().name

@export_storage var interactable_root_node_name: String

func _execute(follower: PathFollower) -> float:
	print(follower.find_parent(interactable_root_node_name).get_node(interactable))
	return 0
