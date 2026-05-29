extends Node

class_name TimeManager

var time_stack: Array[TimeDelta] = []
var cur_time: float = 0
var delta_time: float = 0

var logging: bool = false
var time_multiplier:float = 1

var night_start_hours: int = 1
var night_start_minutes: int = 49
var night_end: float = 300 #seconds / 5 mins

var REWIND_MULTIPLIER = -5
var WAIT_MULTIPLIER = 5
var WAIT_FASTER_MULTIPLIER = 15

var time_juice : float = 100
var max_time_juice : float = 100
var rewind_drain_per_sec : float = 15
var rewind_charge_per_sec : float = 40

var time_travelling: bool = false
var fast_forwarding: bool = false

func _ready():
	globals.time_manager = self
	logging = true
	start_time()

func _physics_process(delta):
	if time_travelling: #rewind
		time_multiplier = REWIND_MULTIPLIER
		rewind(delta * time_multiplier)
		time_juice = max(0, time_juice - delta * rewind_drain_per_sec)
	else:
		if fast_forwarding:
			time_multiplier = WAIT_MULTIPLIER
		else:
			time_multiplier = 1
		delta_time = delta * time_multiplier
		cur_time += delta_time
	
	if cur_time > 5 * 60:
		globals.player_caught()
		globals.ui_manager.caught_ui.label.text = "Out of time!"

func start_time():
	time_multiplier = 1

func stop_time():
	time_multiplier = 0

func set_fast_forwarding(value: bool):
	fast_forwarding = value
	if value:
		time_travelling = false

func set_time_travelling(value: bool):
	if value:
		if time_juice > 0:
			time_travelling = true
			fast_forwarding = false
		else:
			time_travelling = false
	else:
		time_travelling = value

func rewind(time_sec:float):
	delta_time = time_sec
	var goal_time = cur_time + delta_time
	if goal_time < 0:
		goal_time = 0
		delta_time = -cur_time
	
	logging = false
	while(not time_stack.is_empty() and time_stack.back().time_stamp > goal_time):
		cur_time = time_stack.back().time_stamp
		time_stack.pop_back().undo_delta()
	logging = true
	cur_time = goal_time

func timelog(_object: Node,_var_name:String, _old_value):
	var newDelta = TimeDelta.new()
	newDelta.object = _object
	newDelta.time_stamp = cur_time
	newDelta.var_name = _var_name
	newDelta.old_value = _old_value
	time_stack.append(newDelta)

class TimeDelta:
	var object: Object
	var time_stamp: float
	var var_name:String
	var old_value
	func undo_delta():
		object.set(var_name,old_value)
