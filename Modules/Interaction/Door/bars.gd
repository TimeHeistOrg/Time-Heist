@tool
extends Node3D

@onready var anim_player: TimeAnimationPlayer = $PositioningNode/TimeAnimationPlayer

@export var start_open: bool = false:
	set(value):
		start_open = value
		if value:
			open()
		else:
			close()
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func open():
	if Engine.is_editor_hint():
		anim_player.play("BarsOpen")
	else:
		anim_player.time_play("BarsOpening")

func close():
	if Engine.is_editor_hint():
		anim_player.play("BarsClosed")
	else:
		anim_player.time_play("BarsClosing")

func set_open(value: bool):
	@warning_ignore("standalone_ternary")
	open() if value else close()

func set_open_opposite(value: bool):
	set_open(not value)
