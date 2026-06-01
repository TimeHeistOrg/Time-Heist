extends Node

#@onready var scene_holder := $"../SceneHolder"
#@onready var current_scene := $"../SceneHolder/temp"
# since this is a global, need to assign these in _ready
var scene_holder: Node
var current_scene: Node
var transition_animator: Node
var scene_transition := preload("res://Modules/UI/Game UI/scene_transition.tscn")

enum Scene {
	GAMEPLAY,
	HOMEBASE,
	MAIN_MENU,
	TUTORIAL
}
#enum Transition { For later use
	#FADE
#}
var scene_paths := {
	Scene.GAMEPLAY: "res://Scenes/Gameplay/Gameplay.tscn",
	Scene.HOMEBASE: "res://Scenes/Homebase/Homebase.tscn",
	Scene.MAIN_MENU: "res://Scenes/Main Menu/main_menu3.tscn",
	Scene.TUTORIAL: "res://Scenes/Tutorial/Tutorial.tscn"
}

const START_SCENE := Scene.MAIN_MENU
const ROOT_SCENE_NAME := "TimeHeist"


func change_scene(s: Scene) -> void:
	change_scene_to_path(scene_paths[s])

func change_scene_with_transition(s: Scene) -> void:
	change_scene_to_path_with_transition(scene_paths[s])

func change_scene_to_path_with_transition(path:String):
	await transition_animator.fade_in()
	change_scene_to_path(path)
	await transition_animator.fade_out()

func change_scene_to_path(path: String):
	# clear current scene if there
	if current_scene:
		scene_holder.call_deferred("remove_child",current_scene)
		current_scene.queue_free()
		current_scene = null
	call_deferred("_load_scene",path)

func _load_scene(path: String):
	current_scene = load(path).instantiate()
	scene_holder.add_child(current_scene)
	get_tree().paused = false

func reload_current_scene():
	get_tree().paused = true
	if globals.time_manager:
		globals.time_manager.stop_time()
	#print("reload normal")
	change_scene_to_path(current_scene.scene_file_path)

func reload_current_scene_transition():
	get_tree().paused = true
	if globals.time_manager:
		globals.time_manager.stop_time()
	#print("reload transition")
	await transition_animator.fade_in()
	change_scene_to_path(current_scene.scene_file_path)
	await transition_animator.fade_out()

func quit_game():
	await transition_animator.fade_in()
	get_tree().quit()

func _ready() -> void:
	current_scene = get_tree().current_scene
	#print(current_scene)
	#print(get_tree().current_scene)
	scene_holder = Node.new()
	scene_holder.name = "SceneHolder"
	add_child(scene_holder)
	current_scene.call_deferred("reparent",scene_holder)
	
	transition_animator = scene_transition.instantiate()
	add_child(transition_animator)
	
