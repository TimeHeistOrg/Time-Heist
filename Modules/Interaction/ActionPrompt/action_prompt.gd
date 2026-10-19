@tool
class_name ActionPrompt
extends Node3D
## Action Prompt class
##
## Prompt that pops up when hovering over interactables

@export var fade_duration : float = 0.15

var _tween : Tween

@onready var icon: Sprite3D = %Icon
@onready var prompt: Label3D = %Prompt

func _ready() -> void:
	icon.no_depth_test = true
	prompt.no_depth_test = true
	if Engine.is_editor_hint():
		return
	set_modulation(0)
	visible = false

func set_icon(icon_texture : Texture) -> void:
	icon.texture = icon_texture


func set_prompt(prompt_text : String) -> void:
	prompt.text = prompt_text


func set_offset(offset : Vector3) -> void:
	position = offset


func show_prompt():
	visible = true
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(set_modulation, get_current_alpha(), 1.0, fade_duration)


func hide_prompt():
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(set_modulation, get_current_alpha(), 0.0, fade_duration)
	_tween.chain().tween_callback(func(): visible = false)


func get_current_alpha() -> float:
	return icon.modulate.a


func set_modulation(alpha : float) -> void:
	icon.modulate.a = alpha
	prompt.modulate.a = alpha


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
