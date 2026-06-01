extends Node

var faded_in : bool = false
@onready var black: ColorRect = %Black

func _ready() -> void:
	black.hide()

func fade_in():
	if not faded_in:
		black.show()
		$AnimationPlayer.play('fade_in')
		print("OPENING FADE")
		await $AnimationPlayer.animation_finished
		faded_in = true
	
func fade_out():
	if faded_in:
		$AnimationPlayer.play('fade_out')
		await $AnimationPlayer.animation_finished
		black.hide()
		print("CLOSING FADE")
		faded_in = false
