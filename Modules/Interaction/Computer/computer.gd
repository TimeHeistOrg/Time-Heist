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

func _ready() -> void:
	computer_ui.load_computer(preload("res://Modules/UI/Game UI/Desktops/TestingNewComputer/test_computer.tres"))

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
