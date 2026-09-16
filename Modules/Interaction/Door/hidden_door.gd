@tool
class_name HiddenShelfDoor
extends Door

var is_opening: bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_opening",is_opening)
		is_opening = value

var is_closing: bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_closing",is_closing)
		is_closing = value

var user:Node3D = null

@export_enum("Left","Right") var open_direction : String = "Left":
	set(value):
		open_direction = value
		is_open_setter(is_open)

@export var anim_player: TimeAnimationPlayer

@export_group("Animations")
@export_subgroup("Open")
@export var left_opening_animation: Animation
@export var right_opening_animation: Animation
@export var left_opened_animation: Animation
@export var right_opened_animation: Animation
@export var open_swing_length: float
@export_subgroup("Close")
@export var left_closing_animation: Animation
@export var right_closing_animation: Animation
@export var closed_animation: Animation
@export var close_swing_length: float

@onready var door: Node3D = $Door

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("Left Opening",left_opening_animation)
	anim_lib.add_animation("Right Opening",right_opening_animation)
	anim_lib.add_animation("Left Opened",left_opened_animation)
	anim_lib.add_animation("Right Opened",right_opened_animation)
	anim_lib.add_animation("Left Closing",left_closing_animation)
	anim_lib.add_animation("Right Closing",right_closing_animation)
	anim_lib.add_animation("Closed",closed_animation)
	anim_player.add_animation_library("",anim_lib)


func open():
	if is_open:
		return
	if is_closing:
		var open_progress: float = open_swing_length - anim_player.cur_progress
		if open_direction == "Left":
			open_left(open_progress)
		else:
			open_right(open_progress)
	else:
		if open_direction == "Left":
			open_left()
		else:
			open_right()
	user = null
	is_opening = true
	is_closing = false
	is_open = true


func close():
	if not is_open:
		return
	if is_opening:
		var close_progress: float = close_swing_length - anim_player.cur_progress
		if open_direction == "Left":
			close_left(close_progress)
		else:
			close_right(close_progress)
	else:
		if open_direction == "Left":
			close_left()
		else:
			close_right()
	user = null
	is_closing = true
	is_opening = false
	is_open = false


func open_left(progress:float = 0):
	anim_player.time_play("Left Opening",progress,animation_done)


func open_right(progress:float = 0):
	anim_player.time_play("Right Opening",progress,animation_done)


func close_left(progress:float = 0):
	anim_player.time_play("Left Closing",progress,animation_done)


func close_right(progress:float = 0):
	anim_player.time_play("Right Closing",progress,animation_done)


func animation_done():
	is_opening = false
	if is_closing:
		is_closing = false


func is_open_setter(value:bool):
	if Engine.is_editor_hint():
		print(open_direction)
		if value:
			if open_direction == "Left":
				if left_opened_animation:
					anim_player.play("Left Opened")
			else:
				if right_opened_animation:
					anim_player.play("Right Opened")
		else:
			if closed_animation:
				anim_player.play("Closed")


func interacted_by(_person: Variant):
	user = _person
	anon_interacted()
	
func locked_door_behavior():
	pass
