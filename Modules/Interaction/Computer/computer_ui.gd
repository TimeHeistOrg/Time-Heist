extends UI
class_name ComputerUI

@onready var desktop: TextureRect = $Desktop
@onready var icons_container: Control = $Icons

const DESKTOP_ITEM = preload("res://Modules/Interaction/Computer/desktop_item.tscn")
const APP_WINDOW = preload("res://Modules/Interaction/Computer/app_window.tscn")

func load_computer(data: ComputerData) -> void:
	desktop.texture = data.desktop_image
	
	# clear any existing icons
	for child in icons_container.get_children():
		child.queue_free()
	
	for app in data.apps:
		# spawn desktop icon
		var item = DESKTOP_ITEM.instantiate()
		icons_container.add_child(item)
		item.setup(app, self)  # pass self so icon can ask us to open a window

func open_app(app: AppData) -> void:
	# spawn the draggable window
	var win = APP_WINDOW.instantiate()
	add_child(win)  # add to computer ui, not desktop, so it floats on top
	
	# instance the app content and hand it to the window
	var content = app.app_scene.instantiate() as AppBase
	
	if app.app_config and content.has_method("setup"):
		content.setup(app.app_config)
	
	win.setup(content)
	win.open_tab()
