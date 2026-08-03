extends AnimationTree

@onready var npc_script: PathFollower = $".."

var last_processed_component: PathComponent
var time_scale: float = 0 #to adapt to time travel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if npc_script.cur_component != last_processed_component:
		last_processed_component = npc_script.cur_component
		if last_processed_component is PathLine:
			set("parameters/TimeScale/scale",npc_script.cur_component.speed)
			set("parameters/Transition/transition_request","Walking")
		elif last_processed_component is PathVertex:
			set("parameters/Transition/transition_request","Standing")
	
	#TODO make the animation scale with time travel, time_multiplier is not being used properly in time manager
	#if time_scale != globals.time_manager.time_multiplier:
		#pass
