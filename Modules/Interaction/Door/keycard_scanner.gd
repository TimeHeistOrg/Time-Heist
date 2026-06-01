extends Node3D
class_name KeycardScanner

@onready var indicator: MeshInstance3D = $Card_reader/Indicator
@export var perma_locked: bool = false

@export var lock : Lockable = null
@export var retrigger : float = 0.0 #seconds
var retrigger_timer: float = 0.0
var is_ready : bool = true : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_ready",is_ready)
		elif not value:
			retrigger_timer = retrigger
		is_ready = value

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
	if not is_ready:
		return
	if globals.player_unlock_everything:
		keycard_scanned.emit()
		show_feedback(globals.green_color)
		if retrigger > 0:
			is_ready = false
		return
	if (lock and not lock.try_unlock()) or perma_locked:
		show_feedback(globals.red_color)
		return
	
	keycard_scanned.emit()
	show_feedback(globals.green_color)
	if retrigger > 0:
		is_ready = false

func _physics_process(_delta: float) -> void:
	if not is_ready:
		retrigger_timer += globals.time_manager.delta_time
		if retrigger_timer >= retrigger:
			keycard_scanned.emit()
			retrigger_timer = 0
			is_ready = true
		
func show_feedback(color: Color) -> void:
	indicator.mesh.material.albedo_color = color
	feedback_timer.stop()
	feedback_timer.start(2.0)

func _on_feedback_end() -> void:
	indicator.mesh.material.albedo_color = default_color
