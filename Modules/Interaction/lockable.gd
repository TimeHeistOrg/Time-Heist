extends Node
class_name Lockable

@onready var label: Label = $Label

var display_note: bool = false
var display_time_elapsed: float = 0
@export var needed_item: Array[PickupItem]
@export var consume_items: bool = false
@export var needed_clearance: Array[globals.Clearances]
@export var needed_doc: Array[DocumentInfo]
@export var needed_lever: Array[Lever]
@export var locked_label : String = "Locked!"

@export var perma_unlock: bool = false
var unlocked_once: bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"unlocked_once",unlocked_once,value)
		unlocked_once = value

var feedback_timer : Timer

func _ready() -> void:
	#feedback_timer = Timer.new()
	#feedback_timer.one_shot = true
	#feedback_timer.timeout.connect(_on_feedback_end)
	#add_child(feedback_timer)
	label.text = locked_label

func try_unlock():
	var unlocked = check_interact()
	
	if unlocked or (perma_unlock and unlocked_once):
		succ_unlock()
		return true
	else:
		fail_unlock()
		return false
		
func fail_unlock():
	print("failed unlock")
	globals.ui_manager.display_message(locked_label)
	#display_note = true
	#label.visible = true

func succ_unlock():
	unlocked_once = true
	

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
			if lever.flipped:
				success= false
	return success

#func _process(delta):
	#if display_note:
		#if display_time_elapsed >= 2:
			#display_note = false
			#display_time_elapsed = 0
			#label.visible = false
		#else:
			#display_time_elapsed += delta
