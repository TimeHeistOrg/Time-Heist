# computer.gd
extends Node3D
class_name Computer

@export var data: ComputerData
@onready var view_position: Marker3D = $ViewPosition
@onready var computer_ui: ComputerUI = %"Computer UI"
@onready var sub_viewport: SubViewport = $SubViewport
@onready var screen_mesh: MeshInstance3D = $Screen

var original_transform: Transform3D
var original_fov: float
var is_viewing: bool = false
var tween: Tween
var computer_ui_instance: ComputerUI
var target_fov : float = 90

const COMPUTER_UI = preload("res://Modules/Interaction/Computer/computer_ui.tscn")

func _ready() -> void:
	if data:
		computer_ui.load_computer(data)
	

func interact() -> void:
	if is_viewing:
		return
	globals.player.lock_camera()
	globals.player.visible = false
	screen_mesh.visible = true
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
		globals.player.camera,
		"global_transform",
		view_position.global_transform,
		0.6
	)
	tween.parallel().tween_property(
		globals.player.camera,
		"fov",
		target_fov,
		0.6
	)

func close_computer() -> void:
	if globals.player:
		globals.player.visible = true
		globals.player.return_camera(_on_computer_closed)

func _on_computer_closed():
	is_viewing = false
	screen_mesh.visible = false
