extends Control
class_name MiniTimeJuiceBar

@export var start_visible: bool = true
@onready var mini_bar: TextureProgressBar = %MiniBar
var bar_visible : bool = false

func _ready() -> void:
	if start_visible:
		mini_bar.show()
	else:
		mini_bar.hide()

func _process(_delta: float) -> void:
	mini_bar.value = globals.time_manager.time_juice if globals.time_manager else 100.0
	
func open_bar():
	if not bar_visible:
		mini_bar.scale = Vector2.ZERO
		mini_bar.show()
		$BarPlayer.play('appear')
		bar_visible = true
	
func close_bar():
	if bar_visible:
		$BarPlayer.play('disappear')
		await $BarPlayer.animation_finished
		mini_bar.hide()
		bar_visible = false
