extends Node3D
class_name LabelsFade

@export var fade_duration: float = 0.6

var labels: Array[Label3D] = []
var tween: Tween


func _ready() -> void:
	for child in get_children():
		if child is Label3D:
			labels.append(child)
	fade_out()


func fade_in() -> void:
	_fade(1.0)


func fade_out() -> void:
	_fade(0.0)


func _fade(target_alpha: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.set_parallel(true)

	for label in labels:
		var target_color := Color(label.modulate.r, label.modulate.g, label.modulate.b, target_alpha)
		tween.tween_property(label, "modulate", target_color, fade_duration)
