class_name Laser extends Node3D

@onready var laser_mesh : MeshInstance3D = $LaserCylinder
@onready var laser_sfx : AudioStreamPlayer = $AudioStreamPlayer
@export var laser_on: bool = false
@export var target: Node3D = null
var source: Node3D

# Called when the node enters the scene tree for the first time.
func _ready():
	source = get_parent_node_3d()
	if laser_on:
		start_laser()
	else:
		stop_laser()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if laser_on and target:
		update_beam(source.global_position,target.global_position)

func start_laser():
	laser_mesh.visible = true
	if laser_sfx.playing == false:
		laser_sfx.play()
	laser_on = true

func stop_laser():
	laser_mesh.visible = false
	laser_sfx.stop()
	laser_on = false

func set_target(new_target: Node3D):
	target = new_target

func update_beam(start_pos: Vector3, end_pos: Vector3):
	if start_pos.is_equal_approx(end_pos):
		visible = false
		return
	visible = true

	global_position = (start_pos + end_pos) / 2.0

	laser_mesh.look_at(end_pos)
	
	laser_mesh.rotate_object_local(Vector3.RIGHT, -PI / 2.0)

	var distance = start_pos.distance_to(end_pos)
	laser_mesh.scale.y = distance
	
	laser_mesh.scale.x = 1.0 
	laser_mesh.scale.z = 1.0
