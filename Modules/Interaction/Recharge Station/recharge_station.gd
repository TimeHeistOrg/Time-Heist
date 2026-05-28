extends Node3D
class_name RechargeStation

var in_zone : bool = false
var charging : bool = false:
	set(value):
		print("set charing to ", value)
		if not value:
			wire_mesh.clear_surfaces()
		charging = value
var old_speed : float
@export var speed_in_zone : float = 1.0

@onready var charge_area: Area3D = $"Charge Area"
@onready var wire: MeshInstance3D = $Wire
@onready var wire_mesh: Mesh = wire.mesh
@onready var player = globals.player

func _process(delta: float) -> void:
	if in_zone:
		#print(in_zone)
		#player.current_max_speed = speed_in_zone
		if charging:
			wire_mesh.clear_surfaces()
			draw_line()
			globals.time_manager.time_juice = minf(globals.time_manager.max_time_juice, globals.time_manager.time_juice + globals.time_manager.rewind_charge_per_sec * delta)
	pass
	
func interact():
	if not in_zone:
		return
	if charging: 
		charging = false
	else:
		charging = true
	
func draw_line():
	var start_point = Vector3.ZERO  # local origin of the laser node
	var end_point = to_local(globals.player.global_position) + Vector3(0, 0.5, 0) # if you want y=1 offset
	# Begin drawing the line
	wire_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	wire_mesh.surface_set_color(Color(0.0, 0.458, 0.751, 1.0))
	# Add the vertices
	wire_mesh.surface_add_vertex(start_point)
	wire_mesh.surface_add_vertex(end_point)
	# Finish drawing
	wire_mesh.surface_end()


func _on_charge_area_body_entered(body: Node3D) -> void:
	if body == globals.player:
		print("entering zone")
		#old_speed = player.current_max_speed
		#player.current_max_speed = speed_in_zone
		in_zone = true
	
	
func _on_charge_area_body_exited(body: Node3D) -> void:
	if body == globals.player:
		print("exiting zone")
		#player.current_max_speed = old_speed
		in_zone = false
		wire_mesh.clear_surfaces()
		charging = false
