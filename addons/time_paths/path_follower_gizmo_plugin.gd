@tool
class_name PathFollowerGizmoPlugin extends EditorNode3DGizmoPlugin
## Draws a preview of the path being assigned to the PathFollower with semi-transparent green segments.

const EDGE_COLOR := Color(0.2, 0.9, 0.4, 0.35)
const CYLINDER_RADIUS := 0.05
const CONE_RADIUS := 0.12
const CONE_LENGTH := 0.3
const SEGMENTS := 8


func _init() -> void:
	create_material("time_paths_follower_edge", EDGE_COLOR)


func _get_gizmo_name() -> String:
	return "PathFollower"


func _has_gizmo(node: Node3D) -> bool:
	return node is PathFollower


func _redraw(gizmo: EditorNode3DGizmo) -> void:
	gizmo.clear()
	
	var follower := gizmo.get_node_3d() as PathFollower
	if follower == null or follower.path_data == null or not follower.show_path_gizmo:
		return
	
	var material := get_material("time_paths_follower_edge", gizmo)
	var path_data := follower.path_data
	
	for edge in path_data.edges:
		var from_v := path_data.get_vertex_by_id(edge.from_vertex)
		var to_v := path_data.get_vertex_by_id(edge.to_vertex)
		if from_v == null or to_v == null:
			continue
		var local_from := follower.to_local(from_v.position)
		var local_to := follower.to_local(to_v.position)
		var mesh := _build_edge_mesh(local_from, local_to)
		if mesh != null:
			gizmo.add_mesh(mesh, material)


func _build_edge_mesh(from: Vector3, to: Vector3) -> ArrayMesh:
	var direction := to - from
	var length := direction.length()
	if length < 0.001:
		return null
	direction = direction.normalized()
	
	var cone_length: float = min(CONE_LENGTH, length / 3.0)
	var cylinder_length := length - cone_length
	var cylinder_end := from + direction * cylinder_length
	
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right := direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	
	for i in SEGMENTS:
		var a0 := (float(i) / SEGMENTS) * TAU
		var a1 := (float(i + 1) / SEGMENTS) * TAU
		var p0 := from + (right * cos(a0) + up * sin(a0)) * CYLINDER_RADIUS
		var p1 := from + (right * cos(a1) + up * sin(a1)) * CYLINDER_RADIUS
		var p2 := cylinder_end + (right * cos(a0) + up * sin(a0)) * CYLINDER_RADIUS
		var p3 := cylinder_end + (right * cos(a1) + up * sin(a1)) * CYLINDER_RADIUS
		st.add_vertex(p0); st.add_vertex(p2); st.add_vertex(p1)
		st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)
	
	
	for i in SEGMENTS:
		var a0 := (float(i) / SEGMENTS) * TAU
		var a1 := (float(i + 1) / SEGMENTS) * TAU
		var p0 := cylinder_end + (right * cos(a0) + up * sin(a0)) * CONE_RADIUS
		var p1 := cylinder_end + (right * cos(a1) + up * sin(a1)) * CONE_RADIUS
		st.add_vertex(p0); st.add_vertex(to); st.add_vertex(p1)
		st.add_vertex(p1); st.add_vertex(p0); st.add_vertex(cylinder_end)
	
	st.generate_normals()
	return st.commit()
