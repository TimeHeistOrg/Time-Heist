extends WorldEnvironment

@export var camera: Camera3D
@export var parallax_strength: float = 0.003

var initial_camera_pos: Vector3

func _ready() -> void:
	initial_camera_pos = Vector3.ZERO

func _process(_delta: float) -> void:
	if not camera:
		return
	
	var offset = camera.global_position - initial_camera_pos
	
	# Rotate the sky based on camera movement
	var sky_rotation = Basis.from_euler(Vector3(
		offset.z * parallax_strength,
		0,
		-offset.x * parallax_strength
	))
	environment.sky_rotation = sky_rotation.get_euler()
