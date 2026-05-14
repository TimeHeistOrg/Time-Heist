class_name FileTab extends AppBase
var file
@onready var file_viewer: TextureRect = $FileViewer

func setup(config: FileAppConfig) -> void:
	#print("file_app SETUP")
	file = config.file
	
func _ready() -> void:
	#print("file_app READY")
	file_viewer.texture = file.document_image

func open_process():
	super.open_process()
	globals.emit_signal("added_doc",file)
	
func get_fit_size() -> Vector2:
	if file and file.document_image:
		return file.document_image.get_size()
	return Vector2.ZERO
