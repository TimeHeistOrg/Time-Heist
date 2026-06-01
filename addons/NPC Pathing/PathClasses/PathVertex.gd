@tool
class_name PathVertex extends PathComponent


@export var position: Vector3:
	set(value):
		var old = position
		position = value
		emit_manual_change("position",old)

@export var vertex_actions: Array[VertexAction]:
	set(value):
		#print("vertex actions changed")
		vertex_actions = value
		if Engine.is_editor_hint():
			_validate_actions()
			vertex_action_changed()

func _init(_id: int = 0, _path: NPCPath = null):
	super(_id,_path)

func _to_string():
	return "Vertex at " + str(position)

func num_actions():
	return vertex_actions.size()

func action(ix: int) -> VertexAction:	
	if ix < 0 or ix >= vertex_actions.size():
		return null
	return vertex_actions[ix]

func get_duration():
	var duration: float = 0
	for action in vertex_actions:
		if action is WaitAction:
			duration += action.duration
	return duration

func _validate_property(property: Dictionary):
	super(property)
	if id == 0:
		if property.name == "time_start":
			property.usage |= PROPERTY_USAGE_READ_ONLY
		if property.name == "position":
			property.usage |= PROPERTY_USAGE_READ_ONLY

func _validate_actions():
	#print("validate actions")
	var cur_start_time = time_start
	for action: VertexAction in vertex_actions:
		if action is WaitAction:
			action.editing_action = true
			action.start_time = cur_start_time
			action.end_time = action.start_time + action.duration
			cur_start_time = action.end_time
			action.editing_action = false
	verify_signals()

func verify_signals():
	for action: VertexAction in vertex_actions:
		if action is WaitAction:
			if not action.changed.is_connected(vertex_action_changed):
				action.changed.connect(vertex_action_changed)
			if not action.validate_action.is_connected(_validate_actions):
				action.validate_action.connect(_validate_actions)

func vertex_action_changed():
	emit_manual_change("vertex_actions",null)

func progress(npc: PathFollower, from: float, to: float):
	var cur_action = action(npc.cur_action_ix)
	while cur_action and cur_action.progress(npc, from, to):
		npc.cur_action_ix += 1
		cur_action = action(npc.cur_action_ix)
	return to >= time_end

func revert(npc: PathFollower, from: float, to: float):
	var cur_action = action(npc.cur_action_ix)
	while cur_action and cur_action.revert(npc, from, to):
		npc.cur_action_ix -= 1
		cur_action = action(npc.cur_action_ix)
	return to < time_start
