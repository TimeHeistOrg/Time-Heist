@tool
class_name BranchActionInspectorPlugin extends EditorInspectorPlugin
## Plugin that displays a dropdown of the edges that leave the vertex that the BranchAction is being editted on.

var time_paths_plugin: EditorPlugin


func _can_handle(object: Object) -> bool:
	return object is BranchAction


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name != "target_edge_id":
		return false
	add_property_editor(name, EdgeIdEditorProperty.new(time_paths_plugin))
	return true


class EdgeIdEditorProperty extends EditorProperty:
	var _option_button: OptionButton
	var _time_paths_plugin: EditorPlugin
	var _updating: bool = false

	func _init(time_paths_plugin: EditorPlugin) -> void:
		_time_paths_plugin = time_paths_plugin
		_option_button = OptionButton.new()
		_option_button.item_selected.connect(_on_item_selected)
		add_child(_option_button)
		add_focusable(_option_button)

	func _update_property() -> void:
		_updating = true
		_option_button.clear()

		var ctx: Dictionary = _time_paths_plugin.get_selected_vertex_context() if _time_paths_plugin != null else {}
		var path_data: PathData = ctx.get("path_data")
		var vertex_id: int = ctx.get("vertex_id", -1)
		var current_value: int = get_edited_object().get(get_edited_property())

		if path_data == null or vertex_id == -1:
			_option_button.add_item("(no vertex selected)", -1)
			_option_button.disabled = true
			_updating = false
			return

		var outgoing: Array = path_data.get_outgoing_edges(vertex_id)
		if outgoing.is_empty():
			_option_button.add_item("(no outgoing edges)", -1)
			_option_button.disabled = true
			_updating = false
			return

		_option_button.disabled = false
		var selected_index := 0
		for i in outgoing.size():
			var e: PathEdge = outgoing[i]
			var label := "-> Vertex #%d" % [e.to_vertex]
			if e.is_loop_edge:
				label += " (loop)"
			_option_button.add_item(label, e.id)
			if e.id == current_value:
				selected_index = i
		_option_button.select(selected_index)
		_updating = false

	func _on_item_selected(index: int) -> void:
		if _updating:
			return
		emit_changed(get_edited_property(), _option_button.get_item_id(index))
