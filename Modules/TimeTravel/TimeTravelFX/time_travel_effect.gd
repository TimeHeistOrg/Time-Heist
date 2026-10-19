extends ColorRect

@export_group("Animation Settings")
@export var duration : float = 0.2
@export var intensity : float = 0.5
@export var intensity_pulse_amount: float = 0.02

#@export_group("Audio")
#@export var start_sfx : AudioStreamPlayer 
#@export var end_sfx : AudioStreamPlayer  

#var tween : Tween
#var is_active : bool = false

#func _ready() -> void:
#	globals.time_manager.time_traveled.connect(_play_anim)
#	globals.time_manager.stopped_time_travel.connect(_stop_animation)
	
@onready var time_travel_post_fx = preload("res://Modules/TimeTravel/TimeTravelFX/time_travel_post_fx.tres")
var tween : Tween

var active: bool = false

func _ready() -> void:
	visible = false
	_set_shader_radius(0.0)

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
	if is_active:
		return
		
	is_active = true
	visible = true
	
	if start_sfx and not start_sfx.playing:
		start_sfx.play()
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	var current_val = (material as ShaderMaterial).get_shader_parameter("intensity")
	
	tween.tween_method(_set_shader_radius, current_val, intensity, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_start_pulse)

func _start_pulse() -> void:
	if not is_active:
		return

	if tween:
		tween.kill()
		
	tween = create_tween().set_loops()
	tween.tween_method(_set_shader_radius, intensity, intensity - intensity_pulse_amount, 0.2).set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_set_shader_radius, intensity - intensity_pulse_amount, intensity, 0.2).set_ease(Tween.EASE_IN_OUT)

func _stop_animation() -> void:
	if not is_active:
		return
		
	is_active = false
	
#	if start_sfx:
#		start_sfx.stop()
#	if end_sfx:
#		end_sfx.play()

func _pulsate_effect() -> void:
	var new_tween : Tween = create_tween()
	new_tween.tween_method(_set_shader_radius, intensity, intensity - intensity_pulse_amount, 0.2)
	new_tween.tween_method(_set_shader_radius, intensity - intensity_pulse_amount, intensity, 0.2)
	await new_tween.finished
	
	if tween:
		tween.kill()
	
	tween = create_tween()
	
	var current_val = (material as ShaderMaterial).get_shader_parameter("intensity")
	tween.tween_method(_set_shader_radius, current_val, 0.0, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_callback(func(): visible = false)

func _set_shader_radius(value: float) -> void:
	(material as ShaderMaterial).set_shader_parameter('intensity', value)
