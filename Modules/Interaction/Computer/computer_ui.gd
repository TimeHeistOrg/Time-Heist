extends UI
class_name ComputerUI

@onready var desktop: TextureRect = $Desktop
@onready var icons_container: Control = $Icons
@onready var computer: Computer = $"../.."

const DESKTOP_ITEM = preload("res://Modules/Interaction/Computer/desktop_item.tscn")
const APP_WINDOW = preload("res://Modules/Interaction/Computer/app_window.tscn")

static var desktop_size: Vector2 = Vector2(1920,1080) #unused

func _ready() -> void:
	node_area.mouse_entered.connect(_mouse_entered_area)
	node_area.mouse_exited.connect(_mouse_exited_area)
	node_area.input_event.connect(_mouse_input_event)
	close()

func open():
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#print("Hello computer opening")
	super.open()

func close():
	computer.close_computer()
	#print("Hello computer closing")
	super.close()

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
	
	var win: AppWindow = APP_WINDOW.instantiate()
	add_child(win)
	
	var content = app.app_scene.instantiate() as AppBase
	content.setup(app)
	
	win.setup(content)
	win.open_tab()
	open_windows[app] = win
	
	# clean up dictionary when window closes
	win.tree_exited.connect(func(): open_windows.erase(app))
			
# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

@onready var node_viewport = %SubViewport
@onready var node_quad = $"../../Screen"
@onready var node_area = $"../../Screen/Area3D"

	# If the material is NOT set to use billboard settings, then avoid running billboard specific code
	#if node_quad.get_surface_override_material(0).billboard_mode == BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED:
		#set_process(false)

func _mouse_entered_area():
	#print("entered")
	is_mouse_inside = true


func _mouse_exited_area():
	#print("exit")
	is_mouse_inside = false

func _unhandled_input(event):
	# Check if the event is a non-mouse/non-touch event
	for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		if is_instance_of(event, mouse_event):
			# If the event is a mouse/touch event, then we can ignore it here, because it will be
			# handled via Physics Picking.
			return
	#node_viewport.push_input(event)


func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	#print("input")
	# Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	var quad_mesh_size = node_quad.mesh.size

	# Event position in Area3D in world coordinate space.
	var event_pos3D = event_position

	# Current time in seconds since engine start.
	var now: float = Time.get_ticks_msec() / 1000.0

	# Convert position to a coordinate space relative to the Area3D node.
	# NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D

	# TODO: Adapt to bilboard mode or avoid completely.

	var event_pos2D: Vector2 = Vector2()

	if is_mouse_inside:
		# Convert the relative event position from 3D to 2D.
		event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)

		# Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		# We need to convert it into the following range: -0.5 -> 0.5
		event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		# Then we need to convert it into the following range: 0 -> 1
		event_pos2D.x += 0.5
		event_pos2D.y += 0.5

		# Finally, we convert the position to the following range: 0 -> viewport.size
		event_pos2D.x *= node_viewport.size.x
		event_pos2D.y *= node_viewport.size.y
		# We need to do these conversions so the event's position is in the viewport's coordinate system.

	elif last_event_pos2D != null:
		# Fall back to the last known event position.
		event_pos2D = last_event_pos2D

	# Set the event's position and global position.
	event.position = event_pos2D
	if event is InputEventMouse:
		event.global_position = event_pos2D

	# Calculate the relative event distance.
	if event is InputEventMouseMotion or event is InputEventScreenDrag:
		# If there is not a stored previous position, then we'll assume there is no relative motion.
		if last_event_pos2D == null:
			event.relative = Vector2(0, 0)
		# If there is a stored previous position, then we'll calculate the relative position by subtracting
		# the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		else:
			event.relative = event_pos2D - last_event_pos2D
			event.velocity = event.relative / (now - last_event_time)

	# Update last_event_pos2D with the position we just calculated.
	last_event_pos2D = event_pos2D

	# Update last_event_time to current time.
	last_event_time = now

	# Finally, send the processed input event to the viewport.
	node_viewport.push_input(event)
