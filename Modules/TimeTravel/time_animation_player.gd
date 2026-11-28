@tool
class_name TimeAnimationPlayer extends AnimationPlayer

var cur_action: TimeAnimationAction = null : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint() and globals.time_manager:
			if globals.time_manager.logging:
				cur_action.progress = current_animation_position
				globals.time_manager.timelog(self,"cur_action",cur_action)
			cur_action = value
			play(value.track,-1,value.speed)
			seek(value.progress)
		#if value:
			#play(value.track, -1, cur_speed)
			#pause()
		#if globals.time_manager.delta_time > 0:
			#if cur_action:
				#cur_action.progress = cur_progress
		#if globals.time_manager.delta_time < 0:
			#if value:
				#cur_progress = value.progress
		#
		#if not Engine.is_editor_hint() and globals.time_manager and globals.time_manager.logging:
			#globals.time_manager.timelog(self,"cur_action",cur_action)
		#cur_action = value
var cur_progress: float = 0
var cur_speed: float = 1

func _ready() -> void:
	pass


## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
	#if not Engine.is_editor_hint():
		#if cur_action:
			#if not globals.time_manager or globals.time_manager.delta_time > 0: #time travelling forward
				#cur_progress += globals.time_manager.delta_time if globals.time_manager else delta
				#if cur_progress >= current_animation_length:
					#cur_progress = current_animation_length
					#cur_action = null
				#seek(cur_progress,true)
			#elif globals.time_manager.delta_time < 0: #time travelling backward
				#cur_progress += globals.time_manager.delta_time
				#if cur_progress <= 0:
					#cur_progress = 0
				#seek(cur_progress,true)


## Starts an animation that will be tracked by time manager.
func time_play(name: StringName = &"", custom_blend: float = -1, custom_speed: float = 1.0, from_end: bool = false, progress: float = 0, speed: float = 1):
	cur_action = TimeAnimationAction.new(name, progress, speed)

class TimeAnimationAction:
	var track: StringName
	var progress: float
	var speed: float
	func _init(_track: StringName, _progress: float = 0, _speed = 1):
		track = _track
		progress = _progress
		speed = speed
