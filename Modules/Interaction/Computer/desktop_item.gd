@tool
extends Control
class_name DesktopItem

@onready var icon: TextureRect = $VBoxContainer/Icon
@onready var title: Label = $VBoxContainer/Title

var app_data: AppData
var computer_ui: ComputerUI

func setup(app: AppData, ui: ComputerUI) -> void:
	app_data = app
	computer_ui = ui
	if app.icon:
		icon.texture = app.icon
	title.text = app.app_name

func _on_button_pressed() -> void:
	computer_ui.open_app(app_data)

func _on_mouse_entered() -> void:
	Input.set_custom_mouse_cursor(globals.clicking_cursor)

func _on_mouse_exited() -> void:
	Input.set_custom_mouse_cursor(globals.normal_cursor)
