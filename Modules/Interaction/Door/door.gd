@abstract @tool
class_name Door extends Node3D

@export var locker: Lockable = null
signal disabled(value: bool)

@export var is_open: bool = false : #TIMEVAR
	set(value):
		#print("set is_open to ", value)
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_open",is_open)
		is_open_setter(value)
		is_open = value

@export var is_locked: bool = false : #TIMEVAR
	set(value):
		#print("set is_locked to ", value)
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_locked",is_locked)
		is_locked_setter(value)
		is_locked = value

@export var is_disabled: bool = false: #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"is_disabled",is_disabled)
		is_disabled_setter(value)
		is_disabled = value

# Called when the node enters the scene tree for the first time.
func _ready():
	if not is_disabled:
		is_disabled_setter(false)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

@abstract
func open()

@abstract
func close()

func toggle_open():
	if is_open:
		close()
	else:
		open()

func set_open(value: bool):
	@warning_ignore("standalone_ternary")
	open() if value else close()

func set_is_open_opposite(value:bool):
	set_open(not value)

func lock():
	if is_locked: #check to avoid unnecessary call to setter
		return
	is_locked = true

func unlock():
	if is_locked: #check to avoid unnecessary call to setter
		is_locked = false

func toggle_lock():
	is_locked = not is_locked

func set_lock(value : bool):
	@warning_ignore("standalone_ternary")
	lock() if value else unlock()

func set_lock_opposite(value : bool):
	set_lock(not value)

func unlock_and_open():
	unlock()
	open()

func close_and_lock():
	close()
	lock()

func disable():
	is_disabled = true

func enable():
	is_disabled = false

func toggle_disabled():
	is_disabled = not is_disabled

func anon_interacted():
	if is_open:
			close()
	else:
		if is_locked:
			if locker:
				if not locker.try_unlock():
					locked_door_behavior()
				else:
					unlock_and_open()
			else:
				locked_door_behavior()
		else:
			open()

func interacted_by(_person: Variant):
	anon_interacted()

@abstract
func locked_door_behavior()

func is_open_setter(_value:bool): #made so that setter can be overridden in children, value will be set in main setter
	pass

func is_locked_setter(_value:bool): #made so that setter can be overridden in children, value will be set in main setter
	pass

func is_disabled_setter(value: bool):
	disabled.emit(value)
	
func is_disabled_setter_opposite(value: bool):
	disabled.emit(not value)
