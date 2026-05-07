# computer.gd
extends Node3D
class_name Computer

@export var data: ComputerData
@onready var desktop_viewer: DesktopViewer = $"Screen/SubViewport/Desktop Viewer"
@onready var view_position: Marker3D = $ViewPosition

var player_camera: Camera3D
var original_transform: Transform3D
var original_fov: float
var is_viewing: bool = false
var tween: Tween
var computer_ui_instance: ComputerUI

#func interact():
	#if not data:
		#push_warning("Computer has no ComputerData resource")
		#return
	##globals.ui_manager.desktop_viewer.display_computer(data)
	#desktop_viewer.display_computer(data)

@onready var sub_viewport: SubViewport = $Screen/SubViewport

const COMPUTER_UI = preload("res://Modules/Interaction/Computer/computer_ui.tscn")

func _ready() -> void:
	# load the UI into the subviewport on ready, not on interact
	# so it's always running in the background
	computer_ui_instance = COMPUTER_UI.instantiate()
	sub_viewport.add_child(computer_ui_instance)
	computer_ui_instance.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if data:
		computer_ui_instance.load_computer(data)

func interact() -> void:
	if is_viewing:
		return
	original_transform = globals.player_camera.global_transform
	original_fov = globals.player_camera.fov
	lerp_camera_to_screen()

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
	globals.player_camera.fov = 100
	tween.tween_callback(func(): 
		desktop_viewer.display_computer(data)
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
	globals.player_camera.fov = original_fov
	tween.tween_callback(func():
		is_viewing = false
		globals.player.enable_input()
	)
