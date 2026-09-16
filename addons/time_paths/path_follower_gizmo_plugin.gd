@tool
class_name PathFollowerGizmoPlugin extends EditorNode3DGizmoPlugin
## Draws each edge of a PathFollower's assigned path as a semi-transparent
## green cylinder with a cone tip, so the loaded path is visible in the
## normal 3D viewport (not just while actively editing it via the Time
## Paths dock) without being as visually loud as the editor tool's own
## bright lines/arrows -- meant to sit quietly in the background, toggle
## off per-follower (PathFollower.show_path_gizmo) if it's in the way.
##
## Registered once via EditorPlugin.add_node_3d_gizmo_plugin() and applies
## automatically to every PathFollower in any open scene -- no per-node
## setup needed beyond the toggle.
##
## KNOWN LIMITATION: gizmos redraw on node property changes, selection
## changes, and undo/redo, but NOT automatically when a PathData resource's
## internal vertices/edges change out from under it (e.g. editing the same
## path via our dock while a PathFollower elsewhere in the scene is using
## it). Reselecting the follower node (or moving/touching it) forces a
## redraw in the meantime -- live-syncing this properly would need the
## editor tool to explicitly notify affected followers on every graph
## mutation, which felt like more plumbing than this deserved for a first
## pass.

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
		# PathVertex.position is authored as a GLOBAL/world coordinate (see
		# the editor tool), but gizmo geometry is drawn in the node's LOCAL
		# space -- convert.
		var local_from := follower.to_local(from_v.position)
		var local_to := follower.to_local(to_v.position)
		var mesh := _build_edge_mesh(local_from, local_to)
		if mesh != null:
			gizmo.add_mesh(mesh, material)


## Builds a cylinder (shaft) + cone (arrowhead) mesh pointing from `from`
## toward `to`, in whatever local space those two points are already given
## in. The cone eats into the last third of the edge at most, so a very
## short edge doesn't disappear entirely under an oversized cone.
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

	# Cylinder shaft.
	for i in SEGMENTS:
		var a0 := (float(i) / SEGMENTS) * TAU
		var a1 := (float(i + 1) / SEGMENTS) * TAU
		var p0 := from + (right * cos(a0) + up * sin(a0)) * CYLINDER_RADIUS
		var p1 := from + (right * cos(a1) + up * sin(a1)) * CYLINDER_RADIUS
		var p2 := cylinder_end + (right * cos(a0) + up * sin(a0)) * CYLINDER_RADIUS
		var p3 := cylinder_end + (right * cos(a1) + up * sin(a1)) * CYLINDER_RADIUS
		st.add_vertex(p0); st.add_vertex(p2); st.add_vertex(p1)
		st.add_vertex(p1); st.add_vertex(p2); st.add_vertex(p3)

	# Cone arrowhead, including a base cap so it doesn't look hollow from
	# behind/the side.
	for i in SEGMENTS:
		var a0 := (float(i) / SEGMENTS) * TAU
		var a1 := (float(i + 1) / SEGMENTS) * TAU
		var p0 := cylinder_end + (right * cos(a0) + up * sin(a0)) * CONE_RADIUS
		var p1 := cylinder_end + (right * cos(a1) + up * sin(a1)) * CONE_RADIUS
		st.add_vertex(p0); st.add_vertex(to); st.add_vertex(p1)
		st.add_vertex(p1); st.add_vertex(p0); st.add_vertex(cylinder_end)

	st.generate_normals()
	return st.commit()
