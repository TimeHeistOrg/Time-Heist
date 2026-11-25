@tool
extends Node

enum Scene {
	GAMEPLAY,
	HOMEBASE,
	MAIN_MENU,
	TUTORIAL,
	TEST
}

var scene_paths := {
	Scene.GAMEPLAY: "res://Scenes/Gameplay/gameplay_scene.tscn",
	Scene.HOMEBASE: "res://Scenes/Homebase/homebase_scene.tscn",
	Scene.MAIN_MENU: "res://Scenes/Main Menu/main_menu_scene.tscn",
	Scene.TUTORIAL: "res://Scenes/Tutorial/tutorial_scene.tscn",
	Scene.TEST: "res://Scenes/test.tscn"
}

const START_SCENE := Scene.MAIN_MENU
const ROOT_SCENE_NAME := "TimeHeist"

#enum Manager {
	#INPUT_MANAGER,
	#UI_MANAGER,
	#TIME_MANAGER
#}
#
#var managers := {
	#Manager.INPUT_MANAGER: preload("res://GameManagement/input_manager.gd"),
	#Manager.UI_MANAGER: preload("res://GameManagement/ui_manager.tscn"),
	#Manager.TIME_MANAGER: preload("res://GameManagement/time_manager.gd")
#}

var managers: Array[GDScript] = [InputManager,UIManager,TimeManager]

# since this is a global, need to assign these in _ready
var current_scene: Node
var current_scene_path := ""
var sub_viewport_container: SubViewportContainer
var sub_viewport: SubViewport
var transition_animator: Node

var scene_transition := preload("res://Modules/UI/GameUI/scene_transition.tscn")


func _ready() -> void:
	print("ready!")
	if not Engine.is_editor_hint():
		sub_viewport_container = SubViewportContainer.new()
		add_child(sub_viewport_container)

		sub_viewport = SubViewport.new()
		sub_viewport_container.add_child(sub_viewport)

		transition_animator = scene_transition.instantiate()
		add_child(transition_animator)
		
		await get_tree().process_frame
		_get_run_scene()
		get_tree().root.print_tree_pretty()


func _get_run_scene() -> void:
	var run_scene := get_tree().current_scene
	if run_scene == null:
		push_warning("SceneManager: Run scene not found.")
		return
	
	var config := _find_scene_config(run_scene)
	if config == null:
		push_warning("SceneManager: No SceneConfig found in '%s'." % run_scene.name)
		return
	#print("config: ", config, " managers: ", config.managers)
	_setup_managers(run_scene, config)
	run_scene.reparent(sub_viewport)
	current_scene = run_scene
	current_scene_path = run_scene.scene_file_path


func _find_scene_config(root: Node) -> SceneConfig:
	var queue: Array[Node] = [root]
	while not queue.is_empty():
		var n: Node = queue.pop_front()
		if n is SceneConfig:
			return n
		queue.append_array(n.get_children())
	return null


func _setup_managers(root: Node, config: SceneConfig) -> void:
	#for manager in config.managers:
		#print(manager)
		#var new_manager: Node = managers[manager].new()
		#new_manager.name = Manager.keys()[manager].capitalize().replace(" ", "")
		#root.add_child(new_manager)
	pass


func change_scene(s: Scene, transition = null) -> void:
	if transition:
		await change_scene_to_path_with_transition(scene_paths[s])
	else:
		await change_scene_to_path(scene_paths[s])


func change_scene_to_path_with_transition(path: String) -> void:
	await transition_animator.fade_in()
	await change_scene_to_path(path)
	await transition_animator.fade_out()


func change_scene_to_path(path: String) -> void:
	global_inventory.reset_items()
	if current_scene:
		current_scene.queue_free()
		current_scene = null
		await get_tree().process_frame
	_load_scene(path)


func reload_current_scene() -> void:
	get_tree().paused = true
	if globals.time_manager:
		globals.time_manager.stop_time()
	await change_scene_to_path(current_scene_path)


func reload_current_scene_transition() -> void:
	get_tree().paused = true
	if globals.time_manager:
		globals.time_manager.stop_time()
	await transition_animator.fade_in()
	await change_scene_to_path(current_scene_path)
	await transition_animator.fade_out()


func quit_game() -> void:
	await transition_animator.fade_in()
	get_tree().quit()


func _load_scene(path: String) -> void:
	var root: Node = (load(path) as PackedScene).instantiate()
	var config := _find_scene_config(root)  # works before entering the tree
	if config:
		_setup_managers(root, config)       # managers exist before the scene's _ready
	else:
		push_warning("SceneManager: No SceneConfig found in '%s'." % path)
	sub_viewport.add_child(root)
	current_scene = root
	current_scene_path = path
	get_tree().paused = false
