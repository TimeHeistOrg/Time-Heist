class_name SecurityGuard extends Path3D

@onready var follower: PathFollow3D = $PathFollow3D
@export var speed: float = 1

func _process(_delta):
	follower.progress = globals.time_manager.cur_time * speed
