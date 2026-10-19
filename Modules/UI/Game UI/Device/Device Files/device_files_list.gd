extends ScrollContainer
class_name DeviceFilesList

@onready var files: VBoxContainer = $Files

var tag: String
var documents: Array[DocumentInfo]
var button: NodePath

func set_tag(_tag: String) -> void:
	tag = _tag
	pass
	
func add_doc(doc: DocumentInfo) -> Button:
	#Add button
	var doc_button = Button.new()
	files.add_child(doc_button)
	
	doc_button.toggle_mode = true
	doc_button.button_group = preload("res://Assets/UI/Device Menu/Database/device_files.tres")
	doc_button.text = doc.title
	doc_button.focus_neighbor_left = button
	documents.append(doc)
	
	return doc_button
	
