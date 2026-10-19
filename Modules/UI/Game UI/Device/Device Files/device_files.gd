extends MenuTabPanel
class_name DeviceFiles

#var documents : Array = [preload("res://Assets/UI/Time Travel Menu/Files_Test/person2.png"), preload("res://Assets/UI/Time Travel Menu/Files_Test/person3.png"), preload("res://Assets/UI/Time Travel Menu/Files_Test/person4.png"), preload("res://Assets/UI/Time Travel Menu/Files_Test/person_1.png"), preload("res://Assets/UI/Time Travel Menu/Files_Test/place1.jpg")]
@onready var folder_buttons: VBoxContainer = $"MarginContainer/HBoxContainer/LeftPanel/ScrollContainer/Folder Buttons"
@onready var folders: Control = $"MarginContainer/HBoxContainer/MidPanel/Folders"
var folder_button: PackedScene = preload("res://Modules/UI/Game UI/Device/Device Files/folder_button.tscn")
@onready var left_panel: MarginContainer = $MarginContainer/HBoxContainer/LeftPanel
@onready var mid_panel: VBoxContainer = $MarginContainer/HBoxContainer/MidPanel
@onready var fullscreen_button: TextureButton = $MarginContainer/HBoxContainer/Control/HBoxContainer/Fullscreen
@onready var fullscreen_controls: Label = $MarginContainer/HBoxContainer/Control/HBoxContainer/Controls

var device_files_list : PackedScene = preload("res://Modules/UI/Game UI/Device/Device Files/device_files_list.tscn")
var fullscreen: bool = false

@onready var document_viewer := $MarginContainer/HBoxContainer/Control/RightPanel/SubViewport/DeviceDocumentViewer

func _ready() -> void:
	#Add already owned documents
	for doc in global_inventory.documents:
		check_for_new_tags(doc)
		add_new_doc(doc)
	global_inventory.update_device_files.connect(update_doc_list)
		
	if folder_buttons.get_child_count() != 0:
		var button = folder_buttons.get_child(0) as FolderButton
		button.button_pressed = true
		view_panel(folders.get_child(0))
	
	#$MarginContainer/HBoxContainer/SubViewportContainer/SubViewport.size = $MarginContainer/HBoxContainer/SubViewportContainer.size

func handle_input(_delta):
	document_viewer.handle_input(_delta)
	if fullscreen:
		document_viewer.handle_fullscreen_input(_delta)

func select():
	super.select()
	var button = (folder_buttons.get_child(0) as FolderButton) if folder_buttons.get_children().size() > 0 else null
	if button:
		button.button_pressed = true
	globals.new_in_device.emit(false, globals.Device_Tabs.Files)
	if fullscreen and fullscreen_button:
		fullscreen_button.grab_focus() #for when you are in fullscreen, change tabs, then come back
		

func view_panel(panel_to_view:DeviceFilesList):
	for folder in folders.get_children():
		folder.hide()
	
	panel_to_view.show()
	
func view_doc(doc_to_view:int):
	document_viewer.set_document_texture(doc_to_view)

func update_doc_list(doc : DocumentInfo):
	check_for_new_tags(doc)
	add_new_doc(doc)
	
#region populating documents
func add_new_doc(doc: DocumentInfo):
	for doc_tag in doc.relevant_tags:
		for folder in folders.get_children():
			if folder.tag == doc_tag:
				var doc_button = folder.add_doc(doc)
				doc_button.pressed.connect(view_doc.bind(doc.document_id))

func check_for_new_tags(doc: DocumentInfo):
	for tag in doc.relevant_tags:
		var found = false
		for button in folder_buttons.get_children():
			if button.label_text == tag:
				found = true
		if not found:
			add_new_folder(tag)
			
func add_new_folder(folder_name : String):
	#Edge case for when there are no folders
	if folders.get_child_count() == 0:
		$MarginContainer/HBoxContainer/MidPanel/NoDocuments.queue_free()
	
	#New folder button
	var new_folder_button = folder_button.instantiate()
	folder_buttons.add_child(new_folder_button)
	#await get_tree().process_frame
	new_folder_button.label_text = folder_name
	
	#New folder
	var new_folder = device_files_list.instantiate()
	new_folder.set_tag(folder_name)
	folders.add_child(new_folder)
	new_folder.button = new_folder_button.get_path()
	new_folder.name = folder_name + "Container"
	new_folder.hide()
	
	#Connect button
	new_folder_button.pressed.connect(view_panel.bind(new_folder))
	
	#Make the top one the first focused button
	main_focus = folder_buttons.get_child(0)
	
	return new_folder
	
#endregion

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	@warning_ignore("standalone_ternary")
	left_panel.hide() if toggled_on else left_panel.show()
	@warning_ignore("standalone_ternary")
	mid_panel.hide() if toggled_on else mid_panel.show()
	if not toggled_on: document_viewer.reset_position()
	@warning_ignore("standalone_ternary")
	fullscreen_controls.show() if toggled_on else fullscreen_controls.hide()
	fullscreen = toggled_on
