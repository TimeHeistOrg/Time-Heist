extends Control

class_name UI

var is_open : bool = true
@export var default_focus : Control
@export var disable_e_to_close: bool = false

func open():
	if is_open:
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_open = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	if globals.ui_manager:
		globals.ui_manager.take_control(self)
	if default_focus:
		default_focus.grab_focus()

func close():
	if not is_open:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_open = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if globals.ui_manager:
		globals.ui_manager.release_control()

func handle_input(_delta):
	if Input.is_action_just_pressed("escape") or (not disable_e_to_close and Input.is_action_just_pressed("player_interact")):
		close()
		
func handle_event(_event):
	pass
