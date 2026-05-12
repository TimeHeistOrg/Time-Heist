extends Node

enum InputControllers {UI, GAMEPLAY, NONE}

var in_control = InputControllers.UI

var camera_sens_hor: float = 5

var roll_walk_timer: float = 0
var player: Player:
	set(value):
		player = value
		if value:
			change_input_controller(InputControllers.GAMEPLAY)

const TAP_HOLD_THRESH:float = 0.2

var close_timer: Timer #for inventory wheel

func _ready():
	change_input_controller(in_control)
	await get_tree().process_frame
	
	#for inventory wheel
	close_timer = Timer.new()
	close_timer.wait_time = 0.8
	close_timer.one_shot = true
	close_timer.timeout.connect(func(): player.inventory_wheel.close())
	add_child(close_timer)

func change_input_controller(controller: InputControllers):
	match controller:
		InputControllers.UI:
			_switch_to_ui()
		InputControllers.GAMEPLAY:
			_switch_to_gameplay()
		InputControllers.NONE:
			_switch_to_none()

func _physics_process(delta):
	match in_control:
		InputControllers.UI:
			_process_UI(delta)
		InputControllers.GAMEPLAY:
			_process_gameplay(delta)
		InputControllers.NONE:
			pass

func _input(event):
	match in_control:
		InputControllers.UI:
			_input_UI(event)
		InputControllers.GAMEPLAY:
			_input_gameplay(event)
		InputControllers.NONE:
			pass

#region None
func _switch_to_none():
	in_control = InputControllers.NONE
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

#endregion

#region UI
func _switch_to_ui():
	in_control = InputControllers.UI
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _input_UI(event: InputEvent):
	if globals.ui_manager:
		globals.ui_manager.cur_ui.handle_event(event)
	pass

func _process_UI(delta: float):
	print(get_viewport().gui_get_hovered_control())
	if globals.ui_manager:
		globals.ui_manager.cur_ui.handle_input(delta)

#endregion

#region Gameplay
func _switch_to_gameplay():
	in_control = InputControllers.GAMEPLAY
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input_gameplay(event: InputEvent):
	if player and event is InputEventMouseMotion:
		player.pan_camera_horizontally(-deg_to_rad(event.screen_relative.x * (camera_sens_hor/100)))

func _process_gameplay(delta: float):
	if player:
		player.move(Input.get_vector("player_left","player_right","player_up","player_down"), delta)
	if Input.is_action_pressed("player_roll_walk"):
		if roll_walk_timer < TAP_HOLD_THRESH:
			roll_walk_timer += delta
		else:
			player.set_walk(true)
	if Input.is_action_just_released("player_roll_walk"):
		if roll_walk_timer < TAP_HOLD_THRESH:
			player.roll()
		else:
			player.set_walk(false)
		roll_walk_timer = 0
	if Input.is_action_just_pressed("player_crouch"):
		player.toggle_crouch()
	if Input.is_action_just_pressed("player_interact"):
		player.interact()

	if Input.is_action_just_released("inventory_wheel_scroll_up"):
		player.inventory_wheel.scroll(1)
		keep_wheel_open()
	if Input.is_action_just_released("inventory_wheel_scroll_down"):
		player.inventory_wheel.scroll(-1)
		keep_wheel_open()
	if Input.is_action_just_released("player_interact"):
		player.inventory_wheel.close()
	if globals.ui_manager and Input.is_action_just_pressed("device_menu"):
		globals.ui_manager.device_menu.open()
		globals.ui_manager.get_node("ButtonMove").play()
		
	#if Input.is_action_just_pressed("escape"):
		#change_input_controller(InputControllers.UI)

func keep_wheel_open() -> void:
	player.inventory_wheel.open()
	close_timer.stop()     #cancel a close
	close_timer.start()    #restart the countdown

#endregion
