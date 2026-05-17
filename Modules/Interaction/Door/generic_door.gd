@tool
extends Node3D
class_name Generic_Door

@onready var collision_body: StaticBody3D = $"Door_Frame_with_Door_Animated_v2(Faster)/DoorHinge/Door/Door RB"
@onready var mesh: MeshInstance3D = $"Door_Frame_with_Door_Animated_v2(Faster)/DoorHinge/Door"
@onready var animation_player : AnimationPlayer = $"Door_Frame_with_Door_Animated_v2(Faster)/AnimationPlayer"

@export var is_open: bool = false : #TIMEVAR
	set(value):
		#print("set is_open to ", value)
		if not Engine.is_editor_hint():
			if door_ready and globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_open",is_open,value)
			is_open = value
			if collision_body:
				if value:
					collision_body.process_mode = Node.PROCESS_MODE_DISABLED
				else:
					collision_body.process_mode = Node.PROCESS_MODE_INHERIT
			
		elif animation_player:
			is_open = value
			if value:
				animation_player.play("DoorOpen")
			else:
				animation_player.play("DoorClosed")

@export var is_locked: bool = false : #TIMEVAR
	set(value):
		#print("set is_locked to ", value)
		if not Engine.is_editor_hint():
			if door_ready and globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_locked",is_locked,value)
			if value:
				print("here")
				$AudioStreamPlayer3D.play()
		is_locked = value

var cur_action: DoorTimeAction = null: #TIMEVAR
	set(value):
		#print("setting action at ", globals.time_manager.cur_time)
		if globals.time_manager.delta_time > 0:
			if cur_action:
				#print("recording end progress ", progress)
				cur_action.end_progress = progress
		if globals.time_manager.delta_time < 0:
			if value:
				#print("new progress", value.end_progress)
				progress = value.end_progress
		if value:
			if value.opening:
				#print("set animation open")
				animation_player.play("Door_Action_Open")
				animation_player.pause()
			else:
				#print("set animation close")
				animation_player.play("Door_Action_Close")
				animation_player.pause()
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"cur_action",cur_action,value)
		cur_action = value



var door_ready: bool = false
var progress:float = 0
var door_anim_length = 0.625
var knob_delay = 0.2

func _ready():
	if is_open:
		animation_player.play("DoorOpen")
		collision_body.process_mode = Node.PROCESS_MODE_DISABLED
	door_ready = true

func _process(_delta):
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

func open():
	#print("open")
	if (not cur_action or not cur_action.opening):
		if(not is_open or (cur_action and not cur_action.opening)):
			var was_closing: bool = cur_action != null
			cur_action = DoorTimeAction.new(true)
			if was_closing:
				progress = knob_delay + (door_anim_length - progress)
			else:
				progress = 0
			is_open = true

func close():
	if (not cur_action or cur_action.opening):
		if(is_open or (cur_action and cur_action.opening)):
			var was_opening: bool = cur_action != null
			cur_action = DoorTimeAction.new(false)
			if was_opening:
				progress = knob_delay + (door_anim_length - progress)
			else:
				progress = 0
			is_open = false

func toggle_open():
	if cur_action:
		@warning_ignore("standalone_ternary")
		close() if cur_action.opening else open()
	else:
		@warning_ignore("standalone_ternary")
		close() if is_open else open()

func lock():
	is_locked = true

func unlock():
	is_locked = false

func toggle_lock():
	is_locked = not is_locked
	
func set_lock_opposite(flipped : bool):
	if flipped:
		is_locked = false
	else:
		close()
		is_locked = true

func set_lock(flipped : bool):
	if flipped:
		close()
		is_locked = true
	else:
		is_locked = false
	
func unlock_open():
	unlock()
	open()

 #and not globals.player.can_open_any_door
func interact(person: Node):
	#print("interact")
	if person == globals.player:
		if is_open:
				close()
		else:
			if is_locked:
				animation_player.play("Door_Action_Locked")
			else:
				open()

class DoorTimeAction:
	var opening: bool
	var end_progress:float
	func _init(_opening:bool):
		opening = _opening
