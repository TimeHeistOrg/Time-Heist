extends UI

var debug_button_handled: bool = true
var fastforwarding: bool = false
var rewinding: bool = false
var pausing: bool = false
var restarting: bool = false

func open():
	super.open()
	globals.ui_manager.debug_mode = true

func close():
	super.close()
	globals.ui_manager.debug_mode = false

#func _process(_delta):
	#if Input.is_action_pressed("debug_button"):
		#if not pausing and Input.is_key_pressed(KEY_1):
			##print("toggle time")
			##globals.time_manager.toggle_time()
			#pausing = true
			#debug_button_handled = true
		#if not fastforwarding and Input.is_key_pressed(KEY_2):
			##print("fast forward x2")
			#globals.time_manager.start_fast_forward(2)
			#fastforwarding = true
			#debug_button_handled = true
		#if not fastforwarding and Input.is_key_pressed(KEY_3):
			##print("fast forward x5")
			#globals.time_manager.start_fast_forward(5)
			#fastforwarding = true
			#debug_button_handled = true
		#if not fastforwarding and Input.is_key_pressed(KEY_4):
			##print("fast forward x10")
			#globals.time_manager.start_fast_forward(10)
			#fastforwarding = true
			#debug_button_handled = true
		#if not restarting and Input.is_key_pressed(KEY_5):
			##print("restart")
			#globals.time_manager.restart_time()
			#restarting = true
			#debug_button_handled = true
		#if not rewinding and Input.is_key_pressed(KEY_R):
			##print("rewind")
			#globals.time_manager.rewind(10)
			#rewinding = true
			#debug_button_handled = true
	#if fastforwarding and not (Input.is_key_pressed(KEY_2) or Input.is_key_pressed(KEY_3) or Input.is_key_pressed(KEY_4)):
		#globals.time_manager.stop_fast_forward()
		#fastforwarding = false
	#if rewinding and not Input.is_key_pressed(KEY_R):
		#rewinding = false
	#if pausing and not Input.is_key_pressed(KEY_1):
		#pausing = false
	#if restarting and not Input.is_key_pressed(KEY_5):
		#restarting = false
