extends AppBase
var file
@onready var file_viewer: TextureRect = $FileViewer

func setup(config: FileAppConfig) -> void:
	file = config.file
	file_viewer.texture = file.document_image

func open_process():
	super.open_process()
	globals.emit_signal("added_doc",file)
