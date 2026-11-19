@tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.
var dock

func _enter_tree():
	# Initialization of the plugin goes here.
	# Load the dock scene and instantiate it.
	var dock_scene = preload("res://addons/document_database/document_database_dock.tscn").instantiate()

	# Create the dock and add the loaded scene to it.
	dock = EditorDock.new()
	dock.add_child(dock_scene)

	dock.title = "Document Database"

	# Note that LEFT_UL means the left of the editor, upper-left dock.
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM

	# Allow the dock to be on the left or right of the editor, and to be made floating.
	dock.available_layouts = EditorDock.DOCK_LAYOUT_VERTICAL | EditorDock.DOCK_LAYOUT_FLOATING

	add_dock(dock)


func _exit_tree():
	# Clean-up of the plugin goes here.
	# Remove the dock.
	remove_dock(dock)
	# Erase the control from the memory.
	dock.queue_free()
