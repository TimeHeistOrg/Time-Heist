extends Tool
class_name CameraTool

var is_placed : bool = false
static var quantity : int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func use_tool():
	if not is_placed:
		if globals.player.sneak_detect.head_forward.is_colliding():
			#var camera_position = globals.player.sneak_detect.head_forward.get_collision_point()
			#var camera_direction = globals.player.sneak_detect.head_forward.get_collision_normal()
			#position = camera_position
			pass
			
	
func interact():
	if is_placed:
		is_placed = false
		quantity += 1
		
		
		
	
