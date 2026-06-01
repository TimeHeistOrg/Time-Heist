@tool
class_name SwingingDoor extends Door

var is_opening: bool = false
var is_closing: bool = false
var pos_z: bool = false

var user:Node3D = null
@export var anim_player: TimeAnimationPlayer

@export var flip_horizontal: bool = false:
	set(value):
		if value:
			rotation.y = PI
			position = Vector3(0.75,0,0)
		else:
			rotation.y = 0
			position = Vector3.ZERO
		flip_horizontal = value
@export var reverse_opened: bool = false:
	set(value):
		reverse_opened = value
		is_open_setter(is_open)


@export_group("Animations")
@export_subgroup("Open")
@export var opening_animation: Animation
@export var reverse_opening_animation: Animation
@export var opened_animation: Animation
@export var reverse_opened_animation: Animation
@export var open_swing_length: float
@export var open_start_buffer: float
@export_subgroup("Close")
@export var closing_animation: Animation
@export var reverse_closing_animation: Animation
@export var closed_animation: Animation
@export var close_swing_length: float
@export var close_start_buffer: float
@export_subgroup("Locked")
@export var locked_animation: Animation

# Called when the node enters the scene tree for the first time.
func _ready():
	super._ready()
	if anim_player.has_animation_library(""):
		anim_player.remove_animation_library("")
	var anim_lib = AnimationLibrary.new()
	anim_lib.add_animation("Opening",opening_animation)
	anim_lib.add_animation("ReverseOpening",reverse_opening_animation)
	anim_lib.add_animation("Opened",opened_animation)
	anim_lib.add_animation("ReverseOpened",reverse_opened_animation)
	anim_lib.add_animation("Closing",closing_animation)
	anim_lib.add_animation("ReverseClosing",reverse_closing_animation)
	anim_lib.add_animation("Closed",closed_animation)
	anim_lib.add_animation("Locked",locked_animation)
	anim_player.add_animation_library("",anim_lib)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func open():
	if is_closing:
		var open_progress: float = open_start_buffer + (open_swing_length - anim_player.cur_progress)
		if pos_z: #opens towards -z
			open_neg_z(open_progress)
		else:#opens towards +z
			open_pos_z(open_progress)
		play_creak_open(open_progress/open_swing_length)
	else:
		if not user or to_local(user.global_position).z > 0: #opens towarsd -z
			open_neg_z()
		else: #opens towards +z
			open_pos_z()
		play_open_sound()
		play_creak_open()
	user = null
	is_opening = true
	is_closing = false
	is_open = true

func close():
	if is_opening:
		var close_progress: float = close_start_buffer + (close_swing_length - anim_player.cur_progress)
		if pos_z: #closes towards -z
			close_neg_z(close_progress)
		else: #closes towards +z
			close_pos_z(close_progress)
		play_creak_close(close_progress/close_swing_length)
	else:
		if pos_z: #closes towards -z
			close_neg_z()
		else: #closes towards +z
			close_pos_z()
		play_creak_close()
	user = null
	is_closing = true
	is_opening = false
	is_open = false

func open_neg_z(progress:float = 0):
	anim_player.time_play("Opening",progress,animation_done)
	pos_z = false

func open_pos_z(progress:float = 0):
	anim_player.time_play("ReverseOpening",progress,animation_done)
	pos_z = true

func close_neg_z(progress:float = 0):
	anim_player.time_play("ReverseClosing",progress,animation_done)
	pos_z = false

func close_pos_z(progress:float = 0):
	anim_player.time_play("Closing",progress,animation_done)
	pos_z = true

func animation_done():
	is_opening = false
	if is_closing:
		is_closing = false
		play_close_sound()

func locked_door_behavior():
	if not is_closing:
		anim_player.time_play("Locked")
		play_shake_sound()
	#else: #This lets the door be opened while still closing even if its locked
		#open()

func is_open_setter(value:bool):
	if Engine.is_editor_hint():
		if value:
			if reverse_opened:
				if reverse_opened_animation:
					anim_player.play("ReverseOpened")
			else:
				if opened_animation:
					anim_player.play("Opened")
		else:
			if closed_animation:
				anim_player.play("Closed")

func interacted_by(_person: Variant):
	user = _person
	anon_interacted()

func is_locked_setter(value:bool):
	if value:
		play_lock_sound()
	else:
		play_unlock_sound()

func play_open_sound():
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("open sound")
		pass

func play_creak_open(_progress: float = 0): #proportion is how open the door is range of 0-1
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("creak open, progress: ", progress)
		pass

func play_creak_close(_progress: float = 0): #proportion is how closed the door is range of 0-1
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("creak close, progress: ", progress)
		pass

func play_close_sound():
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("close sound")
		pass

func play_shake_sound(): #this is the sound that plays if door is attempted to be opened while locked
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("shake sound")
		pass

func play_lock_sound():
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("lock sound")
		pass

func play_unlock_sound():
	if is_node_ready() and (not globals.time_manager or not globals.time_manager.time_travelling):
		#print("unlock sound")
		pass
