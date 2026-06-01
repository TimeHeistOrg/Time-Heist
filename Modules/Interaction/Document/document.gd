@tool
extends Node3D

class_name Document

@export var document_info: DocumentInfo
@export var max_size: float = 1.0  # max width or height in world units

@export var texture: Texture2D = null:
	set(value):
		texture = value
		if not is_node_ready():
			await ready
		$Sprite3D.texture = value
		if value:
			fit_sprite_to_texture(value)
			
var is_visible: bool = true: #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_visible",is_visible)
		is_visible = value
		if value:
			show()
			process_mode = Node.PROCESS_MODE_INHERIT
		else:
			hide()
			process_mode = Node.PROCESS_MODE_DISABLED
@export var start_invisible: bool = false

func fit_sprite_to_texture(tex: Texture2D) -> void:
	var tex_size = tex.get_size()
	var aspect = tex_size.x / tex_size.y
	
	# figure out scale to fit within max_size
	var scale_factor: float
	if aspect >= 1.0:
		# wider than tall — clamp by width
		scale_factor = max_size / tex_size.x
	else:
		# taller than wide — clamp by height
		scale_factor = max_size / tex_size.y
	
	$Sprite3D.pixel_size = scale_factor

func _ready() -> void:
	if start_invisible:
		is_visible = false

func interact():
	globals.ui_manager.document_viewer.display_document(document_info.document_id)
	globals.emit_signal("added_doc", document_info)
