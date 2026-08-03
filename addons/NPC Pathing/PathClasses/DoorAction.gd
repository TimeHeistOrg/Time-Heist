class_name DoorAction extends InstantAction

@export_node_path("Door") var door: NodePath
@export var action: door_action

enum door_action {open, close, lock, unlock, unlock_and_open, close_and_lock}

func progress(npc: PathFollower, from: float, to: float):
	var door_node: Door = npc.get_node(door)
	match action:
		door_action.open:
			door_node.open()
		door_action.close:
			door_node.close()
		door_action.lock:
			door_node.lock()
		door_action.unlock:
			door_node.unlock()
		door_action.unlock_and_open:
			door_node.unlock()
			door_node.open()
		door_action.close_and_lock:
			door_node.close()
			door_node.unlock()
