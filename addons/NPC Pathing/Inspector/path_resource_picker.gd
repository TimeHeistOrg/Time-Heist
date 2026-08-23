class_name PathResourcePicker extends EditorResourcePicker

var property_editor: PathPropertyEditor

func _init(_property_editor: PathPropertyEditor):
	property_editor = _property_editor

func _set_create_options(menu_node: Object):
	menu_node.add_separator("New",0)
	menu_node.add_icon_item(EditorInterface.get_base_control().get_theme_icon("Object","EditorIcons"),"NPCPath",2)
	menu_node.add_separator()
	if not menu_node.id_pressed.is_connected(_handle_menu_selected):
		menu_node.id_pressed.connect(_handle_menu_selected)

func _handle_menu_selected(id: int):
	if id == 2:
		property_editor.create_new_path()
	return true
