class_name PathPropertyEditor extends EditorProperty

var undo_redo: EditorUndoRedoManager
var resource_slot: PathResourcePicker
var is_open: bool = false
var mini_inspector: Control

func _init(_npc: PathFollower, _undo_redo: EditorUndoRedoManager):
	set_object_and_property(_npc,"path")
	undo_redo = _undo_redo
	resource_slot = PathResourcePicker.new(self)
	resource_slot.base_type = "NPCPath"
	resource_slot.edited_resource = get_edited_object().path
	resource_slot.resource_changed.connect(on_resource_changed)
	resource_slot.resource_selected.connect(on_resource_selected)
	add_child(resource_slot)
	mini_inspector = EditorInspector.new()
	mini_inspector.custom_minimum_size = Vector2(0,200)
	mini_inspector.visible = false
	add_child(mini_inspector)
	property_changed.connect(on_property_changed)

func on_property_changed(property: StringName, value:NPCPath, field: StringName, changing: bool):
	undo_redo.create_action("Set NPCPath")
	undo_redo.add_do_property(get_edited_object(),"updating_path",true)
	undo_redo.add_do_property(get_edited_object(),"path",value)
	undo_redo.add_do_method(get_edited_object(),"notify_property_list_changed")
	undo_redo.add_do_property(get_edited_object(),"updating_path",false)
	
	undo_redo.add_undo_property(get_edited_object(),"path",get_edited_object()[get_edited_property()])
	undo_redo.add_undo_method(get_edited_object(),"notify_property_list_changed")
	undo_redo.commit_action()
	get_edited_object().notify_property_list_changed()

func on_resource_changed(resource: NPCPath):
	emit_changed(get_edited_property(),resource)

func on_resource_selected(resource:NPCPath, inspect: bool):
	if is_open:
		close_mini_inspector()
	else:
		open_mini_inspector()

func open_mini_inspector():
	mini_inspector.visible = true
	mini_inspector.edit(get_edited_object()[get_edited_property()])
	set_bottom_editor(mini_inspector)
	is_open = true

func close_mini_inspector():
	mini_inspector.visible = false
	set_bottom_editor(null)
	is_open = false

func create_new_path():
	var new_path = NPCPath.new()
	#resource_slot.edited_resource = new_path
	#emit_changed(get_edited_property(),new_path)
	undo_redo.create_action("Create NPCPath")
	undo_redo.add_do_property(get_edited_object(),"updating_path",true)
	undo_redo.add_do_property(get_edited_object(),"path",new_path)
	undo_redo.add_do_method(get_edited_object(),"notify_property_list_changed")
	undo_redo.add_do_property(get_edited_object(),"updating_path",false)
	
	undo_redo.add_undo_property(get_edited_object(),"path",get_edited_object()[get_edited_property()])
	undo_redo.add_undo_method(get_edited_object(),"notify_property_list_changed")
	undo_redo.commit_action()
