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

func interact():
	globals.ui_manager.document_viewer.display_document(document_info.document_id)
	globals.emit_signal("added_doc", document_info)
