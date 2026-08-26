class_name InputManager extends Node

enum InputControllers {UI, GAMEPLAY, NONE}

var in_control = InputControllers.UI

var camera_sens_hor: float = 5

var roll_walk_timer: float = 0

const TAP_HOLD_THRESH:float = 0.2

var close_timer: Timer #for inventory wheel
var toggle_crouch: bool = true

func _ready():
	globals.input_manager = self
	change_input_controller(in_control)
	await get_tree().process_frame
	
	#for inventory wheel
	close_timer = Timer.new()
	close_timer.wait_time = 0.8
	close_timer.one_shot = true
	close_timer.timeout.connect(func(): globals.player.inventory_wheel.close())
	add_child(close_timer)

func change_input_controller(controller: InputControllers):
	if controller == in_control:
		return
	match in_control:
		InputControllers.UI:
			_leave_ui()
		InputControllers.GAMEPLAY:
			_leave_gameplay()
		InputControllers.NONE:
			pass
	match controller:
		InputControllers.UI:
			_switch_to_ui()
		InputControllers.GAMEPLAY:
			_switch_to_gameplay()
		InputControllers.NONE:
			_switch_to_none()

func _physics_process(delta):
	_process_universal(delta)
	match in_control:
		InputControllers.UI:
			_process_UI(delta)
		InputControllers.GAMEPLAY:
			_process_gameplay(delta)
		InputControllers.NONE:
			pass

func _input(event):
	_input_universal(event)
	match in_control:
		InputControllers.UI:
			_input_UI(event)
		InputControllers.GAMEPLAY:
			_input_gameplay(event)
		InputControllers.NONE:
			pass

#region universal
func _process_universal(_delta: float):
	if globals.time_manager:
		globals.time_manager.set_time_travelling(Input.is_action_pressed("rewind"))
		globals.time_manager.set_fast_forwarding(Input.is_action_pressed("wait") or Input.is_action_pressed("wait_faster"))
		if Input.is_action_pressed("wait_faster"): #Wait faster implementation is temporary, should be moved into debug ui
			globals.time_manager.WAIT_MULTIPLIER = globals.time_manager.WAIT_FASTER_MULTIPLIER
		else:
			globals.time_manager.WAIT_MULTIPLIER = 5

func _input_universal(_event: InputEvent):
	pass

#endregion

#region None
func _switch_to_none():
	in_control = InputControllers.NONE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#endregion

#region UI
func _switch_to_ui():
	in_control = InputControllers.UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _leave_ui():
	pass

func _input_UI(event: InputEvent):
	if globals.ui_manager:
		globals.ui_manager.cur_ui.handle_event(event)
	pass

func _process_UI(delta: float):
	#print(get_viewport().gui_get_hovered_control())
	if globals.ui_manager:
		globals.ui_manager.cur_ui.handle_input(delta)

#endregion

#region Gameplay
func _switch_to_gameplay():
	in_control = InputControllers.GAMEPLAY
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _leave_gameplay():
	globals.player.lost_input()
	if not toggle_crouch:
		globals.player.set_crouch(false)

func _input_gameplay(event: InputEvent):
	var player = globals.player
	if player and event is InputEventMouseMotion:
		player.pan_camera_horizontally(-deg_to_rad(event.screen_relative.x * (camera_sens_hor/100)))

func _process_gameplay(_delta: float):
	var player = globals.player
	if player:
		player.move(Input.get_vector("player_left","player_right","player_up","player_down"))
	#if Input.is_action_pressed("player_roll_walk"):
		#if roll_walk_timer < TAP_HOLD_THRESH:
			#roll_walk_timer += delta
		#else:
			#player.set_walk(true)
	#if Input.is_action_just_released("player_roll_walk"):
		#if roll_walk_timer < TAP_HOLD_THRESH:
			#player.roll()
		#else:
			#player.set_walk(false)
		#roll_walk_timer = 0
	if Input.is_action_just_pressed("player_roll_walk"):
		player.roll()
	if toggle_crouch:
		if Input.is_action_just_pressed("player_crouch"):
			player.toggle_crouch()
	else:
		if Input.is_action_just_pressed("player_crouch"):
			player.set_crouch(true)
		if Input.is_action_just_released("player_crouch"):
			player.set_crouch(false)
	if Input.is_action_just_pressed("player_interact"):
		player.interact()
	if Input.is_action_just_pressed("set_time_waypoint"):
		globals.time_manager.set_waypoint()
	if Input.is_action_just_pressed("rewind_to_waypoint"):
		globals.time_manager.rewind_to_waypoint()
	

	if Input.is_action_just_released("inventory_wheel_scroll_up"):
		player.inventory_wheel.scroll(1)
		keep_wheel_open()
	if Input.is_action_just_released("inventory_wheel_scroll_down"):
		player.inventory_wheel.scroll(-1)
		keep_wheel_open()
	if globals.ui_manager and Input.is_action_just_pressed("device_menu"):
		globals.ui_manager.device_menu.open()
		globals.ui_manager.get_node("ButtonMove").play()
		
	#if Input.is_action_just_pressed("escape"):
		#change_input_controller(InputControllers.UI)

func keep_wheel_open() -> void:
	globals.player.inventory_wheel.open()
	close_timer.stop()     #cancel a close
	close_timer.start()    #restart the countdown

#endregion
