extends Floor

@export var cameras : Array[SubViewport]

func _ready() -> void:
	globals.cameras = cameras
	pass
