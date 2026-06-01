@tool
class_name PuzzlePanel extends Node3D

@export var puzzle: UI:
	set(value):
		if value:
			turn_on()
		else:
			turn_off()
		puzzle = value

var puzzle_ref: Node = null

const off_mat: Material = preload("res://Modules/Interaction/Puzzles/DisplayOffMaterial.tres")
const on_mat: Material = preload("res://Modules/Interaction/Puzzles/DisplayOnMaterial.tres")

@onready var mesh: MeshInstance3D = $KeyCardReader

var panel_on: bool : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"panel_on",panel_on)
		if is_node_ready():
			panel_on_setter(value)
		panel_on = value

# Called when the node enters the scene tree for the first time.
func _ready():
	if not Engine.is_editor_hint():
		panel_on_setter(panel_on)
		if puzzle:
			puzzle.close()
		else:
			print("no puzzle selected")

func open_puzzle():
	if puzzle:
		puzzle.open()
	else:
		print("no puzzle selected")

func turn_on():
	panel_on = true

func turn_off():
	panel_on = false

func panel_on_setter(value: bool):
	if value:
		mesh.set_surface_override_material(1,on_mat)
		if not Engine.is_editor_hint():
			$KeyCardReader/Interactable.enable()
	else:
		mesh.set_surface_override_material(1,off_mat)
		if not Engine.is_editor_hint():
			$KeyCardReader/Interactable.disable()
