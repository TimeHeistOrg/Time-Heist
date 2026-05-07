extends Node3D

@export var collision_polygon: CollisionPolygon3D
@export var mesh_material: Material
@export var cone_depth: float = 0.1
var wall_mask: int = 4

var mesh_instance: MeshInstance3D
var space_state: PhysicsDirectSpaceState3D

func _ready() -> void:
	space_state = get_world_3d().direct_space_state
	mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "VisionMesh"
	if mesh_material:
		mesh_instance.material_override = mesh_material
	add_child(mesh_instance)

func _process(_delta: float) -> void:
	_update_mesh()

func _update_mesh() -> void:
	var original = collision_polygon.polygon
	var clipped = PackedVector2Array()
	clipped.append(Vector2(0, 0))  # Always keep tip at guard origin

	for point in original:
		var ray_origin = global_position
		var ray_target = global_position + global_basis * Vector3(point.x, 0, point.y)

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_target)
		query.collision_mask = wall_mask
		query.exclude = [get_parent().get_rid()]

		var result = space_state.intersect_ray(query)

		if result:
			# Wall hit — use the hit point instead of the full polygon point
			var hit_local = global_basis.inverse() * (result.position - global_position)
			clipped.append(Vector2(hit_local.x, hit_local.z))
		else:
			clipped.append(point)

	_build_mesh(clipped)

func _build_mesh(polygon: PackedVector2Array) -> void:
	if polygon.size() < 3:
		return

	var arr_mesh = ArrayMesh.new()
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)

	var verts = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var tip = Vector2(0, 0)
	var max_dist = 0.0
	for point in polygon:
		max_dist = max(max_dist, point.distance_to(tip))
	if max_dist == 0:
		return

	for point in polygon:
		var dist = point.distance_to(tip) / max_dist
		var angle = atan2(point.x - tip.x, point.y - tip.y)
		var u = (angle / PI) * 0.5 + 0.5
		verts.append(Vector3(point.x, cone_depth * 0.5, point.y))
		uvs.append(Vector2(u, dist))

	for point in polygon:
		var dist = point.distance_to(tip) / max_dist
		var angle = atan2(point.x - tip.x, point.y - tip.y)
		var u = (angle / PI) * 0.5 + 0.5
		verts.append(Vector3(point.x, -cone_depth * 0.5, point.y))
		uvs.append(Vector2(u, dist))

	var triangulated = Geometry2D.triangulate_polygon(polygon)
	if triangulated.is_empty():
		return

	for i in range(0, triangulated.size(), 3):
		indices.append(triangulated[i])
		indices.append(triangulated[i + 1])
		indices.append(triangulated[i + 2])

	var offset = polygon.size()
	for i in range(0, triangulated.size(), 3):
		indices.append(triangulated[i + 2] + offset)
		indices.append(triangulated[i + 1] + offset)
		indices.append(triangulated[i] + offset)

	for i in range(polygon.size()):
		var next = (i + 1) % polygon.size()
		indices.append(i)
		indices.append(next)
		indices.append(i + offset)
		indices.append(next)
		indices.append(next + offset)
		indices.append(i + offset)

	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh_instance.mesh = arr_mesh
