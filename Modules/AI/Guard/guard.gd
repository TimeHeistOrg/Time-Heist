@tool
class_name Guard extends PathFollower
## Guard class
##
## State machine: NORMAL -> SEEN -> ALERT -> CAUGHT
## NORMAL: follows its path.
## SEEN: player is in line of sight and the guard stops and tracks them.
##      Becomes ALERT after "alert_time" of continuous sight.
## ALERT: guard lasers the player. Catches them after "caught_time"
## SEARCH: entered from SEEN/ALERT any time line of sight is lost (or from
##      NORMAL when another guard's alert broadcast reaches this guard)
##      Oscillates around the last known position
##
## Guards in SEEN/ALERT/SEARCH share their state with nearby guards via an
## AlertGroup (see below) with a shared timer. The whole group will return
## to NORMAL together. This time only decreases if no guard in the group
## has line of sight. Once no one has vision for "search_time" return ot NORMAL
##
## Waypoint/rewind support: everything that matters for restoring a guard to
## a past moment is stored as a TIMESTAMP (a cur_time value marking when
## something last happened), not as a per-frame accumulator. Durations like
## "how long has the player been seen" are always derived on demand as
## `cur_time - some_timestamp`. Timestamps only change at real, infrequent
## transition moments, so they're cheap to log as TIMEVARs; the durations
## derived from them never need logging at all, and are automatically
## correct after any jump in cur_time (waypoint or otherwise).

# Guard Body Parts
@onready var robot: Node3D = %Robot
@onready var eye: MeshInstance3D = %Eye
@onready var torso: MeshInstance3D = %Torso
@onready var legs: MeshInstance3D = %Legs
@onready var tires: MeshInstance3D = %Tires
@onready var seen_sound: AudioStreamPlayer = %SeenSound

## Different states the Guard can be in
enum AlertStates {NORMAL, SEEN, ALERT, CAUGHT, SEARCH}

## Current state of the Guard (TIMEVAR)
var state = AlertStates.NORMAL: #TIMEVAR
	set(value):
		if value == state:
			return
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self, "state", state)
		var old_state = state
		state = value
		if not Engine.is_editor_hint():
			_exit_state(old_state)
			_enter_state(state)

## Flag for if player is seen in line of sight and in zone (TIMEVAR)
var player_seen: bool = false: #TIMEVAR
	set(value):
		if value == player_seen:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "player_seen", player_seen)
		if value:
			sight_started_at = time_manager.cur_time
		player_seen = value

## cur_time at which player_seen most recently became true (TIMEVAR)
## get_time_detecting() calculates how long has the player been continuously
## seen from this instead of accumulating it every frame.
var sight_started_at: float = 0.0: #TIMEVAR
	set(value):
		if value == sight_started_at:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "sight_started_at", sight_started_at)
		sight_started_at = value

@onready var detector: PlayerDetector = $PlayerDetector
@onready var laser: Laser = $Laser
## Time to detect the player before becoming Alert
@export var alert_time: float = 1
## Time to detect the player before catching them
@export var caught_time: float = 2
## How long a guard (or its whole alert group) searches without
## anyone having line of sight before giving up and returning to NORMAL
@export var search_time: float = 3

## Total cur_time this guard has spent off NORMAL
## accumulated from stretches that have already ended. TIMEVAR. Combined with
## left_normal_at, this is what lets normal_process resume path-following at
## exactly the right point after any cur_time jump.
var total_time_away_from_normal: float = 0.0: #TIMEVAR
	set(value):
		if value == total_time_away_from_normal:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "total_time_away_from_normal", total_time_away_from_normal)
		total_time_away_from_normal = value

## cur_time at which this guard most recently left NORMAL. Only meaningful
## while state != NORMAL. TIMEVAR.
var left_normal_at: float = 0.0: #TIMEVAR
	set(value):
		if value == left_normal_at:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "left_normal_at", left_normal_at)
		left_normal_at = value

var scan_angle: float = 0.0
## Speed at which a guard scans when SEARCHING
@export var scan_speed: float = 5
## Width of the angle the guard scans when SEARCHING (meters)
@export var scan_width: float = 3

## Guard torso material
var torso_material: StandardMaterial3D

## How fast the guard turns to look at or away from a target
@export var look_lerp_speed: float = 10.0

## Rotation while path-following (set by PathFollower.face() during NORMAL).
## SEEN/ALERT/SEARCH temporarily take over this rotation but remembers what it was.
## When we return to NORMAL we lerp back to this
## snapshot before letting path following drive rotation again.
## For visual smoothing
var path_facing_basis: Basis = Basis.IDENTITY
## Flag for when the guard is realigning with its path
var realigning_to_path: bool = false

## Radius within which this guard's SEEN/ALERT/SEARCH state is broadcast to
## other guards
@export var alert_radius: float = 10.0

## Last known position of the player (or position broadcasted by another guard)
## Used by looking_process when this guard doesn't have real line of sight of its own. (TIMEVAR)
var target_seen_position: Vector3 = Vector3.ZERO: #TIMEVAR
	set(value):
		if value == target_seen_position:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "target_seen_position", target_seen_position)
		target_seen_position = value

## Shared tracking with every other guard drawn into the same incident
## Is a TIMEVAR so guard knows what group is was apart of when.
## Set when a guard sees the player themselves or is dawn into one
## by another guard. Can only ever return to NORMAL when this group disbands
var alert_group: AlertGroup = null: #TIMEVAR
	set(value):
		if value == alert_group:
			return
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self, "alert_group", alert_group)
		alert_group = value

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		torso_material = torso.get_surface_override_material(0)
		add_to_group("guards")
		laser.stop_laser()


#region State Machine functions

func _enter_state(new_state: AlertStates) -> void:
	match new_state:
		AlertStates.NORMAL:
			_enter_normal()
		AlertStates.SEEN:
			_enter_seen()
		AlertStates.ALERT:
			_enter_alert()
		AlertStates.SEARCH:
			_enter_search()
		AlertStates.CAUGHT:
			_enter_caught()


func _exit_state(old_state: AlertStates) -> void:
	match old_state:
		AlertStates.NORMAL:
			_exit_normal()
		AlertStates.SEEN:
			_exit_seen()
		AlertStates.ALERT:
			_exit_alert()
		AlertStates.SEARCH:
			_exit_search()
		AlertStates.CAUGHT:
			_exit_caught()


func _enter_normal() -> void:
	torso_material.emission = Color("ff0000")
	torso_material.emission_energy_multiplier = 1
	# Only realigning if we are currently returning from another state
	realigning_to_path = not transform.basis.is_equal_approx(path_facing_basis)
	# Finalize the offline stretch we're leaving
	total_time_away_from_normal += (time_manager.cur_time - left_normal_at)


func _exit_normal() -> void:
	# Snapshot our current path-following rotation so we can return to it when back in NORMAL
	path_facing_basis = transform.basis
	left_normal_at = time_manager.cur_time


func _enter_seen() -> void:
	seen_sound.play()
	torso_material.emission = Color("ff0000")
	torso_material.emission_energy_multiplier = 3
	if not alert_group:
		AlertGroup.new(search_time, time_manager.cur_time).add(self)


func _exit_seen() -> void:
	pass


func _enter_alert() -> void:
	if not alert_group:
		AlertGroup.new(search_time, time_manager.cur_time).add(self)


func _exit_alert() -> void:
	# Losing sight during ALERT jumps straight to SEARCH 
	# caused by the detector's player_stopped_seen signal
	if laser.laser_on:
		laser.stop_laser()


func _enter_search() -> void:
	torso_material.emission = Color("ba7902")
	scan_angle = 0.0
	if not alert_group:
		AlertGroup.new(search_time, time_manager.cur_time).add(self)


func _exit_search() -> void:
	pass


func _enter_caught() -> void:
	pass


func _exit_caught() -> void:
	pass

#endregion
#region Per Frame Functions

func _process(_delta):
	if not Engine.is_editor_hint():
		match state:
			AlertStates.NORMAL:
				normal_process(_delta)
			AlertStates.SEEN:
				seen_process(_delta)
			AlertStates.ALERT:
				alert_process(_delta)
			AlertStates.SEARCH:
				search_process(_delta)


func normal_process(delta):
	if detector.player_spotted:
		state = AlertStates.SEEN
		return
		
	if realigning_to_path:
		var target_transform := Transform3D(path_facing_basis, transform.origin)
		transform = transform.interpolate_with(target_transform, look_lerp_speed * delta)
		if transform.basis.is_equal_approx(path_facing_basis):
			transform.basis = path_facing_basis
			realigning_to_path = false
			
	if not path_following:
		return
	# total time in NORMAL (I think?)
	var cur_time = time_manager.cur_time - total_time_away_from_normal + start_offset
	if cur_time < 0:
		return
	if path_following.loop:
		cur_time = fmod(cur_time, path_following.get_path_duration())
	if last_processed_time > cur_time: # moved backward in time
		path_following.revert(self, last_processed_time, cur_time)
	elif last_processed_time < cur_time: # moved forward in time
		path_following.progress(self, last_processed_time, cur_time)
	last_processed_time = cur_time


## How long the player has been continuously, really seen by THIS guard's own
## detector. Calculated from sight_started_at
func get_time_detecting() -> float:
	if not player_seen:
		return 0.0
	return clamp(time_manager.cur_time - sight_started_at, 0.0, caught_time)


func seen_process(delta):
	looking_process(delta)
	broadcast_alert()
	if alert_group:
		alert_group.tick(delta, time_manager.cur_time)
	if state != AlertStates.SEEN:
		return

	var detecting := get_time_detecting()
	globals.safe_ratio = min(globals.safe_ratio, (caught_time - detecting) / caught_time)
	if detecting >= alert_time:
		state = AlertStates.ALERT


func alert_process(delta):
	looking_process(delta)
	broadcast_alert()
	if alert_group:
		alert_group.tick(delta, time_manager.cur_time)
	if state != AlertStates.ALERT:
		return
		
	var detecting := get_time_detecting()
	globals.safe_ratio = min(globals.safe_ratio, (caught_time - detecting) / caught_time)
	if detecting >= caught_time:
		state = AlertStates.CAUGHT
		catch_player()
		return
		
	if detector.player_spotted:
		if not laser.laser_on:
			laser.start_laser()
			laser.set_target(globals.player.detection_point)
	else:
		if laser.laser_on:
			laser.stop_laser()


func search_process(delta):
	looking_process(delta)
	broadcast_alert()
	if alert_group:
		alert_group.tick(delta, time_manager.cur_time)

#endregion

## Called if the player walks into the Guard's hitbox. The player is instantly caught
func _on_npc_hitbox_body_entered(body: Node3D) -> void:
	if body == globals.player and not globals.player_invisible:
		state = AlertStates.CAUGHT
		catch_player()


## Tells the player that they are caught
func catch_player():
	globals.player_caught(self)


## The position this guard should look toward. 
## If player is currently seen -> its own detector's live seen_position
## Otherwise -> last real position it saw the player before losing sight
## (or a position reported by another guard's alert broadcast)
func get_target_seen_position() -> Vector3:
	if detector.player_spotted:
		return detector.seen_position
	return target_seen_position


## Called by another guard's broadcast_alert() when this guard is within its alert_radius
## Ignored if this guard is already part of any alert_group already.
## Otherwise joins the broadcasters group and enter SEARCH toward the reported position
func receive_alert(source_group: AlertGroup, seen_position: Vector3) -> void:
	if alert_group != null or state == AlertStates.CAUGHT:
		return
	source_group.add(self)
	target_seen_position = seen_position
	state = AlertStates.SEARCH


## Notifies nearby guards to join this guard's alert_group giving a position to look.
## Called every frame while SEEN, ALERT, or SEARCH, so a guard still in NORMAL picks
## up whatever incident a nearby guard is currently part of the moment it
## it enters the alert_radius.
# HACK: kinda gross to check every guard in the tree
func broadcast_alert() -> void:
	if not alert_group:
		AlertGroup.new(search_time, time_manager.cur_time).add(self)
	var target_position := get_target_seen_position()
	for other in get_tree().get_nodes_in_group("guards"):
		if other == self or not (other is Guard):
			continue
		if global_position.distance_to(other.global_position) <= alert_radius:
			other.receive_alert(alert_group, target_position)


## Rotates the whole entire Guard
func looking_process(delta):
	var target_position: Vector3
	match state:
		AlertStates.SEEN, AlertStates.ALERT:
			var seen_pos := get_target_seen_position()
			target_position = Vector3(seen_pos.x, global_position.y, seen_pos.z)
			
		AlertStates.SEARCH:
			# Oscillate left and right around the last known position
			scan_angle += delta * scan_speed
			var offset = sin(scan_angle) * scan_width
			var seen_pos := get_target_seen_position()
			
			var to_target = (seen_pos - global_position).normalized()
			var perp = to_target.cross(Vector3.UP).normalized()
			
			var base = Vector3(seen_pos.x, global_position.y, seen_pos.z)
			target_position = base + perp * offset
		_:
			return

	var target_transform: Transform3D = global_transform.looking_at(target_position, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, look_lerp_speed * delta)


## Catches signal when [var detector] sees the player. Sets state to SEEN
func _on_player_detector_player_seen(_player_position: Vector3) -> void:
	player_seen = true
	state = AlertStates.SEEN


## Catches signal when [var detector] stops seeing the player. Sets state to SEARCH
func _on_player_detector_player_stopped_seen(last_position: Vector3) -> void:
	player_seen = false
	target_seen_position = last_position
	state = AlertStates.SEARCH

## Class AlertGroup
## Guards sharing an incident track whether ANY member currently has real
## line of sight on the player. They disband the whole group back to NORMAL
## when no body has line of sight in "disband_time" seconds straight.
##
## Every field that affects the disband countdown is a rare-write TIMEVAR
## (changed only at real sight-transition edges, not every frame), and
## `members` is TIMEVAR too -- so a waypoint jump reconstructs exactly which
## guards were in this group and how far into its countdown it was.
class AlertGroup:
	## Members of the AlertGroup
	var members: Array[Guard] = []: #TIMEVAR
		set(value):
			if value == members:
				return
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self, "members", members.duplicate())
			members = value

	var disband_time: float

	## cur_time at which every member of this group most recently lost real
	## line of sight simultaneously (or time of the groups creation, if nobody has
	## lost it yet). (TIMEVAR)
	var lost_sight_at: float = 0.0: #TIMEVAR
		set(value):
			if value == lost_sight_at:
				return
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self, "lost_sight_at", lost_sight_at)
			lost_sight_at = value

	## Whether any member had real line of sight as of the last tick(). Edge
	## detector for lost_sight_at. TIMEVAR -- without this, the first tick()
	## after a waypoint jump could misdetect a false "just lost sight" edge
	## and wrongly reset an already-in-progress countdown.
	var had_sight: bool = true: #TIMEVAR
		set(value):
			if value == had_sight:
				return
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self, "had_sight", had_sight)
			had_sight = value

	## Real-engine-frame dedup so tick() only advances once per rendered
	## frame no matter how many members call it. Unrelated to game time, so
	## deliberately not a TIMEVAR -- it self-corrects every frame regardless.
	var _last_tick_frame: int = -1

	func _init(initial_disband_time: float, cur_time: float) -> void:
		disband_time = initial_disband_time
		lost_sight_at = cur_time

	func add(guard: Guard) -> void:
		if not members.has(guard):
			var new_members := members.duplicate()
			new_members.append(guard)
			members = new_members
			guard.alert_group = self

	func has_line_of_sight() -> bool:
		for m in members:
			if is_instance_valid(m) and m.detector.player_spotted:
				return true
		return false

	## Advances the shared disband countdown once per rendered frame no
	## matter how many members call this the same frame.
	func tick(delta: float, cur_time: float) -> void:
		var frame := Engine.get_process_frames()
		if frame == _last_tick_frame:
			return
		_last_tick_frame = frame

		var has_sight := has_line_of_sight()
		if has_sight:
			had_sight = true
		elif had_sight:
			lost_sight_at = cur_time
			had_sight = false

		if not has_sight and (cur_time - lost_sight_at) >= disband_time:
			disband()

	func disband() -> void:
		for m in members:
			if is_instance_valid(m):
				m.alert_group = null
				m.state = Guard.AlertStates.NORMAL
		members = []
