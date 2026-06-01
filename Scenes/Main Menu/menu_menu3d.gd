extends Node3D

@onready var camera : Camera3D = %MainMenuCamera
@onready var marker_right: Marker3D = $SubViewportContainer/SubViewport/marker_right
@onready var marker_left: Marker3D = $SubViewportContainer/SubViewport/marker_left
@onready var marker_mid: Marker3D = $SubViewportContainer/SubViewport/marker_middle
@onready var animation_player: AnimationPlayer = $SubViewportContainer/SubViewport/titlescreenv3/AnimationPlayer
@onready var vignette_material: ShaderMaterial = $CanvasLayer2/ColorRect.material

var lerp_speed : float = 5.0
var chosen_marker : Marker3D

func _ready() -> void:
	$CanvasLayer/OriginalFocus.grab_focus()
	pass

func _on_play_pressed() -> void:
	tighten_vignette()
	dim_lights($SubViewportContainer/SubViewport/Lights.get_children())
	animation_player.play("mixamo_com_001")
	await animation_player.animation_finished
	globals.tutorial_start_point = 0
	SceneManager.change_scene_with_transition(SceneManager.Scene.TUTORIAL)
	pass

func dim_lights(lights: Array, duration: float = 0.5) -> void:
	var tween = create_tween()
	for light in lights:
		print(light)
		tween.parallel().tween_property(light, "light_energy", 0.0, duration)
	await tween.finished

func tighten_vignette(duration: float = 2.5) -> void:
	var tween = create_tween()
	tween.tween_method(
		func(value: float): vignette_material.set_shader_parameter("radius", value),
		vignette_material.get_shader_parameter("radius"),
		vignette_material.get_shader_parameter("radius") - 0.14,
		duration
	)
	await tween.finished

func _on_settings_pressed():
	pass # Replace with function body.

func _on_credits_pressed() -> void:
	pass # Replace with function body.

func _on_quit_pressed():
	get_tree().quit()

func _on_settings_focus_entered() -> void:
	chosen_marker = marker_left

func _on_play_focus_entered() -> void:
	chosen_marker = marker_mid

func _on_credits_focus_entered() -> void:
	chosen_marker = marker_right

func _process(delta: float) -> void:
	if camera and chosen_marker:
		camera.global_position = lerp(camera.global_position, chosen_marker.global_position, lerp_speed * delta)
		camera.rotation = lerp(camera.rotation, chosen_marker.rotation, lerp_speed * delta)
