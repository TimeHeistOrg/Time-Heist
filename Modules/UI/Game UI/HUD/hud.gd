extends Control
class_name HUD

@onready var time_juice: TextureProgressBar = $TimeJuiceBar
@onready var new_notif_texture: TextureRect = %NewNotif
@onready var time_label: Label = $Time
@onready var time_label_seconds: Label = $"Time Seconds"
var notif_on_tab : Array[bool] = [false,false,false]
var bar_visible : bool = false

func _ready() -> void:
	$LightPlayer.play('RESET')
	globals.new_in_device.connect(new_notif)
	
	globals.time_manager.time_traveled.connect(open_bar)
	globals.time_manager.stopped_time_travel.connect(close_bar)
	globals.start_charging.connect(open_bar)
	globals.stop_charging.connect(close_bar)
	pass

func _process(_delta: float) -> void:
	%TextureProgressBar.value = globals.time_juice
	time_juice.value = globals.time_juice
	if globals.time_manager:
		var cur_time: int = int(globals.time_manager.cur_time)
		@warning_ignore("integer_division")
		time_label.text = "%02d:%02d" % [globals.time_manager.night_start_hours,globals.time_manager.night_start_minutes+(cur_time/60)] #start time is 1:49
		time_label_seconds.text = "%02d" % [int(cur_time)%60]
	pass

func new_notif(value : bool, tab : globals.Device_Tabs):
	$BobPlayer.play('bob')
	var do_show : bool = false
	notif_on_tab[tab] = value
	#print("checking ", notif_on_tab)
	for notif_tab in notif_on_tab:
		if notif_tab:
			do_show = true
	@warning_ignore("standalone_ternary")
	if do_show:
		#new_notif_texture.show()
		$LightPlayer.play('pulse')
	else:
		#new_notif_texture.hide()
		$LightPlayer.play('RESET')
		
func open_bar():
	if not bar_visible:
		$BarPlayer.play('appear')
	bar_visible = true
	
	
func close_bar():
	if bar_visible:
		$BarPlayer.play('disappear')
	bar_visible = false
