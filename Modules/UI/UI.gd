extends Control

class_name UI

var is_open : bool = true
@export var default_focus : Control

func open():
	if is_open:
		return
	mouse_filter = Control.MOUSE_FILTER_STOP
	is_open = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	globals.ui_manager.take_control(self)
	if default_focus:
		default_focus.grab_focus()
	print(InputManager.in_control)

func close():
	if not is_open:
		return
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_open = false
	visible = false
	process_mode = Node.PROCESS_MODE_DISABLED
	globals.ui_manager.release_control()
	print(InputManager.in_control)

func handle_input(_delta):
	if Input.is_action_just_pressed("escape"):
		close()
