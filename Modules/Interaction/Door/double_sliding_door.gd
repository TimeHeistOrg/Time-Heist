@tool
class_name DoubleSlidingDoor
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

@export var anim_player: TimeAnimationPlayer

@export_group("Animations")
@export_subgroup("Open")
@export var opening_animation: Animation
@export var opened_animation: Animation
@export var open_swing_length: float
@export_subgroup("Close")
@export var closing_animation: Animation
@export var closed_animation: Animation
@export var close_swing_length: float

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("Opening",opening_animation)
	anim_lib.add_animation("Opened",opened_animation)
	anim_lib.add_animation("Closing",closing_animation)
	anim_lib.add_animation("Closed",closed_animation)
	anim_player.add_animation_library("",anim_lib)


func open():
	if is_open:
		return
	if is_closing:
		var open_progress: float = open_swing_length - anim_player.cur_progress
		open_animate(open_progress)
	else:
		open_animate()
	user = null
	is_opening = true
	is_closing = false
	is_open = true


func close():
	if not is_open:
		return
	if is_opening:
		var close_progress: float = close_swing_length - anim_player.cur_progress
		close_animate(close_progress)
	else:
		close_animate()
	user = null
	is_closing = true
	is_opening = false
	is_open = false


func open_animate(progress:float = 0):
	anim_player.time_play("Opening",progress,animation_done)


func close_animate(progress:float = 0):
	anim_player.time_play("Closing",progress,animation_done)


func animation_done():
	is_opening = false
	if is_closing:
		is_closing = false


func is_open_setter(value:bool):
	if Engine.is_editor_hint():
		if value:
			if opened_animation:
				anim_player.play("Opened")
		else:
			if closed_animation:
				anim_player.play("Closed")


func interacted_by(_person: Variant):
	user = _person
	anon_interacted()
	
func locked_door_behavior():
	pass
