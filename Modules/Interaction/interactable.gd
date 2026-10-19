@tool
extends Area3D
class_name Interactable
## Interactable Class
##
## Added to objects that are interactable.
## [member meshes] stores meshes to apply outline to

## Sigal emitted when someone interacts. Includes [param interactor]
signal interacted_by(interactor: Variant)
## Sigal emitted when anyone interacts. Kept anonymous
signal anon_interacted

static var outline_material:ShaderMaterial = preload("res://Assets/Materials/Interactable/interactable_outline.tres")
static var highlight_material:ShaderMaterial = preload("res://Assets/Materials/Interactable/interactable_highlight.tres")
static var invalid_outline_material:StandardMaterial3D = preload("res://Assets/Materials/Interactable/Invalid_Highlight.tres")

## All array members gain outlines
@export var meshes: Array[GeometryInstance3D] = []

@export_category("Action Prompt Exports")
## Icon of [member action_prompt]
@export var icon : Texture:
	set(value):
		icon = value
		if Engine.is_editor_hint() and action_prompt:
			action_prompt.set_icon(icon)
## Prompt text of [member action_prompt]
@export var prompt_text : String:
	set(value):
		prompt_text = value
		if Engine.is_editor_hint() and action_prompt:
			action_prompt.set_prompt(prompt_text)
## Positional offset of [member action_prompt]
@export var positional_offset : Vector3:
	set(value):
		positional_offset = value
		if Engine.is_editor_hint() and action_prompt:
			action_prompt.set_offset(positional_offset)

## [code]true[/code] when invalid animation is playing
var playing_invalid_animation: bool = false
## Stores info about invalid interaction
## [blink duration, blink timer, number of blinks, cur_blink, is highlighted]
var invalid_animation_info: Array = [0.2,0,3,0,false]

## [code]true[/code] if interactor is currently being targetted
var is_targetted: bool = false
## Flag stated whether or not interaction is disabled
var disabled: bool = false:
	set(value):
		disabled = value
		if value:
			remove_outline()
			process_mode = Node.PROCESS_MODE_DISABLED
		else:
			add_outline()
			process_mode = Node.PROCESS_MODE_INHERIT

@onready var action_prompt: ActionPrompt = %ActionPrompt

## Gives [member meshes]'s members [member outline_material]
func _ready():
	if action_prompt:
		action_prompt.set_icon(icon)
		action_prompt.set_prompt(prompt_text)
		action_prompt.set_offset(positional_offset)
	if Engine.is_editor_hint():
		return
	if not disabled and not meshes.is_empty():
		for mesh:MeshInstance3D in meshes:
			mesh.material_overlay = outline_material


## Plays invalid interaction
func _process(delta):
	if Engine.is_editor_hint():
		return
	if playing_invalid_animation:
		_process_invalid_interaction(delta)


## Handles the playing of the invalid interaction animation
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


## Sets [member is_targetted] to true and updates outline
func targetted():
	is_targetted = true
	action_prompt.show_prompt()
	if not meshes.is_empty() and not playing_invalid_animation:
		highlight()


## Sets [member is_targetted] to false and updates outline
func untargetted():
	is_targetted = false
	action_prompt.hide_prompt()
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


func disable():
	disabled = true


func enable():
	disabled = false


func set_disabled(value: bool):
	disabled = value
