@tool
extends Node3D
class_name Lever

@onready var animation_player: AnimationPlayer = $Lever2/AnimationPlayer
@onready var indicator: MeshInstance3D = $Lever2/Indicator
var on_color : Color = globals.green_color
var off_color : Color = globals.red_color

signal lever_flipped(flip: bool)

@export var flipped : bool = false : #TIMEVAR
	set(value):
		#print("set is_open to ", value)
		if not Engine.is_editor_hint():
			if lever_ready and globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"flipped",flipped,value)
			flipped = value
			
		elif animation_player:
			flipped = value
			if value:
				animation_player.play("Down")
				indicator.mesh.material.albedo_color = on_color
			else:
				animation_player.play("Up")
				indicator.mesh.material.albedo_color = off_color
				
@export var is_jammed : bool = false: #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			if lever_ready and globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_jammed",is_jammed,value)
		is_jammed = value
		
var cur_action: LeverTimeAction = null: #TIMEVAR
	set(value):
		if globals.time_manager.delta_time > 0:
			if cur_action:
				cur_action.end_progress = progress
		if globals.time_manager.delta_time < 0:
			if value:
				progress = value.end_progress
		if value:
			if value.flipping:
				animation_player.play("UpToDown")
				animation_player.pause()
			else:
				#print("set animation close")
				animation_player.play("DownToUp")
				animation_player.pause()
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"cur_action",cur_action,value)
		cur_action = value


var lever_ready: bool = false
var progress:float = 0
var lever_anim_length = 1.833
var finish_delay = 0.533

func _ready() -> void:
	if not Engine.is_editor_hint():
		if flipped:
			flip()
			indicator.mesh.material.albedo_color = on_color
		lever_ready = true
	
func _process(delta: float) -> void:
	if not Engine.is_editor_hint():
		
		if cur_action:
			if globals.time_manager.delta_time > 0: #time travelling forward
				progress += globals.time_manager.delta_time
				if progress >= animation_player.current_animation_length:
					progress = animation_player.current_animation_length
					#is_open = cur_action.opening
					cur_action = null
				animation_player.seek(progress,true)
			elif globals.time_manager.delta_time < 0: #time travelling backward
				progress += globals.time_manager.delta_time
				if progress <= 0:
					progress = 0
				animation_player.seek(progress,true)

func flip():
	if (not cur_action or not cur_action.flipping):
		if(not flipped or (cur_action and not cur_action.flipping)):
			var was_unflipping: bool = cur_action != null
			cur_action = LeverTimeAction.new(true)
			if was_unflipping:
				progress = (lever_anim_length - progress) - finish_delay
			else:
				progress = 0
			flipped = true
			indicator.mesh.material.albedo_color = on_color
			lever_flipped.emit(true)
			

func unflip():
	if (not cur_action or cur_action.flipping):
		if(flipped or (cur_action and cur_action.flipping)):
			var was_flipping: bool = cur_action != null
			cur_action = LeverTimeAction.new(false)
			if was_flipping:
				progress = (lever_anim_length - progress) - finish_delay
			else:
				progress = 0
			flipped = false
			indicator.mesh.material.albedo_color = off_color
			lever_flipped.emit(false)

func toggle_flip():
	if cur_action:
		@warning_ignore("standalone_ternary")
		unflip() if cur_action.flipping else flip()
	else:
		@warning_ignore("standalone_ternary")
		unflip() if flipped else flip()

func jam():
	is_jammed = true

func unjam():
	is_jammed = false

func toggle_jam():
	is_jammed = not is_jammed

func interact():
	#print("interact")
	if flipped:
		if is_jammed:
			animation_player.play("DownJammed")
		else:
			unflip()
	else:
		if is_jammed:
			animation_player.play("UpJammed")
		else:
			flip()

class LeverTimeAction:
	var flipping: bool
	var end_progress:float
	func _init(_flipping:bool):
		flipping = _flipping
