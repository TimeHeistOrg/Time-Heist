extends UI

func open():
	super.open()
	$AnimationPlayer.play('fade_in')
	print("OPENING FADE")
	await $AnimationPlayer.animation_finished
	
func close():
	super.close()
	$AnimationPlayer.play('fade_out')
	await $AnimationPlayer.animation_finished
	super.close()
	print("CLOSING FADE")
