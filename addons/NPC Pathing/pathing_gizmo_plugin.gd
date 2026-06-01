# my_custom_gizmo_plugin.gd
extends EditorNode3DGizmoPlugin


const PathingGizmo = preload("res://addons/NPC Pathing/pathing_gizmo.gd")

var undo_redo

func _get_gizmo_name():
	return "NPC Pathing Gizmo"

func _init(_undo_redo: EditorUndoRedoManager):
	undo_redo = _undo_redo
	create_material("line", Color(0.264, 0.622, 0.341, 1.0))
	create_material("wait", Color(0.366, 0.559, 0.851, 1.0))
	create_material("interact", Color(0.834, 0.415, 0.359, 1.0))
	create_handle_material("handle")

func _create_gizmo(node):
	if node is PathFollower:
		return PathingGizmo.new(undo_redo)
	else:
		return null
