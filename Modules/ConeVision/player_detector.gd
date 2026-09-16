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
## The one collision shape, reused for whichever profile is active
@onready var collision := $DetectorCollision
@onready var vision_mesh: MeshInstance3D = $VisionMesh

## Colors for the vision cone overlay shown to the player (topdown decal).
## Brightens/reddens while the player is actually spotted.
@export var vision_color: Color = Color(1, 1, 1, 0.12)
@export var vision_alert_color: Color = Color(1, 0.15, 0.15, 0.35)
## How far above the ground the decal sits, to avoid z-fighting with the floor
@export var vision_mesh_height: float = -0.02
## How long the shown cone takes to ease into a new profile. Collision and
## the raycast length switch instantly -- only the visual eases.
@export var vision_lerp_time: float = 0.12

var vision_material: StandardMaterial3D

## Params (angle, radius, smaller_angle, smaller_radius) the shown mesh is
## easing from/to, and how far along that ease we are (1.0 = done)
var vision_from: Vector4 = Vector4.ZERO
var vision_to: Vector4 = Vector4.ZERO
var vision_progress: float = 1.0

## Vision cone profiles a guard can switch this detector between
enum VisionProfile {NORMAL, TIGHT, WIDE}
## Which profile is currently active
var current_profile: VisionProfile = VisionProfile.NORMAL

@export_category("Normal Vision Cone")
## Angle of the vision cone
@export var normal_sight_line_angle : float = 110:
	set(value):
		normal_sight_line_angle = value
		if current_profile == VisionProfile.NORMAL:
			_apply_active_profile_change()
## Radius of the vision cone
@export var normal_sight_line_radius : float = 8:
	set(value):
		normal_sight_line_radius = value
		if current_profile == VisionProfile.NORMAL:
			_apply_active_profile_change()
## Angle of small vision cone
@export var normal_smaller_sight_line_angle : float = 70:
	set(value):
		normal_smaller_sight_line_angle = value
		if current_profile == VisionProfile.NORMAL:
			_apply_active_profile_change()
## Radius of small vision cone
@export var normal_smaller_sight_line_radius : float = 1.5:
	set(value):
		normal_smaller_sight_line_radius = value
		if current_profile == VisionProfile.NORMAL:
			_apply_active_profile_change()
@export_category("Tight Vision Cone (Search)")
## Angle of the vision cone
@export var tight_sight_line_angle : float = 30:
	set(value):
		tight_sight_line_angle = value
		if current_profile == VisionProfile.TIGHT:
			_apply_active_profile_change()
## Radius of the vision cone
@export var tight_sight_line_radius : float = 8:
	set(value):
		tight_sight_line_radius = value
		if current_profile == VisionProfile.TIGHT:
			_apply_active_profile_change()
## Angle of small vision cone
@export var tight_smaller_sight_line_angle : float = 110:
	set(value):
		tight_smaller_sight_line_angle = value
		if current_profile == VisionProfile.TIGHT:
			_apply_active_profile_change()
## Radius of small vision cone
@export var tight_smaller_sight_line_radius : float = 1.5:
	set(value):
		tight_smaller_sight_line_radius = value
		if current_profile == VisionProfile.TIGHT:
			_apply_active_profile_change()
@export_category("Wide Vision Cone (Alert)")
## Angle of the vision cone
@export var wide_sight_line_angle : float = 200:
	set(value):
		wide_sight_line_angle = value
		if current_profile == VisionProfile.WIDE:
			_apply_active_profile_change()
## Radius of the vision cone
@export var wide_sight_line_radius : float = 10:
	set(value):
		wide_sight_line_radius = value
		if current_profile == VisionProfile.WIDE:
			_apply_active_profile_change()
## Angle of small vision cone
@export var wide_smaller_sight_line_angle : float = 25:
	set(value):
		wide_smaller_sight_line_angle = value
		if current_profile == VisionProfile.WIDE:
			_apply_active_profile_change()
## Radius of small vision cone
@export var wide_smaller_sight_line_radius : float = 1.5:
	set(value):
		wide_smaller_sight_line_radius = value
		if current_profile == VisionProfile.WIDE:
			_apply_active_profile_change()
@export_category("Misc")
@export var angle_steps : float = 5:
	set(value):
		angle_steps = value
		_apply_active_profile_change()

@export_tool_button("View Normal Mesh")
var view_normal_mesh_button = set_profile.bind(VisionProfile.NORMAL)

@export_tool_button("View Tight Mesh")
var view_tight_mesh_button = set_profile.bind(VisionProfile.TIGHT)

@export_tool_button("View Wide Mesh")
var view_wide_mesh_button = set_profile.bind(VisionProfile.WIDE)


func _ready() -> void:
	if not Engine.is_editor_hint():
		globals.safe_ratio = 1
	_rebuild_active_mesh()
	_snap_vision(_profile_params(current_profile))


## Switches which vision cone profile is active
func set_profile(profile: VisionProfile) -> void:
	current_profile = profile
	_rebuild_active_mesh()
	_start_vision_lerp(_profile_params(current_profile))


## Angle, radius, smaller_angle, smaller_radius for the given profile
func _profile_params(profile: VisionProfile) -> Vector4:
	match profile:
		VisionProfile.NORMAL:
			return Vector4(normal_sight_line_angle, normal_sight_line_radius, normal_smaller_sight_line_angle, normal_smaller_sight_line_radius)
		VisionProfile.TIGHT:
			return Vector4(tight_sight_line_angle, tight_sight_line_radius, tight_smaller_sight_line_angle, tight_smaller_sight_line_radius)
		VisionProfile.WIDE:
			return Vector4(wide_sight_line_angle, wide_sight_line_radius, wide_smaller_sight_line_angle, wide_smaller_sight_line_radius)
	return Vector4.ZERO


## Live tuning of the active profile. Used in engine and snaps vision cone instead of lerping it
func _apply_active_profile_change() -> void:
	_rebuild_active_mesh()
	_snap_vision(_profile_params(current_profile))

#region Detector Collision Building

## Rebuilds the collision polygon and raycast length
func _rebuild_active_mesh() -> void:
	# Check in case this runs in engine
	if not sight_checker or not collision:
		return
	var params := _profile_params(current_profile)
	create_mesh(params.x, params.y, params.z, params.w)
	# Raycast needs to reach as far as the radius
	sight_checker.target_position.z = -params.y


## Sets the collision polygon from the given cone parameters (instant, no lerp)
func create_mesh(sight_line_angle : float, sight_line_radius : float, smaller_sight_line_angle : float, smaller_sight_line_radius : float) -> void:
	if collision:
		collision.polygon = _generate_cone_points(sight_line_angle, sight_line_radius, smaller_sight_line_angle, smaller_sight_line_radius)

#endregion

## Builds cone polygon points for the given parameters. Used by both vision mesh and detector collision
func _generate_cone_points(sight_line_angle : float, sight_line_radius : float, smaller_sight_line_angle : float, smaller_sight_line_radius : float) -> PackedVector2Array:
	var polygon_points : PackedVector2Array = []
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
	return polygon_points

#region Vision Mesh

## Rebuilds the vision mesh shown to the player
func _update_vision_mesh(polygon_points : PackedVector2Array) -> void:
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


## Update the vision mesh color if the player is seen
func _update_vision_color() -> void:
	if vision_material:
		vision_material.albedo_color = vision_alert_color if player_spotted else vision_color


## Shows params instantly, no ease
func _snap_vision(params: Vector4) -> void:
	vision_from = params
	vision_to = params
	vision_progress = 1.0
	_update_vision_mesh(_generate_cone_points(params.x, params.y, params.z, params.w))


## Starts easing the shown mesh toward target
## If already mid ease starts from wherever it currently is
func _start_vision_lerp(target: Vector4) -> void:
	if Engine.is_editor_hint(): # nothing advances the ease outside _process
		_snap_vision(target)
		return
	vision_from = vision_from.lerp(vision_to, vision_progress)
	vision_to = target
	vision_progress = 0.0


## Advances the shown mesh's ease toward vision_to, if one is in progress
func _advance_vision_lerp(delta: float) -> void:
	if vision_progress >= 1.0:
		return
	vision_progress = min(vision_progress + delta / vision_lerp_time, 1.0)
	var params := vision_from.lerp(vision_to, vision_progress)
	# Generate the updated mesh every frame
	_update_vision_mesh(_generate_cone_points(params.x, params.y, params.z, params.w))

#endregion

## If the player is in the cone, check if their is line of sight. Also advance the vision cone
func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_advance_vision_lerp(_delta)
	if _player_in_active_cone() and not globals.player.is_hidden and not globals.player_invisible and globals.time_manager.delta_time > 0:
		sight_checker.look_at(globals.player.detection_point.global_position)
		if sight_checker.get_collider() == globals.player:
			_seen_process(_delta)
			player_spotted = true
		else:
			_clear_spotted()
	else:
		# not in cone / hidden / invisible / time stopped -> can't be spotted
		_clear_spotted()


## True if the player's position is inside the currently active cone polygon
func _player_in_active_cone() -> bool:
	var local_pos = collision.to_local(globals.player.global_position)
	return Geometry2D.is_point_in_polygon(Vector2(local_pos.x, local_pos.y), collision.polygon)


func _seen_process(_delta: float) -> void:
	seen_position = globals.player.detection_point.global_position


## Marks the player as no longer spotted, recording where they were last seen
func _clear_spotted() -> void:
	if player_spotted:
		last_seen_position = seen_position
		player_spotted = false
