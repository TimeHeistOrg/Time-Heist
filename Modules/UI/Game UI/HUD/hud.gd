extends Control
class_name HUD

@onready var time_juice: TextureProgressBar = $TimeJuice
@onready var new_notif_texture: TextureRect = $TimeJuice/NewNotif
@onready var time_label: Label = $Time
@onready var time_label_seconds: Label = $"Time Seconds"
var notif_on_tab : Array[bool] = [false,false,false]

func _ready() -> void:
	globals.new_in_device.connect(new_notif)
	pass

func _process(_delta: float) -> void:
	time_juice.value = globals.time_manager.time_juice
	if globals.time_manager:
		var cur_time: int = int(globals.time_manager.cur_time)
		@warning_ignore("integer_division")
		time_label.text = "%02d:%02d" % [globals.time_manager.night_start_hours,globals.time_manager.night_start_minutes+(cur_time/60)] #start time is 1:49
		time_label_seconds.text = "%02d" % [int(cur_time)%60]
	pass

func new_notif(value : bool, tab : globals.Device_Tabs):
	var do_show : bool = false
	notif_on_tab[tab] = value
	#print("checking ", notif_on_tab)
	for notif_tab in notif_on_tab:
		if notif_tab:
			do_show = true
	@warning_ignore("standalone_ternary")
	new_notif_texture.show() if do_show else new_notif_texture.hide()
