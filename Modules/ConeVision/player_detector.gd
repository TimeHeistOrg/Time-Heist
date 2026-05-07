@tool
class_name PlayerDetector extends Area3D

var player_in_zone : bool
var player_spotted : bool
@onready var sight_checker := $SightChecker
@onready var collision := $DetectorCollision

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

var polygon_points : PackedVector2Array = []


func _ready() -> void:
	if not Engine.is_editor_hint():
		globals.safe_ratio = 1
		sight_checker.target_position.z = -sight_line_radius
		create_mesh()
		collision.polygon = polygon_points

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
		if player_in_zone and not globals.player.is_hidden and not globals.player_invisible and not globals.time_manager.is_time_traveling:
			sight_checker.look_at(globals.player.detection_point.global_position)
			if sight_checker.get_collider() == globals.player:
				player_spotted = true
			else:
				player_spotted = false

func _on_body_entered(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = true
		
func _on_body_exited(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = false 
		player_spotted = false
