extends AppData
class_name TextAppConfig

func _init() -> void:
	app_name = "Text"
	icon = preload("res://Modules/Interaction/Computer/ComputerAssets/Apps/text_app.png")
	app_scene = preload("res://Modules/Interaction/Computer/Text App/text_tab.tscn")

@export var convos: Array[TextConvo]
@export var which_person: Array[int]
