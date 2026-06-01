@tool
class_name DetectingNPC extends PathFollower

@onready var detector: PlayerDetector = $PlayerDetector
@export var catch_enabled: bool = true

func _process(delta):
	super._process(delta)
	if not Engine.is_editor_hint():
		if catch_enabled and detector.player_spotted:
			catch_player()


func _on_hitbox_body_entered(body):
	if catch_enabled and body == globals.player and not globals.player_invisible:
		catch_player()

func catch_player():
	globals.player_caught()
