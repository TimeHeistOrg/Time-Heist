@tool
class_name PathFollower extends Node3D

@export var color : Color = Color("cf7d00"):
	set(value):
		color = value
		#print("changing their colors")
		if find_child("MeshInstance3D"):
			$MeshInstance3D.mesh.material.albedo_color = value
		if find_child("torso"):
			$torso.get_surface_override_material(0).emission = color

@export var branch_paths: Array[NPCPath] = []
@export var follow_branch: int = -1:
	set(value):
		if value < branch_paths.size() and value > -2:
			follow_branch = value
			if not Engine.is_editor_hint():
				path_following = branch_paths[value]
				initialize_path_vars()
var path_following: NPCPath = null: #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"path_following",path_following)
		path_following = value
		initialize_path_vars()

var time_manager: TimeManager

var cur_component: PathComponent = null
var cur_action_ix: int = 0
var last_processed_time: float = 0
var reached_path_end: bool = false
var branched: bool
@export var start_offset: float = 0

var start_pos: Vector3

@export_category("Path Editor")
@export var path: NPCPath:
	set(value):
		path = value
		if Engine.is_editor_hint():
			if path and is_node_ready(): 
				path.updating_path = true
				path.path_components[0].position = global_position
				path.updating_path = false
				if not path.changed.is_connected(update_gizmos):
					path.changed.connect(update_gizmos)
			update_gizmos()

func initialize_path_vars():
	if not globals.time_manager:
		return
	var cur_time = globals.time_manager.cur_time + start_offset
	if path_following:
		cur_component = path_following.at(0)
		while cur_component and cur_component.time_end <= cur_time:
			cur_component = path_following.at(cur_component.id+1)
		if cur_component is PathVertex:
			cur_action_ix = 0
			var cur_action = cur_component.action(cur_action_ix)
			while cur_action is InstantAction or (cur_action is WaitAction and cur_action.end_time <= cur_time):
				cur_action_ix += 1
				cur_action = cur_component.action(cur_action_ix)

func interact_with(nodepath: NodePath):
	var node = get_node(nodepath)
	if node is Interactable:
		node.interact(self)
	else:
		for child in node.get_children():
			if child is Interactable:
				child.interact(self)
				return
		print("node at ", nodepath, " is not an Interactable and has no Interactible children")
	

func face(rotation_deg: float):
	#print("facing ", rotation_deg)
	rotation.y = deg_to_rad(rotation_deg)

func branch_if(branchAction: BranchAction):
	#print("branch if")
	var temp = get_node(branchAction.object)
	#print("node: ", temp)
	if temp.get(branchAction.property_name) != branchAction.is_false:
		#print("branching")
		path_following = branch_paths[branchAction.dest_path_id]
		initialize_path_vars()
		#print("done branching")
		branched = true
		return true
	return false

func set_start_offset(value:float):
	start_offset = value

func start_path_at_current_time(): #very temporary for tutorial purpose
	start_offset = -time_manager.cur_time

func _ready():
	if not Engine.is_editor_hint():
		time_manager = globals.time_manager
		start_pos = Vector3.UP * position.y
		if follow_branch > -1:
			path_following = branch_paths[follow_branch]
			initialize_path_vars()


func _process(_delta):
	if not Engine.is_editor_hint():
		if not path_following:
			return
		var cur_time = time_manager.cur_time + start_offset
		if cur_time < 0:
			return
		if path_following.loop:
			cur_time = fmod(cur_time,path_following.get_path_duration())
		if last_processed_time > cur_time: # moved backward in time
			path_following.revert(self,last_processed_time,cur_time)
		elif last_processed_time < cur_time: # moved forward in time
			path_following.progress(self,last_processed_time,cur_time)
		else: #time did not move?
			pass
		last_processed_time = cur_time
