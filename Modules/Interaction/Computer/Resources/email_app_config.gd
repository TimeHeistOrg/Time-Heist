extends AppData
class_name EmailAppConfig

func _init() -> void:
	app_name = "Email"
	icon = preload("res://Assets/UI/Computer/Apps/mail app.png")
	app_scene = preload("res://Modules/Interaction/Computer/Email App/email_tab.tscn")

@export var emails: Array[DocumentInfo]
