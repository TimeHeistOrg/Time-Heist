extends ColorRect

@export var duration : float = 0.2
var is_playing_effect = false
@export var subviewport_container : SubViewportContainer
@export var intensity : float = 0.5
@export var intensity_pulse_amount: float = 0.02

@onready var time_travel_post_fx = preload("res://Effects/time_travel_post_fx.tres")
var tween : Tween

var active: bool = false

func _ready() -> void:
	globals.time_manager.start_time_travel.connect(_play_anim)
	globals.time_manager.stop_time_travel.connect(_stop_animation)
	visible = false

func _process(_delta):
	if globals.time_manager:
		if globals.time_manager.time_travelling:
			if not active:
				_play_anim()
				active = true
		else:
			if active:
				_stop_animation()
				active = false

func _play_anim() -> void:
	if is_playing_effect:
		return
	is_playing_effect = true
	visible = true
	tween = create_tween()
	#var old_mat = null
	#if subviewport_container:
		#old_mat = subviewport_container.material
		#subviewport_container.material = time_travel_post_fx
	
	tween.tween_method(_set_shader_radius, 0.0, intensity, duration).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	
	while is_playing_effect:
		await _pulsate_effect()
	
	
	#if subviewport_container:
		#subviewport_container.material = old_mat
	
func _stop_animation() -> void:
	is_playing_effect = false
	tween.stop()
	var tween1 : Tween = create_tween()	
	tween1.tween_method(_set_shader_radius, intensity, 0.0, duration).set_ease(Tween.EASE_IN_OUT)
	await tween1.finished
	visible = false

	
func _pulsate_effect() -> void:
	var new_tween : Tween = create_tween()
	new_tween.tween_method(_set_shader_radius, intensity, intensity - intensity_pulse_amount, 0.2)
	new_tween.tween_method(_set_shader_radius, intensity - intensity_pulse_amount, intensity, 0.2)
	await new_tween.finished
	
func _set_shader_radius(value: float) -> void:
	var mat : ShaderMaterial = material
	mat.set_shader_parameter('intensity', value)
