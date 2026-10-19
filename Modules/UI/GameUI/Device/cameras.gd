extends MenuTabPanel
class_name CamerasPanel

@onready var grid := $GridContainer

func _ready() -> void:
	if not globals.cameras.is_empty():
		for camera : SubViewport in get_tree().get_current_scene().cameras:
			var camera_view = TextureRect.new()
			camera_view.custom_minimum_size = Vector2(640,360)
			camera_view.expand_mode = TextureRect.EXPAND_FIT_WIDTH
			camera_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
			var viewport_texture = ViewportTexture.new()
			print(camera.get_texture())
			viewport_texture = camera.get_texture()
			camera_view.texture = viewport_texture
			grid.add_child(camera_view)
	pass # Replace with function body.
