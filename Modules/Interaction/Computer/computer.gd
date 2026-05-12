# computer.gd
extends Node3D
class_name Computer

@export var data: ComputerData
@onready var view_position: Marker3D = $ViewPosition
@onready var computer_ui: ComputerUI = %"Computer UI"
@onready var sub_viewport: SubViewport = $SubViewport

var player_camera: Camera3D
var original_transform: Transform3D
var original_fov: float
var is_viewing: bool = false
var tween: Tween
var computer_ui_instance: ComputerUI
var target_fov : float = 90

const COMPUTER_UI = preload("res://Modules/Interaction/Computer/computer_ui.tscn")

func interact() -> void:
	if is_viewing:
		return
	original_transform = globals.player_camera.global_transform
	original_fov = globals.player_camera.fov
	globals.player.lock_camera()
	computer_ui.open()
	lerp_camera_to_screen()
	#print("COMPUTER INTERACT")

func lerp_camera_to_screen() -> void:
	is_viewing = true
	
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		globals.player_camera,
		"global_transform",
		view_position.global_transform,
		0.6
	)
	tween.parallel().tween_property(
		globals.player_camera,
		"fov",
		target_fov,
		0.6
	)
	

func close_computer() -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		globals.player_camera,
		"global_transform",
		original_transform,
		0.6
	)
	tween.parallel().tween_property(
		globals.player_camera,
		"fov",
		original_fov,
		0.6
	)
	tween.tween_callback(func():
		is_viewing = false
		#globals.ui_manager.desktop_viewer.call_deffered("close")
		#print(sub_viewport.get_child_count())
		#if sub_viewport.get_child_count() != 0:
			#sub_viewport.get_child(0).queue_free()
		if globals.player:
			globals.player.unlock_camera()
	)

func handle_input(_delta) -> void:
	if is_viewing:
		if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("player_interact"):
			#print("COMPUTER HANDLED INPUT")
			close_computer()
			
# Used for checking if the mouse is inside the Area3D.
var is_mouse_inside = false
# The last processed input touch/mouse event. To calculate relative movement.
var last_event_pos2D = null
# The time of the last event in seconds since engine start.
var last_event_time: float = -1.0

@onready var node_viewport = %SubViewport
@onready var node_quad = $Screen
@onready var node_area = $Screen/Area3D

func _ready():
	computer_ui.load_computer(preload("res://Modules/UI/Game UI/Desktops/TestingNewComputer/test_computer.tres"))
	#node_area.mouse_entered.connect(_mouse_entered_area)
	#node_area.mouse_exited.connect(_mouse_exited_area)
	#node_area.input_event.connect(_mouse_input_event)

	# If the material is NOT set to use billboard settings, then avoid running billboard specific code
	#if node_quad.get_surface_override_material(0).billboard_mode == BaseMaterial3D.BillboardMode.BILLBOARD_DISABLED:
		#set_process(false)

#func _mouse_entered_area():
	#print("entered")
	#is_mouse_inside = true
#
#
#func _mouse_exited_area():
	#print("exit")
	#is_mouse_inside = false
#
#func _unhandled_input(event):
	## Check if the event is a non-mouse/non-touch event
	#for mouse_event in [InputEventMouseButton, InputEventMouseMotion, InputEventScreenDrag, InputEventScreenTouch]:
		#if is_instance_of(event, mouse_event):
			## If the event is a mouse/touch event, then we can ignore it here, because it will be
			## handled via Physics Picking.
			#return
	#node_viewport.push_input(event)
#
#
#func _mouse_input_event(_camera: Camera3D, event: InputEvent, event_position: Vector3, _normal: Vector3, _shape_idx: int):
	#print("input")
	## Get mesh size to detect edges and make conversions. This code only support PlaneMesh and QuadMesh.
	#var quad_mesh_size = node_quad.mesh.size
#
	## Event position in Area3D in world coordinate space.
	#var event_pos3D = event_position
#
	## Current time in seconds since engine start.
	#var now: float = Time.get_ticks_msec() / 1000.0
#
	## Convert position to a coordinate space relative to the Area3D node.
	## NOTE: affine_inverse accounts for the Area3D node's scale, rotation, and position in the scene!
	#event_pos3D = node_quad.global_transform.affine_inverse() * event_pos3D
#
	## TODO: Adapt to bilboard mode or avoid completely.
#
	#var event_pos2D: Vector2 = Vector2()
#
	#if is_mouse_inside:
		## Convert the relative event position from 3D to 2D.
		#event_pos2D = Vector2(event_pos3D.x, -event_pos3D.y)
#
		## Right now the event position's range is the following: (-quad_size/2) -> (quad_size/2)
		## We need to convert it into the following range: -0.5 -> 0.5
		#event_pos2D.x = event_pos2D.x / quad_mesh_size.x
		#event_pos2D.y = event_pos2D.y / quad_mesh_size.y
		## Then we need to convert it into the following range: 0 -> 1
		#event_pos2D.x += 0.5
		#event_pos2D.y += 0.5
#
		## Finally, we convert the position to the following range: 0 -> viewport.size
		#event_pos2D.x *= node_viewport.size.x
		#event_pos2D.y *= node_viewport.size.y
		## We need to do these conversions so the event's position is in the viewport's coordinate system.
#
	#elif last_event_pos2D != null:
		## Fall back to the last known event position.
		#event_pos2D = last_event_pos2D
#
	## Set the event's position and global position.
	#event.position = event_pos2D
	#if event is InputEventMouse:
		#event.global_position = event_pos2D
#
	## Calculate the relative event distance.
	#if event is InputEventMouseMotion or event is InputEventScreenDrag:
		## If there is not a stored previous position, then we'll assume there is no relative motion.
		#if last_event_pos2D == null:
			#event.relative = Vector2(0, 0)
		## If there is a stored previous position, then we'll calculate the relative position by subtracting
		## the previous position from the new position. This will give us the distance the event traveled from prev_pos.
		#else:
			#event.relative = event_pos2D - last_event_pos2D
			#event.velocity = event.relative / (now - last_event_time)
#
	## Update last_event_pos2D with the position we just calculated.
	#last_event_pos2D = event_pos2D
#
	## Update last_event_time to current time.
	#last_event_time = now
#
	## Finally, send the processed input event to the viewport.
	#node_viewport.push_input(event)
