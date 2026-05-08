extends Control
class_name AppBase

var default_focus : Control

func open_process():
	if default_focus:
		default_focus.grab_focus()
