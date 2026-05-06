extends Node3D
class_name KeycardScanner

@onready var indicator: MeshInstance3D = $Card_reader/Indicator

signal keycard_scanned
var display_note: bool = false
var display_time_elapsed: float = 0
@export var needed_item: Array[PickupItem]
@export var consume_items: bool = false
@export var needed_clearance: Array[globals.Clearances]
@export var needed_doc: Array[DocumentInfo]
@export var needed_lever: Array[Lever]
@export var locked_label : String

@export var perma_unlock: bool = false
var unlocked_once: bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"unlocked_once",unlocked_once,value)
		unlocked_once = value

var feedback_timer : Timer
var default_color : Color = Color(0.081, 0.081, 0.081, 1.0)

func _ready() -> void:
	feedback_timer = Timer.new()
	feedback_timer.one_shot = true
	feedback_timer.timeout.connect(_on_feedback_end)
	add_child(feedback_timer)
	indicator.mesh.material.albedo_color = default_color
	$Label.text = locked_label

func interact():
	var unlocked = check_interact()
	
	if unlocked or (perma_unlock and unlocked_once):
		unlocked_once = true
		keycard_scanned.emit()
		show_feedback(globals.green_color)
		return
	else:
		display_note = true
		$Label.visible = true
		show_feedback(globals.red_color)
		return

func check_interact():
	var success = true
	if needed_doc:
		for doc in needed_doc:
			if not global_inventory.has_doc(doc):
				success = false
	if needed_item:
		for item in needed_item:
			if not global_inventory.has_item(item):
				success = false
			elif consume_items:
				global_inventory.remove_item(item)
	if needed_clearance:
		for clearance in needed_clearance:
			if not global_inventory.has_clearance(clearance):
				success = false
	if needed_lever:
		for lever in needed_lever:
			if not lever.flipped:
				success= false
	return success

func _process(delta):
	if display_note:
		if display_time_elapsed >= 2:
			display_note = false
			display_time_elapsed = 0
			$Label.visible = false
		else:
			display_time_elapsed += delta
			
func show_feedback(color: Color) -> void:
	indicator.mesh.material.albedo_color = color
	feedback_timer.stop()
	feedback_timer.start(2.0)

func _on_feedback_end() -> void:
	indicator.mesh.material.albedo_color = default_color
