extends AppData
class_name FileAppConfig

func _init() -> void:
	app_scene = preload("res://Modules/Interaction/Computer/File App/file_tab.tscn")

@export var file: DocumentInfo:
	set(value):
		file = value
		app_name = file.title
		icon = file.document_image
	
