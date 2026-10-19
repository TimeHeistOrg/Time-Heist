extends UI

@onready var label: Label = $Label

func open():
	super.open()
	$AnimationPlayer.play('open')

func _on_try_again_pressed():
	#print("press restart")
	close()
	#get_tree().paused = false
	globals.retry()


func _on_homebase_pressed():
	#print("press homebase")
	close()
	#get_tree().paused = false
	globals.to_homebase()

func handle_input(_delta):
	pass
