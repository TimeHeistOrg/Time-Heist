class_name Globals extends Node

#Collision Layers:
#1: Player
#2: Interaction
#3: Floor
#4: Walls
#5: Collidable Interaction
#6: 
#7: 
#8:

#Vision Layers:
#6: Minimap stuff
#7: Lights

enum InputController {UI, GAMEPLAY, TIMETRAVEL}
var controller_of_input = InputController.GAMEPLAY

var time_manager: TimeManager
var ui_manager: UI_Manager

var player : Player

var camera : Node3D

#region DebugMode
var infinite_juice: bool = false

#endregion

#region Detection
var safe_ratio : float = 1
var gaurd_sight_line_angle : float = 130
var gaurd_sight_line_radius : float = 15
var gaurd_smaller_sight_line_radius : float = 1.5
var person_sight_line_angle : float = 360
var person_sight_line_radius : float = 3
var person_smaller_sight_line_radius : float = 0
#endregion

var time_juice : float = 100
var max_time_juice : float = 100
var rewind_drain_per_sec : float = 15
var rewind_charge_per_sec : float = 40

var allow_interact: bool = true

#var cameras : Array[SubViewport]

#var collected_documents: Array[DocumentInfo]
#func collect(doc : DocumentInfo):
	#if not doc in collected_documents:
		#collected_documents.append(doc)
		#emit_signal("added_doc", doc)
		
enum Clearances {
	Security,
	Lab,
	Upper_Office,
	Utility,
	Other
}

enum Device_Tabs {
	Files,
	Inventory,
	Settings
}

##region temporary test variables
#var player_has_keycard: bool = false
#var janitor_has_keycard: bool = false
#
##endregion

#region ui
var normal_cursor = preload("res://Assets/UI/Computer/Cursor_normal.png")
var clicking_cursor = preload("res://Assets/UI/Computer/Cursor_click.png")
#endregion

func _ready():
	time_manager = preload("res://Modules/TimeTravel/TimeManager.gd").new()
	time_manager.name = "TimeManager"
	add_child(time_manager)
	time_juice = 100

func player_caught():
	#print("caught!")
	if ui_manager:
		ui_manager.caught_ui.open()
		ui_manager.caught_ui.visible = true
		ui_manager.mouse_filter = Control.MOUSE_FILTER_STOP
	time_manager.stop_time()
	get_tree().paused = true

func to_homebase():
	#print("to homebase")
	SceneManager.change_scene(SceneManager.Scene.HOMEBASE)

func retry():
	#print("restart")
	time_juice = max_time_juice
	SceneManager.change_scene(SceneManager.current_scene_type)


#region Signals
@warning_ignore("unused_signal")
signal added_doc(doc : DocumentInfo)
@warning_ignore("unused_signal")
signal collect_item(item : PickupItem)
@warning_ignore("unused_signal")
signal remove_item(item : PickupItem)
@warning_ignore("unused_signal")
signal update_items #used to make items work with time
@warning_ignore("unused_signal")
signal collect_clearance(clearance : Clearances)
@warning_ignore("unused_signal")
signal use_item(item : PickupItem)
@warning_ignore("unused_signal")
signal new_in_device(value : bool, tab : Device_Tabs)
#endregion

#region Debug
func toggle_debug_settings():
	player.can_be_seen = not player.can_be_seen
	player.can_open_any_door = not player.can_open_any_door
	player.infinite_juice = not player.infinite_juice
	time_juice = max_time_juice
	player.set_collision_mask_value(4, not player.get_collision_mask_value(4))
func toggle_lesser_debug_settings():
	player.can_be_seen = not player.can_be_seen
#endregion
