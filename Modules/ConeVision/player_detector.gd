@tool
class_name PlayerDetector extends Area3D
## PlayerDectector class
##
## Detects player in a mesh and tests for line of sight. Used in [Guard]. This is a tool
## so you can edit the mesh live in engine

## Emits when the player is seen by the detector
signal player_seen(position : Vector3)

## Emits when the player is stopped being seen by the detector
signal player_stopped_seen(last_position : Vector3)

## Flag if player is in the zone
var player_in_zone : bool
## Flag if player is in the zone and line of sight
var player_spotted : bool:
	set(value):
		if player_spotted == value:
			return
		elif value:
			player_seen.emit(seen_position)
		else:
			player_stopped_seen.emit(last_seen_position)
		player_spotted = value
		_update_vision_color()

## The position the player is being spotted
var seen_position : Vector3
## Last seen position of the player
var last_seen_position : Vector3

@onready var sight_checker := $SightChecker
@onready var collision := $DetectorCollision
@onready var vision_mesh: MeshInstance3D = $VisionMesh

## Colors for the vision-cone overlay shown to the player (topdown decal).
## Brightens/reddens while the player is actually spotted.
@export var vision_color: Color = Color(1, 1, 1, 0.12)
@export var vision_alert_color: Color = Color(1, 0.15, 0.15, 0.35)
## How far above the ground the decal sits, to avoid z-fighting with the floor
@export var vision_mesh_height: float = -0.02

var vision_material: StandardMaterial3D

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


## Creates the mesh based on export values
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
	_update_vision_mesh()


## Rebuilds the flat, ground-projected vision-cone mesh shown to the player
## from the same polygon_points used for the collision shape (see create_mesh).
func _update_vision_mesh() -> void:
	if not vision_mesh or polygon_points.size() < 3:
		return

	if not vision_material:
		vision_material = StandardMaterial3D.new()
		vision_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		vision_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		vision_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		vision_mesh.material_override = vision_material
	_update_vision_color()

	var indices := Geometry2D.triangulate_polygon(polygon_points)
	if indices.is_empty():
		return

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for p in polygon_points:
		verts.append(Vector3(p.x, p.y, vision_mesh_height))
		normals.append(Vector3(0, 0, 1))

	var mesh_arrays := []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = verts
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	vision_mesh.mesh = array_mesh


func _update_vision_color() -> void:
	if vision_material:
		vision_material.albedo_color = vision_alert_color if player_spotted else vision_color
	
func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		if player_in_zone and not globals.player.is_hidden and not globals.player_invisible and globals.time_manager.delta_time > 0:
			sight_checker.look_at(globals.player.detection_point.global_position)
			if sight_checker.get_collider() == globals.player:
				_seen_process(_delta)
				player_spotted = true
			else:
				last_seen_position = seen_position
				player_spotted = false
				
func _seen_process(_delta: float) -> void:
	seen_position = globals.player.detection_point.global_position

func _on_body_entered(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = true
		
func _on_body_exited(body: Node3D) -> void:
	if body == globals.player:
		player_in_zone = false
	if player_spotted:
		last_seen_position = seen_position 
		player_spotted = false
