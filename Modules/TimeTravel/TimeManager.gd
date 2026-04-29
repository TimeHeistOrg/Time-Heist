extends Node

class_name TimeManager

var time_stack: Array[TimeDelta] = []
var cur_time: float = 0
var delta_time: float = 0
var paused: bool = true
var logging: bool = false
var time_multiplier:float = 1

var night_start_hours: int = 1
var night_start_minutes: int = 49
var night_end: float = 300 #seconds / 5 mins

const FIXED_REWIND_VALUE = 15
const REWIND_MULTIPLIER = 5
const WAIT_MULTIPLIER = 5
const WAIT_FASTER_MULTIPLIER = 15

signal time_traveled
signal stopped_time_travel

var last_input_controller

var is_time_traveling = false:
	set(value):
		is_time_traveling = value
		if value:
			last_input_controller = globals.controller_of_input
			globals.controller_of_input = globals.InputController.TIMETRAVEL 
		else:
			globals.controller_of_input = last_input_controller

func _ready():
	globals.time_manager = self
	logging = true
	start_time()

func _physics_process(delta):
	if paused:
		return
	if Input.is_action_pressed("rewind") and globals.time_juice > 0.0:
		if globals.time_juice > 0.0 or not globals.player or globals.infinite_juice:
			rewind(REWIND_MULTIPLIER * delta)
			if not is_time_traveling:
				is_time_traveling = true
			if globals.player and not globals.infinite_juice: #DEBUG dont lose juice if debug mode
				globals.time_juice = maxf(0.0, globals.time_juice - globals.rewind_drain_per_sec * delta)
	else:
		if Input.is_action_pressed("wait"):
			delta_time = delta * WAIT_MULTIPLIER
		elif Input.is_action_pressed("wait_faster"):
			delta_time = delta * WAIT_FASTER_MULTIPLIER
		else:
			delta_time = delta
		if is_time_traveling:
			stopped_time_travel.emit()
			is_time_traveling = false
	cur_time += delta_time
	#print(cur_time)
	

func toggle_time():
	@warning_ignore("standalone_ternary")
	start_time() if paused else stop_time()

func start_time():
	paused = false

func stop_time():
	paused = true

func restart_time():
	paused = true
	time_stack.clear()
	cur_time = 0

func timelog(_object: Node,_var_name:String, _old_value, _new_value):
	var newDelta = TimeDelta.new()
	newDelta.object = _object
	newDelta.time_stamp = cur_time
	newDelta.var_name = _var_name
	newDelta.old_value = _old_value
	time_stack.append(newDelta)

func rewind(time_sec:float):
	delta_time = -time_sec
	var goal_time = cur_time + delta_time
	if goal_time < 0:
		goal_time = 0
		delta_time = -cur_time
	
	logging = false
	while(not time_stack.is_empty() and time_stack.back().time_stamp > goal_time):
		time_stack.pop_back().undo_delta()
	logging = true
	time_traveled.emit()

func start_fast_forward(multiplier: float):
	time_multiplier = multiplier

func stop_fast_forward():
	time_multiplier = 1

class TimeDelta:
	var object: Object
	var time_stamp: float
	var var_name:String
	var old_value
	func undo_delta():
		object.set(var_name,old_value)
