extends Node3D
class_name KeycardScanner

@onready var indicator: MeshInstance3D = $Card_reader/Indicator

@export var lock : Lockable = null

signal keycard_scanned


var feedback_timer : Timer
var default_color : Color = Color(0.081, 0.081, 0.081, 1.0)

func _ready() -> void:
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_end)
	add_child(feedback_timer)
	indicator.mesh.material.albedo_color = default_color

func interact():
	if lock and not lock.try_unlock():
		show_feedback(globals.red_color)
		return
		
	keycard_scanned.emit()
	show_feedback(globals.green_color)
			
func show_feedback(color: Color) -> void:
	indicator.mesh.material.albedo_color = color
	feedback_timer.stop()
	feedback_timer.start(2.0)

func _on_feedback_end() -> void:
	indicator.mesh.material.albedo_color = default_color
