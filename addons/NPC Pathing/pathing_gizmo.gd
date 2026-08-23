# my_custom_gizmo.gd
class_name PathingGizmo extends EditorNode3DGizmo

var path_mesh = preload("res://addons/NPC Pathing/Meshes/PathMesh.tres")
var arrow_mesh = preload("res://addons/NPC Pathing/Meshes/ArrowMesh.tres")

var moving_vertex: PathVertex = null
var selected_component: PathComponent = null

enum GIZMO_ACTION {NONE,MOVE,BRANCH_FORWARD,BRANCH_BACKWARD}
var deferred_action: GIZMO_ACTION = GIZMO_ACTION.NONE
var cur_action: GIZMO_ACTION = GIZMO_ACTION.NONE

var undo_redo: EditorUndoRedoManager

var npc_pos_offset: Vector3

func _init(_undo_redo: EditorUndoRedoManager):
	undo_redo = _undo_redo

func _redraw():
	#print("redraw")
	var path: NPCPath = get_node_3d().path
	npc_pos_offset = -get_node_3d().global_position
	npc_pos_offset.y = 0
	
	clear()
	if not path:
		selected_component = null
		moving_vertex = null
		return
	var line_material = get_plugin().get_material("line", self)
	var handle_material := get_plugin().get_material("handle",self)
	
	var root_array = PackedVector3Array()
	root_array.push_back(path.at(0).position + npc_pos_offset)
	add_handles(root_array,handle_material,PackedInt32Array(),false,true)
	
	var vertex_positions := PackedVector3Array()
	var vertex_ids := PackedInt32Array()
	var line_positions := PackedVector3Array()
	var line_ids := PackedInt32Array()
	
	
	
	for i in range(1,path.size()):
		var component = path.at(i)
		if component is PathVertex:
			vertex_positions.push_back(path.at(i).position + npc_pos_offset)
			vertex_ids.push_back(i)
		elif component is PathLine:
			line_positions.push_back(draw_line(component, line_material))
			line_ids.push_back(i)
	
	if vertex_positions.size() > 0:
		if path.loop:
			line_positions.push_back(draw_line(path.at(path.size()-1), line_material))
			line_ids.push_back(path.size()-1)
		add_handles(vertex_positions,handle_material,vertex_ids)
		add_handles(line_positions,handle_material,line_ids)

func draw_line(line: PathLine, line_material):
	var line_vec = line.next_vertex.position - line.prev_vertex.position
	var line_midpoint = (line.next_vertex.position + line.prev_vertex.position) * 0.5
	line_midpoint += npc_pos_offset
	var rotation: Vector3 = Vector3(-PI/2,Vector3.FORWARD.signed_angle_to(line_vec,Vector3.UP),0)
	var basis = Basis.from_scale(Vector3(1,line_vec.length()/2,1))
	basis = basis.rotated(Vector3.RIGHT, rotation.x)
	basis = basis.rotated(Vector3.UP, rotation.y)
	var transform: Transform3D = Transform3D(basis,line_midpoint)
	add_mesh(path_mesh,line_material,transform)
	add_mesh(arrow_mesh,line_material,Transform3D(Basis.from_euler(rotation),(line.next_vertex.position - line_vec.normalized() * 0.3) + npc_pos_offset))
	return line_midpoint

func _begin_handle_action(id, secondary):
	deferred_action = GIZMO_ACTION.NONE
	var path = get_node_3d().path
	var select_id: int = id
	if id % 2 == 0:
		if Input.is_key_pressed(KEY_CTRL) or Input.is_key_pressed(KEY_META): #Create new line and vertex forward
			deferred_action = GIZMO_ACTION.BRANCH_FORWARD
		elif id == 0:
			pass
		elif Input.is_key_pressed(KEY_SHIFT): #Create new line and vertex backward
			deferred_action = GIZMO_ACTION.BRANCH_BACKWARD
		elif Input.is_key_pressed(KEY_ALT):
			undo_redo.create_action("Delete Vertex")
			undo_redo.add_do_method(path,"delete_vertex",id)
			undo_redo.add_do_method(self,"select_component",null)
			undo_redo.add_do_method(self,"_redraw")
			undo_redo.add_undo_method(path,"redo_branch",path.at(id),path.at(id-1))
			undo_redo.add_undo_method(self,"select_component",path.at(id))
			undo_redo.add_undo_method(self,"_redraw")
			undo_redo.commit_action()
			return
		else:
			deferred_action = GIZMO_ACTION.MOVE
	select_component(path.at(id))

func select_component(component: PathComponent):
	selected_component = component
	EditorInterface.get_inspector().edit(component)

func _set_handle(id, secondary, camera, point):
	check_deferred_action()
	
	var path: NPCPath = get_path()
	if moving_vertex:
		#Handle position
		var origin = camera.project_ray_origin(point)
		var direction = camera.project_ray_normal(point)
		var plane = Plane(Vector3.UP,get_node_3d().position.y)
		var position: Vector3 = plane.intersects_ray(origin,direction)
		position = position.snapped(Vector3(1,0,1) * path.snap)
		position.y = 0
		moving_vertex.position = position
		
		#Handle time
		var prev_line: PathLine = path.at(moving_vertex.id-1)
		var prev_vert: PathVertex = prev_line.prev_vertex
		var add_time = (position.distance_to(prev_vert.position))/prev_line.speed
		moving_vertex.time_start = prev_vert.time_end + add_time
		moving_vertex.time_end = moving_vertex.time_start + moving_vertex.get_duration()
		_redraw()

func check_deferred_action():
	match deferred_action:
		GIZMO_ACTION.NONE:
			return
		GIZMO_ACTION.MOVE:
			undo_redo.create_action("Move Vertex")
			moving_vertex = selected_component
			undo_redo.add_undo_property(moving_vertex,"position",moving_vertex.position)
		GIZMO_ACTION.BRANCH_FORWARD:
			undo_redo.create_action("Branch Forward")
			moving_vertex = get_path().branch_forward(selected_component.id)
			undo_redo.add_undo_method(get_path(),"delete_vertex",moving_vertex.id)
			undo_redo.add_undo_method(self,"_redraw")
		GIZMO_ACTION.BRANCH_BACKWARD:
			undo_redo.create_action("Branch Backward")
			moving_vertex = get_path().branch_backward(selected_component.id)
			undo_redo.add_undo_method(get_path(),"delete_vertex",moving_vertex.id)
			undo_redo.add_undo_method(self,"_redraw")
	undo_redo.add_do_method(self,"select_component",moving_vertex)
	undo_redo.add_undo_method(self,"select_component",selected_component)
	get_path().updating_path = true
	cur_action = deferred_action
	deferred_action = GIZMO_ACTION.NONE
	

func _commit_handle(id, secondary, restore, cancel):
	if cur_action == GIZMO_ACTION.NONE:
		return
	get_path().commit_vertex(moving_vertex,cur_action)
	match cur_action:
		GIZMO_ACTION.MOVE:
			undo_redo.add_do_property(moving_vertex,"position",moving_vertex.position)
		GIZMO_ACTION.BRANCH_FORWARD:
			undo_redo.add_do_method(get_path(),"redo_branch",moving_vertex,get_path().at(moving_vertex.id-1))
			undo_redo.add_do_method(self,"_redraw")
		GIZMO_ACTION.BRANCH_BACKWARD:
			undo_redo.add_do_method(get_path(),"redo_branch",moving_vertex,get_path().at(moving_vertex.id-1))
			undo_redo.add_do_method(self,"_redraw")
	cur_action = GIZMO_ACTION.NONE
	moving_vertex = null
	get_path().updating_path = false
	undo_redo.commit_action(false)

func _get_handle_name(id, secondary):
	return "Handle " + str(id)

func _get_handle_value(id, secondary) -> Variant:
	if selected_component is PathVertex:
		return selected_component.position
	elif selected_component is PathLine:
		return selected_component.speed
	else:
		return null

func _is_handle_highlighted(id, secondary):
	return selected_component and id == selected_component.id

func get_path() -> NPCPath:
	return get_node_3d().path
