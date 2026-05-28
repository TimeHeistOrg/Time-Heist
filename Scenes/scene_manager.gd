extends Node

#@onready var scene_holder := $"../SceneHolder"
#@onready var current_scene := $"../SceneHolder/temp"
# since this is a global, need to assign these in _ready
var scene_holder: Node
var current_scene: Node

enum Scene {
	GAMEPLAY,
	HOMEBASE,
	MAIN_MENU,
	TUTORIAL
}
var scene_paths := {
	Scene.GAMEPLAY: preload("res://Scenes/Gameplay/Gameplay.tscn"),
	Scene.HOMEBASE: preload("res://Scenes/Homebase/Homebase.tscn"),
	Scene.MAIN_MENU: preload("res://Scenes/Main Menu/main_menu3.tscn"),
	Scene.TUTORIAL: preload("res://Scenes/Tutorial/Tutorial.tscn")
}

const START_SCENE := Scene.MAIN_MENU
const ROOT_SCENE_NAME := "TimeHeist"


func change_scene(s: Scene) -> void:
	# clear current scene if there
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	# instantiate designated scene and save ref
	call_deferred("_load_scene",scene_paths[s])

func change_scene_to_path(path: String):
	# clear current scene if there
	if current_scene:
		current_scene.queue_free()
		current_scene = null
	call_deferred("_load_scene",path)

func _load_scene(path: String):
	current_scene = load(path).instantiate()
	scene_holder.add_child(current_scene)

func reload_current_scene():
	change_scene_to_path(current_scene.scene_file_path)

func _ready() -> void:
	current_scene = get_tree().current_scene
	scene_holder = Node.new()
	scene_holder.name = "SceneHolder"
	add_child(scene_holder)
	current_scene.call_deferred("reparent",scene_holder)
