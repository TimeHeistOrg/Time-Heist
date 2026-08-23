class_name SceneConfig extends Node

@export var player: Player
@export var exclusion_list: Array[Node]
@export_category("Includes")
@export var input_manager: bool
@export var ui_manager: bool
@export var time_manager: bool
@export var add_effects: bool = true

@onready var scene_subviewport_container = $SubViewportContainer
@onready var scene_subviewport = $SubViewportContainer/SubViewport
@onready var screen_camera = $ScreenSubViewport/Camera3D


const input_manager_scene := preload("res://GameManagement/input_manager.gd")
const ui_manager_scene := preload("res://GameManagement/ui_manager.tscn")
const time_manager_scene := preload("res://GameManagement/time_manager.gd")

func _ready():
	#print("scene config ready")
	if not Engine.is_editor_hint():
		if input_manager:
			var im: InputManager = input_manager_scene.new()
			add_child(im)
			#print("path ", im.get_path())
		if ui_manager:
			var uim: UI_Manager = ui_manager_scene.instantiate()
			add_child(uim)
			#print("path ", uim.get_path())
		if time_manager:
			var tm: TimeManager = time_manager_scene.new()
			add_child(tm)
			#print("path ", tm.get_path())
		if add_effects:
			move_scene_into_subviewport()
		else:
			scene_subviewport_container.visible = false
			for sibling: Node in get_parent().get_children():
				if sibling is Player and not player:
					player = sibling
			

func move_scene_into_subviewport():
	for sibling: Node in get_parent().get_children():
		if sibling != self and not exclusion_list.has(sibling):
			sibling.reparent.call_deferred(scene_subviewport)
		if sibling is Player and not player:
			player = sibling

func _process(_delta):
	if player:
		screen_camera.global_transform = player.camera.global_transform
		screen_camera.fov = player.camera.fov
		screen_camera.near = player.camera.near
		screen_camera.far = player.camera.far
