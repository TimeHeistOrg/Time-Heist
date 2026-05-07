# computer.gd
extends Node3D
class_name Computer

@export var data: ComputerData
@onready var view_position: Marker3D = $ViewPosition

var player_camera: Camera3D
var original_transform: Transform3D
var original_fov: float
var is_viewing: bool = false
var tween: Tween
var computer_ui_instance: ComputerUI
var target_fov : float = 90

#func interact():
	#if not data:
		#push_warning("Computer has no ComputerData resource")
		#return
	##globals.ui_manager.desktop_viewer.display_computer(data)
	#desktop_viewer.display_computer(data)

@onready var sub_viewport: SubViewport = $Screen/SubViewport

const COMPUTER_UI = preload("res://Modules/Interaction/Computer/computer_ui.tscn")

func interact() -> void:
	if is_viewing:
		return
	original_transform = globals.player_camera.global_transform
	original_fov = globals.player_camera.fov
	lerp_camera_to_screen()

func lerp_camera_to_screen() -> void:
	is_viewing = true
	#globals.player.disable_input()
	globals.ui_manager.desktop_viewer.display_computer_on_model(self, sub_viewport, data)
	
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
		print(sub_viewport.get_child_count())
		if sub_viewport.get_child_count() != 0:
			sub_viewport.get_child(0).queue_free()
	)

#func handle_input(_delta) -> void:
	#if is_viewing:
		#if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("player_interact"):
			#print("COMPUTER HANDLED INPUT")
			#close_computer()
