@tool
class_name Guard extends PathFollower
## Guard class
##
## Seen at all -> Suspicious:
	## stops moving, tracks player, question mark
	## if player leaves sight, continues looking at last seen position & starts descalation timer
	## if player stays in sight (without leaving) goes to alert after alert_time
## alert:
	## exclamation, spread alert to other nearby guards (wait on this)
	## laser if still in sight

# Gaurd Body Parts
@onready var robot: Node3D = %Robot
@onready var eye: MeshInstance3D = %Eye
@onready var torso: MeshInstance3D = %Torso
@onready var legs: MeshInstance3D = %Legs
@onready var tires: MeshInstance3D = %Tires
@onready var seen_sound: AudioStreamPlayer = %SeenSound

enum AlertStates {NORMAL, SUSPICIOUS, ALERT, CAUGHT}

var state = AlertStates.NORMAL : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			#print("setting state to: ", AlertStates.find_key(value))
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"state",state)
			_enter_state_visual(value)
		state = value

var last_detecting_player: float = INF

var detecting_player: float = 0 : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			#print("setting detecting player to: ", value)
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"detecting_player",detecting_player)
			if globals.time_manager.delta_time < 0:
				last_detecting_player = abs(detecting_player)
		detecting_player = value

@onready var detector: PlayerDetector = $PlayerDetector
@onready var laser: Laser = $Laser
@export var alert_time: float = 1
@export var caught_time: float = 2

var time_offset: float = 0
var time_detecting: float = 0

func _enter_state_visual(new_state: AlertStates):
	match new_state:
		AlertStates.NORMAL:
			torso.get_surface_override_material(0).emission_energy_multiplier = 1
		AlertStates.SUSPICIOUS:
			seen_sound.play()
			torso.get_surface_override_material(0).emission_energy_multiplier = 3
		AlertStates.ALERT:
			pass

func _process(_delta):
	if not Engine.is_editor_hint():
		if time_manager.delta_time > 0:
			if detector.player_spotted and detecting_player <= 0:
				detecting_player = time_manager.cur_time
			elif not detector.player_spotted and detecting_player >= 0:
				detecting_player = -time_manager.cur_time
		match state:
			AlertStates.NORMAL:
				normal_process(_delta)
			AlertStates.SUSPICIOUS:
				sus_process(_delta)
			AlertStates.ALERT:
				alert_process(_delta)

func normal_process(_delta):
	#print("normal_process: delta_time: ", time_manager.delta_time, " time_offset: ", time_offset)
	if time_detecting > 0:
		time_offset -= time_detecting
		time_offset = max(0, time_offset)
		time_detecting = 0
	if detector.player_spotted:
		#print("going to sus from normal")
		enter_sus()
		sus_process(_delta)
		return
	if not path_following:
		return
	var cur_time = time_manager.cur_time - time_offset + start_offset
	if cur_time < 0:
		return
	if path_following.loop:
		cur_time = fmod(cur_time,path_following.get_path_duration())
	if last_processed_time > cur_time: # moved backward in time
		path_following.revert(self,last_processed_time,cur_time)
	elif last_processed_time < cur_time: # moved forward in time
		path_following.progress(self,last_processed_time,cur_time)
	last_processed_time = cur_time

func sus_process(_delta):
	#print("sus_process")
	detecting_process(_delta)
	
	looking_process(_delta)
	## Look at player position / last known position
	#if detector.player_spotted:
		#$Robot.look_at(detector.seen_position)
		##rotate to look at player
	#else:
		#$Robot.look_at(detector.seen_position)
		##scan last seen area
	
	if time_detecting >= alert_time:
		enter_alert()
	if time_detecting == 0:
		enter_normal()

func alert_process(_delta):
	detecting_process(_delta)
	looking_process(_delta)
	if time_detecting < alert_time:
		enter_sus()
	if time_detecting == caught_time:
		enter_caught()
	if detector.player_spotted:
		if not laser.laser_on:
			laser.start_laser()
			laser.set_target(globals.player)
	else:
		if laser.laser_on:
			laser.stop_laser()

func detecting_process(_delta):
	#print("detecting_process")
	if detecting_player > 0:
		if time_manager.delta_time < 0 and last_detecting_player - time_manager.cur_time < -time_manager.delta_time:
			#print(1)
			time_detecting += time_manager.delta_time - (last_detecting_player - time_manager.cur_time)
			time_offset += time_manager.delta_time
		else:
			#print(2)
			time_detecting += time_manager.delta_time
			time_offset += time_manager.delta_time
	elif detecting_player < 0:
		if time_manager.delta_time > 0 and time_detecting < time_manager.delta_time:
			#print(3)
			time_offset -= time_detecting
			time_detecting = 0
			normal_process(_delta)
		else:
			#print(4)
			time_detecting -= time_manager.delta_time
			time_offset += time_manager.delta_time
	time_detecting = clamp(time_detecting, 0, caught_time)
	time_offset = max(0, time_offset)
	globals.safe_ratio = min(globals.safe_ratio, (caught_time - time_detecting) / caught_time)
	#print("time detecting: ", time_detecting, " delta_time: ", time_manager.delta_time, " time_offset: ", time_offset)
	#print("cur_time: ",time_manager.cur_time, " detecting_player: ", detecting_player, " last_detecting_player: ", last_detecting_player)


func enter_normal():
	state = AlertStates.NORMAL


func enter_sus():
	state = AlertStates.SUSPICIOUS


func enter_alert():
	state = AlertStates.ALERT


func enter_caught():
	state = AlertStates.CAUGHT
	catch_player()


## Called if the player walks into the Guard's hitbox. The player is instantly caught
func _on_npc_hitbox_body_entered(body: Node3D) -> void:
	if body == globals.player and not globals.player_invisible:
		enter_caught()


func catch_player():
	globals.player_caught(self)


func looking_process(delta):
	var target_position = Vector3(detector.seen_position.x,global_position.y,detector.seen_position.z)
	
	# TODO: right now this only moves the robot mesh for testing
	var target_transform = robot.global_transform.looking_at(target_position, Vector3.UP)
	robot.global_transform = robot.global_transform.interpolate_with(target_transform, 10 * delta)
	robot.rotate_y(sin(delta))
	
