@tool
class_name ConeVision extends Area3D

var player_in_zone : bool
var player_spotted : bool
@onready var shader_mesh_gen := $VisionConeMeshGen
@onready var sight_checker := $SightChecker
@onready var collision := $CollisionPolygon3D
@onready var laser: MeshInstance3D = $Laser
@onready var laser_mesh: ImmediateMesh = laser.mesh

@onready var laser_node : MeshInstance3D = $LaserCylinder
@onready var laser_sfx : AudioStreamPlayer = $AudioStreamPlayer

@export var on_gaurd : bool = true
@export var use_overriden_vals : bool = false
var disabled : bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"disabled",disabled)
		disabled = value
		process_mode = Node.PROCESS_MODE_DISABLED if value else Node.PROCESS_MODE_INHERIT

var time_detecting: float = 0

@export var sight_line_angle : float = 130:
	set(value):
		sight_line_angle = value
		create_mesh()
@export var sight_line_radius : float = 15:
	set(value):
		sight_line_radius = value
		create_mesh()
@export var smaller_sight_line_angle : float = 30:
	set(value):
		smaller_sight_line_angle = value
		create_mesh()
@export var smaller_sight_line_radius : float = 1.5:
	set(value):
		smaller_sight_line_radius = value
		create_mesh()
@export var time_till_caught : float = 2
@export var angle_steps : float = 5:
	set(value):
		angle_steps = value
		create_mesh()

@export var catch_active = true
signal caught

var polygon_points : PackedVector2Array = []

var laser_on: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		if not use_overriden_vals:
			sight_line_angle = globals.gaurd_sight_line_angle if on_gaurd else globals.person_sight_line_angle
			sight_line_radius = globals.gaurd_sight_line_radius if on_gaurd else globals.person_sight_line_radius
			smaller_sight_line_radius = globals.gaurd_smaller_sight_line_radius if on_gaurd else globals.person_smaller_sight_line_radius
		if catch_active:
			caught.connect(globals.player_caught)
		globals.safe_ratio = 1
		sight_checker.target_position.z = -sight_line_radius
		create_mesh()
		collision.polygon = polygon_points
		laser_node.visible = false

func create_mesh():
	polygon_points = []
	var start_angle = -(sight_line_angle/2)
	var end_angle = sight_line_angle/2
	
	var current_angle = start_angle
	while current_angle <= end_angle:
		var rad = deg_to_rad(current_angle)
		polygon_points.append(Vector2(
			sight_line_radius * sin(rad),
			-sight_line_radius * cos(rad)
		))
		current_angle += angle_steps
	
	if smaller_sight_line_radius == 0:
		polygon_points.append(Vector2.ZERO)
	else:
		var rest_of_angle = 360 - sight_line_angle
		var back_cutout = rest_of_angle - (smaller_sight_line_angle * 2)
		#BACK SIGHT PART 1
		end_angle = end_angle+smaller_sight_line_angle
		while current_angle <= end_angle:
			var rad = deg_to_rad(current_angle)
			polygon_points.append(Vector2(
				smaller_sight_line_radius * sin(rad),
				-smaller_sight_line_radius * cos(rad)
			))
			current_angle += angle_steps
		polygon_points.append(Vector2.ZERO)
		#BACK SIGHT PART 2
		end_angle = start_angle+360 #finish the loop around
		current_angle += back_cutout
		while current_angle <= end_angle:
			var rad = deg_to_rad(current_angle)
			polygon_points.append(Vector2(
				smaller_sight_line_radius * sin(rad),
				-smaller_sight_line_radius * cos(rad)
			))
			current_angle += angle_steps
		
		
	#current_angle = end_angle 
	#while current_angle >= start_angle:
		#var rad = deg_to_rad(current_angle)
		#polygon_points.append(Vector2(
			#-smaller_sight_line_radius * sin(rad),
			#smaller_sight_line_radius * cos(rad)
		#))
		#current_angle -= angle_steps

	if collision:
		collision.polygon = polygon_points
	
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if player_in_zone and not globals.player.is_hidden and globals.player.can_be_seen and not globals.time_manager.is_time_traveling:
			#sight_checker.look_at(Vector3(globals.player.global_position.x, 1, globals.player.global_position.z))
			sight_checker.look_at(globals.player.detection_point.global_position)
			
			if sight_checker.get_collider() == globals.player:
				player_spotted = true
			else:
				player_spotted = false
				if catch_active and laser_on:
					stop_laser()
		
		if not globals.time_manager.is_time_traveling:
			if player_spotted and globals.player.can_be_seen:
				time_detecting = min(time_detecting + globals.time_manager.delta_time,time_till_caught)
				if catch_active and not laser_on:
					start_laser()
			else:
				time_detecting = max(time_detecting - globals.time_manager.delta_time, 0.0)
				if catch_active and laser_on:
					stop_laser()
		else:
			time_detecting = max(time_detecting + globals.time_manager.delta_time, 0.0)
			if catch_active and laser_on:
				stop_laser()
		
		if laser_on:
			draw_laser()
		
		globals.safe_ratio = min(globals.safe_ratio, (time_till_caught - time_detecting) / time_till_caught)
		if catch_active and time_detecting >= time_till_caught:
			caught.emit()

func _on_body_entered(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = true
		
func _on_body_exited(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = false 
		player_spotted = false
		#time_detecting = 0
		#globals.safe_ratio = (time_till_caught - time_detecting) / time_till_caught
		laser_mesh.clear_surfaces()
		laser_node.visible = false

func draw_laser():
	laser_mesh.clear_surfaces()
	laser_node.update_beam(sight_checker.global_position, globals.player.global_position + Vector3(0, 1.0, 0))

func start_laser():
	laser_node.visible = true
	if laser_sfx.playing == false:
		laser_sfx.play()
	laser_on = true

func stop_laser():
	laser_mesh.clear_surfaces()
	laser_node.visible = false
	laser_sfx.stop()
	laser_on = false

func _on_npc_hitbox_body_entered(body: Node3D) -> void:
	if body == globals.player and globals.player.can_be_seen:
		caught.emit()
