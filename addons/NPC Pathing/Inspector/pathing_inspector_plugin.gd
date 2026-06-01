extends EditorInspectorPlugin

var undo_redo: EditorUndoRedoManager

func _init(_undo_redo: EditorUndoRedoManager):
	undo_redo = _undo_redo

func _can_handle(object):
	return object is PathFollower

func _parse_property(object, type, name, hint_type, hint_string, usage_flags, wide):
	if name == "path":
		add_property_editor("path",PathPropertyEditor.new(object, undo_redo))
		return true
	return false
