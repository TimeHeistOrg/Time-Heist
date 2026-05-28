extends Node

@export_category("Includes")
@export var input_manager: bool
@export var ui_manager: bool
@export var time_manager: bool

const input_manager_scene := preload("res://Globals/input_manager.gd")
const ui_manager_scene := preload("res://Modules/UI/ui_manager.tscn")
const time_manager_scene := preload("res://Modules/TimeTravel/TimeManager.gd")

func _ready():
	print("scene config ready")
	if input_manager:
		var im: InputManager = input_manager_scene.new()
		add_child(im)
		print("path ", im.get_path())
	if ui_manager:
		var uim: UI_Manager = ui_manager_scene.instantiate()
		add_child(uim)
		print("path ", uim.get_path())
	if time_manager:
		var tm: TimeManager = time_manager_scene.new()
		add_child(tm)
		print("path ", tm.get_path())
