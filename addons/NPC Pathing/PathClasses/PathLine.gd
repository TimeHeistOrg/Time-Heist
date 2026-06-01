@tool
class_name PathLine extends PathComponent

@export var speed: float:
	set(value):
		var old = speed
		speed = value
		emit_manual_change("speed",old)

@export var prev_vertex: PathVertex
@export var next_vertex: PathVertex

@export var is_loop_line: bool = false

func _init(_prev_vertex = null,_next_vertex = null, _id: int = 0, _path:NPCPath = null):
	super(_id,_path)
	prev_vertex = _prev_vertex
	next_vertex = _next_vertex
	if _path:
		speed = _path.default_speed

func _to_string():
	return "Line speed:  " + str(speed)

func recalculate_speed():
	var duration: float = time_end - time_start
	if is_zero_approx(duration):
		speed = INF
	else:
		speed = get_length()/duration

func get_length():
	return prev_vertex.position.distance_to(next_vertex.position)

func get_direction() -> Vector3:
	return next_vertex.position - prev_vertex.position

func get_position_at_time(time: float) -> Vector3:
	var start_pos: Vector3 = prev_vertex.position
	var end_pos: Vector3 = next_vertex.position
	var progress: float = (time-time_start)/(time_end-time_start)
	return lerp(start_pos,end_pos,progress)

func _validate_property(property: Dictionary):
	super(property)
	if property.name == "prev_vertex":
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "next_vertex":
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "is_loop_line":
		property.usage = PROPERTY_USAGE_STORAGE
	if property.name == "time_start":
		property.usage |= PROPERTY_USAGE_READ_ONLY
	if property.name == "time_end":
		if is_loop_line:
			property.usage |= PROPERTY_USAGE_DEFAULT
		else:
			property.usage |= PROPERTY_USAGE_READ_ONLY

func progress(npc: PathFollower, from: float, to: float):
	npc.global_position = get_position_at_time(to)
	npc.look_at(npc.global_position + get_direction())
	return to >= time_end

func revert(npc: PathFollower, from: float, to: float):
	if to > time_start:
		npc.global_position = get_position_at_time(to)
		npc.look_at(npc.global_position + get_direction())
		return false
	else:
		npc.global_position = prev_vertex.position
		return true
