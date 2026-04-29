extends Control
class_name UI_Manager

@onready var document_viewer = $DocumentViewer
@onready var desktop_viewer: DesktopViewer = $"Desktop Viewer"
@onready var debug_ui = $"DEBUG UI"
@export var debug_mode: bool = false
#@onready var camera_ui = $Camera
@onready var device_menu: DeviceMenu = $DeviceMenu
@onready var caught_ui = $CaughtUI
var ui_stack: Array[Control] = []
var cur_ui: Control = null


func _ready():
	globals.ui_manager = self
	set_menu(device_menu,false)
	set_menu(debug_ui,debug_mode)
	set_menu(document_viewer,false)
	set_menu(desktop_viewer,false)
	set_menu(caught_ui, false)

func take_control(ui: Control):
	if ui != debug_ui:
		InputManager.change_input_controller(InputManager.InputControllers.UI)
	if cur_ui:
		ui_stack.append(cur_ui)
		cur_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE #doesnt really do anything
	cur_ui = ui

func release_control():
	if not ui_stack.is_empty():
		cur_ui = ui_stack.pop_back()
		cur_ui.mouse_filter = Control.MOUSE_FILTER_STOP #doesnt really do anything
	else:
		cur_ui = null
		InputManager.change_input_controller(InputManager.InputControllers.GAMEPLAY)

func handle_input(_delta):
	#if Input.is_action_just_pressed("camera_ui"):
		#toggle_menu(camera_ui)
	if Input.is_action_just_pressed("debug_button"):
		toggle_menu(debug_ui)
	if Input.is_action_just_pressed("ui_paste"): #why is this in ui_manager?
		globals.toggle_debug_settings()
	if Input.is_action_just_pressed("ui_copy"):
		globals.toggle_lesser_debug_settings()

func toggle_menu(ui:UI):
	if not ui.is_open:
		ui.open()
	else:
		ui.close()
		
func set_menu(ui:UI,value:bool):
	if value:
		ui.open()
	else:
		ui.close()
	
