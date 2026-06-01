class_name FaceAction extends InstantAction

@export var rotation_deg: float

func progress(npc: PathFollower, from: float, to: float):
	npc.face(rotation_deg)
	return true
