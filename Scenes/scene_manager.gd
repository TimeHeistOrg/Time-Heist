extends Node

#@onready var scene_holder := $"../SceneHolder"
#@onready var current_scene := $"../SceneHolder/temp"
# since this is a global, need to assign these in _ready
var scene_holder: Node
var current_scene: Node
var current_scene_type: Scene

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
		
	# instantiate designated scene and save ref
	globals.time_manager.restart_time()
	current_scene = scene_paths[s].instantiate()
	current_scene_type = s
	if scene_holder:
		scene_holder.add_child(current_scene)
		global_inventory.reset_items()
	
func _ready() -> void:
	if get_tree().current_scene.name == ROOT_SCENE_NAME:
		scene_holder = get_tree().current_scene.get_node("./SceneHolder")
		change_scene(START_SCENE)
	else:
		current_scene = get_tree().current_scene
		scene_holder = Node.new()
		scene_holder.name = "SceneHolder"
		add_child(scene_holder)
		await get_tree().process_frame
		get_tree().current_scene.reparent(scene_holder)
