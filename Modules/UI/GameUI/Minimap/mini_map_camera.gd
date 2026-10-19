extends Camera3D
class_name MinimapCamera

@export var target: Node3D
var offset

func _ready() -> void:
	if not target:
		push_error("No target found for minimap camera")
	else:
		global_position = Vector3(target.global_position.x,global_position.y,target.global_position.z)
		offset = global_position - target.global_position

func _process(_delta: float) -> void:
	if target:
		global_position = target.global_position + offset
