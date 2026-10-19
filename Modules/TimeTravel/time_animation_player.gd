@tool
class_name TimeAnimationPlayer extends AnimationPlayer

var cur_action: TimeAnimationAction = null : #TIMEVAR
	set(value):
		if globals.time_manager.delta_time > 0:
			if cur_action:
				cur_action.progress = cur_progress
		if globals.time_manager.delta_time < 0:
			if value:
				cur_progress = value.progress
		if value:
			play(value.track)
			pause()
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"cur_action",cur_action)
		cur_action = value
var cur_progress: float = 0
var callback: Callable = Callable()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not Engine.is_editor_hint():
		if cur_action:
			if not globals.time_manager or globals.time_manager.delta_time > 0: #time travelling forward
				cur_progress += globals.time_manager.delta_time if globals.time_manager else delta
				if cur_progress >= current_animation_length:
					cur_progress = current_animation_length
					cur_action = null
					if callback.is_valid():
						callback.call()
				seek(cur_progress,true)
			elif globals.time_manager.delta_time < 0: #time travelling backward
				cur_progress += globals.time_manager.delta_time
				if cur_progress <= 0:
					cur_progress = 0
				seek(cur_progress,true)

func time_play(track: StringName, progress: float = 0, _callback: Callable = Callable()): #This is how to start an animation that will be tracked by time
	cur_action = TimeAnimationAction.new(track)
	cur_progress = progress
	callback = _callback

class TimeAnimationAction:
	var track: StringName
	var progress: float
	func _init(_track: StringName):
		track = _track
