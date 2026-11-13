@tool
class_name PathData extends Resource
## The actual data that represents a path.

enum PathType { ONE_SHOT, LOOP, PING_PONG }

@export var vertices: Array[PathVertex] = []
@export var edges: Array[PathEdge] = []

@export var default_speed: float = 1
@export var path_type: PathType = PathType.ONE_SHOT


func _validate_property(property: Dictionary) -> void:
	if property.name in ["vertices", "edges"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR

var _vertex_by_id: Dictionary = {}
var _edge_by_id: Dictionary = {}
var _outgoing_by_vertex: Dictionary = {}
var _cache_valid: bool = false


func invalidate_cache() -> void:
	_cache_valid = false


func _ensure_cache() -> void:
	if _cache_valid:
		return
	_vertex_by_id.clear()
	_edge_by_id.clear()
	_outgoing_by_vertex.clear()
	for v in vertices:
		_vertex_by_id[v.id] = v
	for e in edges:
		_edge_by_id[e.id] = e
		if not _outgoing_by_vertex.has(e.from_vertex):
			_outgoing_by_vertex[e.from_vertex] = [] as Array[PathEdge]
		_outgoing_by_vertex[e.from_vertex].append(e)
	_cache_valid = true


func get_vertex_by_id(vertex_id: int) -> PathVertex:
	_ensure_cache()
	return _vertex_by_id.get(vertex_id, null)


func add_vertex(position: Vector3) -> PathVertex:
	var v := PathVertex.new()
	v.id = _next_free_id(vertices.map(func(x): return x.id))
	v.position = position
	vertices.append(v)
	invalidate_cache()
	return v


func insert_vertex(vertex: PathVertex) -> void:
	vertices.append(vertex)
	invalidate_cache()


## Same reasoning as insert_vertex(), for edges.
func insert_edge(edge: PathEdge) -> void:
	edges.append(edge)
	invalidate_cache()


func remove_vertex(vertex_id: int) -> void:
	vertices = vertices.filter(func(v): return v.id != vertex_id)
	edges = edges.filter(func(e): return e.from_vertex != vertex_id and e.to_vertex != vertex_id)
	invalidate_cache()


func remove_vertex_only(vertex_id: int) -> void:
	vertices = vertices.filter(func(v): return v.id != vertex_id)
	invalidate_cache()


func get_edge_by_id(edge_id: int) -> PathEdge:
	_ensure_cache()
	return _edge_by_id.get(edge_id, null)


func add_edge(from_vertex_id: int, to_vertex_id: int) -> PathEdge:
	assert(get_vertex_by_id(from_vertex_id) != null, "add_edge: from_vertex_id does not exist")
	assert(get_vertex_by_id(to_vertex_id) != null, "add_edge: to_vertex_id does not exist")
	var e := PathEdge.new()
	e.id = _next_free_id(edges.map(func(x): return x.id))
	e.from_vertex = from_vertex_id
	e.to_vertex = to_vertex_id
	edges.append(e)
	invalidate_cache()
	return e


func remove_edge(edge_id: int) -> void:
	edges = edges.filter(func(e): return e.id != edge_id)
	invalidate_cache()


func set_edge_from_vertex(edge_id: int, new_from_vertex_id: int) -> void:
	var e := get_edge_by_id(edge_id)
	if e == null:
		return
	e.from_vertex = new_from_vertex_id
	invalidate_cache()


func set_edge_to_vertex(edge_id: int, new_to_vertex_id: int) -> void:
	var e := get_edge_by_id(edge_id)
	if e == null:
		return
	e.to_vertex = new_to_vertex_id
	invalidate_cache()


func get_outgoing_edges(vertex_id: int) -> Array[PathEdge]:
	_ensure_cache()
	return _outgoing_by_vertex.get(vertex_id, [] as Array[PathEdge])


func get_incoming_edges(vertex_id: int) -> Array[PathEdge]:
	var result: Array[PathEdge] = []
	for e in edges:
		if e.to_vertex == vertex_id:
			result.append(e)
	return result


func compute_vertex_timing(vertex_id: int) -> Dictionary:
	var chain: Array[int] = []
	var visited: Dictionary = {}
	var current_id := vertex_id
	
	while true:
		if visited.has(current_id):
			return {"reachable": false, "arrival": 0.0, "departure": 0.0}
		visited[current_id] = true
		chain.append(current_id)
		
		var incoming := get_incoming_edges(current_id).filter(func(e): return not e.is_loop_edge)
		if incoming.is_empty():
			break
		current_id = incoming[0].from_vertex
	
	chain.reverse()
	
	var time := 0.0
	var arrival := 0.0
	for i in chain.size():
		var vertex := get_vertex_by_id(chain[i])
		if vertex == null:
			return {"reachable": false, "arrival": 0.0, "departure": 0.0}
		
		if i > 0:
			var prev_vertex := get_vertex_by_id(chain[i - 1])
			var edge_length := prev_vertex.position.distance_to(vertex.position)
			var speed := vertex.get_effective_speed(default_speed)
			time += edge_length / speed if speed > 0.0 else 0.0
		
		arrival = time
		
		for action in vertex.actions:
			if action == null or not action.enabled:
				continue
			if action.execution_direction == VertexAction.ExecutionDirection.BACKWARD_ONLY:
				continue
			if action is WaitAction:
				time += action.duration

	return {"reachable": true, "arrival": arrival, "departure": time}


func get_start_vertex() -> PathVertex:
	for v in vertices:
		var non_loop_incoming := get_incoming_edges(v.id).filter(func(e): return not e.is_loop_edge)
		if non_loop_incoming.is_empty():
			return v
	return null


func _next_free_id(existing_ids: Array) -> int:
	var max_id := -1
	for id in existing_ids:
		max_id = max(max_id, id)
	return max_id + 1
