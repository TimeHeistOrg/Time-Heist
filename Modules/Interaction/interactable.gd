extends Area3D
class_name Interactable

@export var meshes: Array[GeometryInstance3D] = []
static var outline_material:ShaderMaterial = preload("res://Assets/Materials/Interactable/interactable_outline.tres")
static var highlight_material:ShaderMaterial = preload("res://Assets/Materials/Interactable/interactable_highlight.tres")
static var invalid_outline_material:StandardMaterial3D = preload("res://Assets/Materials/Interactable/Invalid_Highlight.tres")

var playing_invalid_animation: bool = false
var invalid_animation_info: Array = [0.2,0,3,0,false] #blink duration, blink timer, number of blinks, cur_blink, is highlighted

var is_targetted: bool = false
var disabled: bool = false:
	set(value):
		disabled = value
		if value:
			remove_outline()
			process_mode = Node.PROCESS_MODE_DISABLED
		else:
			add_outline()
			process_mode = Node.PROCESS_MODE_INHERIT

signal interacted_by(interactor: Variant)
signal anon_interacted

func _ready():
	if not disabled and not meshes.is_empty():
		for mesh:MeshInstance3D in meshes:
			mesh.material_overlay = outline_material

func targetted():
	is_targetted = true
	if not meshes.is_empty() and not playing_invalid_animation:
		highlight()

func untargetted():
	is_targetted = false
	if not meshes.is_empty() and not playing_invalid_animation:
		remove_highlight()

func highlight():
	if disabled:
		return
	for mesh:MeshInstance3D in meshes:
			mesh.material_overlay = highlight_material

func remove_highlight():
	if disabled:
		return
	for mesh:MeshInstance3D in meshes:
		mesh.material_overlay = outline_material

func remove_outline():
	for mesh:MeshInstance3D in meshes:
		mesh.material_overlay = null

func add_outline():
	if is_targetted:
		highlight()
	else:
		remove_highlight()

func interact(person:Node = null):
	interacted_by.emit(person)
	anon_interacted.emit()

func _process(delta):
	if playing_invalid_animation:
		_process_invalid_interaction(delta)

func _process_invalid_interaction(delta):
	if invalid_animation_info[3] == invalid_animation_info[2]: #Done blinking
		playing_invalid_animation = false
		invalid_animation_info[1] = 0
		invalid_animation_info[3] = 0
		if is_targetted:
			highlight()
		else:
			remove_highlight()
	elif invalid_animation_info[1] >= invalid_animation_info[0]: #timer is up, change state
		if invalid_animation_info[4]: #currently highlighted
			invalid_animation_info[4] = false
			invalid_animation_info[1] = 0
			invalid_animation_info[3] += 1
			for mesh:MeshInstance3D in meshes:
				mesh.material_overlay = null
		else: #currently not highlighted
			invalid_animation_info[4] = true
			invalid_animation_info[1] = 0
			for mesh:MeshInstance3D in meshes:
				mesh.material_overlay = invalid_outline_material
	else:
		invalid_animation_info[1] += delta

func disable():
	disabled = true

func enable():
	disabled = false

func set_disabled(value: bool):
	disabled = value
