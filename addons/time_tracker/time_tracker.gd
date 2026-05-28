@tool
extends EditorPlugin
var node_ref

func _enable_plugin():
	# Add autoloads here.
	pass


func _disable_plugin():
	# Remove autoloads here.
	pass


func _enter_tree():
	# Initialization of the plugin goes here.
	node_ref = preload("res://addons/time_tracker/time_tracker_replacement.gd").new()
	get_tree().root.add_child(node_ref)
	node_ref.undo_redo = get_undo_redo()

func _exit_tree():
	# Clean-up of the plugin goes here.
	get_tree().root.remove_child(node_ref)
