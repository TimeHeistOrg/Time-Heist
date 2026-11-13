extends Node3D

@onready var camera: Camera3D = $Camera3D
@onready var document := $Document
@export var rotation_speed := 1.2
@export var camera_move_speed := 0.03
@export var rotation_smoothing := 15.0
@export var mouse_rotation_speed := 0.005
@export var mouse_pan_speed := 0.007
@export var mouse_zoom_speed := 0.3

var current_z: float
var target_rotation: Vector3
var target_position: Vector3 

#mouse states
var is_middle_held := false
var is_right_held := false

func _ready():
	target_rotation = document.rotation
	target_position = camera.position

func _input(event: InputEvent) -> void:
	#track button states
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			is_middle_held = event.pressed
		if event.button_index == MOUSE_BUTTON_RIGHT:
			is_right_held = event.pressed
		
		#scroll to zoom
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_position.z -= mouse_zoom_speed
			target_position.z = clamp(target_position.z, current_z - 2, current_z + 2)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_position.z += mouse_zoom_speed
			target_position.z = clamp(target_position.z, current_z - 2, current_z + 2)
	
	#mouse drag
	if event is InputEventMouseMotion:
		if is_middle_held:
			#rotate document
			target_rotation.y += event.relative.x * mouse_rotation_speed
			target_rotation.x += event.relative.y * mouse_rotation_speed
			target_rotation.y = clamp(target_rotation.y, deg_to_rad(-45), deg_to_rad(45))
			target_rotation.x = clamp(target_rotation.x, deg_to_rad(-45), deg_to_rad(45))
		
		if is_right_held:
			#pan camera
			target_position.x -= event.relative.x * mouse_pan_speed
			target_position.y += event.relative.y * mouse_pan_speed
			target_position.x = clamp(target_position.x, -1, 1)
			target_position.y = clamp(target_position.y, -1, 1)

func handle_input(delta):
	var input := Vector2.ZERO

	if Input.is_action_pressed("rotate_document_right"):
		input.x += 1
	if Input.is_action_pressed("rotate_document_left"):
		input.x -= 1
	if Input.is_action_pressed("rotate_document_down"):
		input.y += 1
	if Input.is_action_pressed("rotate_document_up"):
		input.y -= 1

	target_rotation.y += input.x * rotation_speed * delta
	target_rotation.x += input.y * rotation_speed * delta
	target_rotation.y = clamp(target_rotation.y, deg_to_rad(-45), deg_to_rad(45))
	target_rotation.x = clamp(target_rotation.x, deg_to_rad(-45), deg_to_rad(45))

	document.rotation = document.rotation.lerp(
		target_rotation,
		1.0 - exp(-rotation_smoothing * delta)
	)

func handle_fullscreen_input(delta):
	if Input.is_action_pressed("player_left"):
		target_position.x -= camera_move_speed
	if Input.is_action_pressed("player_right"):
		target_position.x += camera_move_speed
	target_position.x = clamp(target_position.x, -1, 1)
	if Input.is_action_pressed("player_up"):
		target_position.y += camera_move_speed
	if Input.is_action_pressed("player_down"):
		target_position.y -= camera_move_speed
	target_position.y = clamp(target_position.y, -1, 1)

	if Input.is_action_pressed("ui_document_zoom"):
		target_position.z -= camera_move_speed
	if Input.is_action_pressed("ui_dowcument_zoom_out"):
		target_position.z += camera_move_speed
	target_position.z = clamp(target_position.z, current_z - 2, current_z + 2)

	# smooth camera to target each frame
	camera.position = camera.position.lerp(target_position, 1.0 - exp(-rotation_smoothing * delta))

func reset_position():
	target_rotation = Vector3(0, 0, 0)
	fit_camera_to_document()
	target_position = Vector3(0, 0, current_z)
	camera.position = target_position

func set_document_texture(document_id: int):
	var document_to_view = document_database.get_document(document_id)
	document.texture = document_to_view.document_image
	fit_camera_to_document()
	target_position = Vector3(camera.position.x, camera.position.y, current_z)

func fit_camera_to_document() -> void:
	if not document.texture:
		return
	var tex_size = document.texture.get_size()
	var world_width = tex_size.x * document.pixel_size * document.scale.x
	var world_height = tex_size.y * document.pixel_size * document.scale.y

	var viewport = camera.get_viewport()
	var viewport_aspect = float(viewport.size.x) / float(viewport.size.y)
	var doc_aspect = world_width / world_height

	var fov_rad = deg_to_rad(camera.fov)

	var dist: float
	if doc_aspect > viewport_aspect:
		var half_width = world_width / 2.0
		dist = half_width / (tan(fov_rad / 2.0) * viewport_aspect)
	else:
		var half_height = world_height / 2.0
		dist = half_height / tan(fov_rad / 2.0)

	camera.position.z = dist
	current_z = dist
	target_position = camera.position
