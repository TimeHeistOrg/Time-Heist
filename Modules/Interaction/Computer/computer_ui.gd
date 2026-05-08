extends UI
class_name ComputerUI

@onready var desktop: TextureRect = $Desktop
@onready var icons_container: Control = $Icons

const DESKTOP_ITEM = preload("res://Modules/Interaction/Computer/desktop_item.tscn")
const APP_WINDOW = preload("res://Modules/Interaction/Computer/app_window.tscn")

func _ready() -> void:
	close()

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

#func open_app(app: AppData) -> void:
	## spawn the draggable window
	#var win = APP_WINDOW.instantiate()
	#
	## instance the app content and hand it to the window
	#var content = app.app_scene.instantiate() as AppBase
	#
	#content.setup(app) #put app data into the tab
	#
	#add_child(win)  # add to computer ui, not desktop, so it floats on top
	#win.setup(content) #put tab into the window
	#win.open_tab()
	
var open_windows: Dictionary = {}  # AppData:AppWindow

func open_app(app: AppData) -> void:
	# if already open, just bring it to front
	if open_windows.has(app):
		open_windows[app].move_to_front()
		return
	
	var win = APP_WINDOW.instantiate()
	add_child(win)
	
	var content = app.app_scene.instantiate() as AppBase
	content.setup(app)
	
	win.setup(content)
	win.open_tab()
	open_windows[app] = win
	
	# clean up dictionary when window closes
	win.tree_exited.connect(func(): open_windows.erase(app))
