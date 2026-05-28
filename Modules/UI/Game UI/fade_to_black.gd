extends UI

var faded_in : bool = false

func open():
	if not faded_in:
		super.open()
		$AnimationPlayer.play('fade_in')
		print("OPENING FADE")
		await $AnimationPlayer.animation_finished
		faded_in = true
	
func close():
	if faded_in:
		super.close()
		$AnimationPlayer.play('fade_out')
		await $AnimationPlayer.animation_finished
		super.close()
		print("CLOSING FADE")
		faded_in = false
