extends TextureRect
class_name SecurityCameraFeed

func set_camera(camera : Camera3D):
	camera.reparent($SubViewport)
	texture.viewport_path = get_path_to($SubViewport)
