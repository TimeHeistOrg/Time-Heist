@tool
class_name Guard extends NPC

#Seen at all -> Suspicious:
	#stops moving, tracks player, quesrtion mark
	#if player leaves sight, continues looking at last seen position & starts descalation timer
	#if player stays in sight (without leaving) goes to alert after alert_time
#alert:
	#exclamation, spread alert to other nearby guards (wait on this)
	#laser if still in sight

enum AlertStates {NORMAL, SUSPICIOUS, ALERT}

var state = AlertStates.NORMAL : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			print("setting state to: ", AlertStates.find_key(value))
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"state",state,value)
			_enter_state(value)
		state = value

var last_detecting_player: float = INF

var detecting_player: float = 0 : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			print("setting detecting player to: ", value)
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"detecting_player",detecting_player,value)
			if globals.time_manager.delta_time < 0:
				last_detecting_player = abs(detecting_player)
		detecting_player = value

@onready var detector: PlayerDetector = $PlayerDetector
@onready var laser: Laser = $Laser
@export var alert_time: float = 1
@export var caught_time: float = 2

var time_offset: float = 0
var time_detecting: float = 0

func _enter_state(new_state: AlertStates):
	match new_state:
		AlertStates.NORMAL:
			_enter_normal()
		AlertStates.SUSPICIOUS:
			_enter_sus()
		AlertStates.ALERT:
			_enter_alert()

func _process(_delta):
	if not Engine.is_editor_hint():
		if time_manager.delta_time > 0:
			if detector.player_spotted and detecting_player <= 0:
				detecting_player = time_manager.cur_time
			elif not detector.player_spotted and detecting_player >= 0:
				detecting_player = -time_manager.cur_time
		match state:
			AlertStates.NORMAL:
				normal_process()
			AlertStates.SUSPICIOUS:
				sus_process()
			AlertStates.ALERT:
				alert_process()

func normal_process():
	print("normal_process: delta_time: ", time_manager.delta_time, " time_offset: ", time_offset)
	if time_detecting > 0:
		time_offset -= time_detecting
		time_offset = max(0, time_offset)
		time_detecting = 0
	if detector.player_spotted:
		print("going to sus from normal")
		enter_sus()
		sus_process()
		return
	if not path_following:
		return
	var cur_time = max(time_manager.cur_time - time_offset, 0)
	if path_following.loop:
		cur_time = fmod(cur_time,path_following.get_path_duration())
	if last_processed_time > cur_time: # moved backward in time
		path_following.revert(self,last_processed_time,cur_time)
	elif last_processed_time < cur_time: # moved forward in time
		path_following.progress(self,last_processed_time,cur_time)
	last_processed_time = cur_time

func sus_process():
	print("sus_process")
	detecting_process()
	if time_detecting >= alert_time:
		enter_alert()
	if time_detecting == 0:
		enter_normal()

func alert_process():
	detecting_process()
	if time_detecting < alert_time:
		enter_sus()
	if time_detecting == caught_time:
		catch_player()
	if detector.player_spotted:
		if not laser.laser_on:
			laser.start_laser()
			laser.set_target(globals.player)
	else:
		if laser.laser_on:
			laser.stop_laser()

func detecting_process():
	print("detecting_process")
	if detecting_player > 0:
		if time_manager.delta_time < 0 and last_detecting_player - time_manager.cur_time < -time_manager.delta_time:
			print(1)
			time_detecting += time_manager.delta_time - (last_detecting_player - time_manager.cur_time)
			time_offset += time_manager.delta_time
		else:
			print(2)
			time_detecting += time_manager.delta_time
			time_offset += time_manager.delta_time
	elif detecting_player < 0:
		if time_manager.delta_time > 0 and time_detecting < time_manager.delta_time:
			print(3)
			time_offset -= time_detecting
			time_detecting = 0
			normal_process()
		else:
			print(4)
			time_detecting -= time_manager.delta_time
			time_offset += time_manager.delta_time
	time_detecting = clamp(time_detecting, 0, caught_time)
	time_offset = max(0, time_offset)
	globals.safe_ratio = min(globals.safe_ratio, (caught_time - time_detecting) / caught_time)
	print("time detecting: ", time_detecting, " delta_time: ", time_manager.delta_time, " time_offset: ", time_offset)
	print("cur_time: ",time_manager.cur_time, " detecting_player: ", detecting_player, " last_detecting_player: ", last_detecting_player)

func enter_normal():
	state = AlertStates.NORMAL
	_enter_state(AlertStates.NORMAL)

func _enter_normal():
	$torso.get_surface_override_material(0).emission = color

func enter_sus():
	state = AlertStates.SUSPICIOUS
	_enter_state(AlertStates.SUSPICIOUS)

func _enter_sus():
	$torso.get_surface_override_material(0).emission = Color(1.0, 0.0, 0.0, 1.0)

func enter_alert():
	state = AlertStates.ALERT
	_enter_state(AlertStates.ALERT)

func _enter_alert():
	pass

func _on_npc_hitbox_body_entered(body: Node3D) -> void:
	if body == globals.player and not globals.player_invisible:
		catch_player()

func catch_player():
	globals.player_caught()
	print("player caught!")
	pass
