@tool
class_name DetectingNPC extends PathFollower

@onready var detector: PlayerDetector = $PlayerDetector

func _process(delta):
	super._process(delta)
	if not Engine.is_editor_hint():
		if detector.player_spotted:
			catch_player()


func _on_hitbox_body_entered(body):
	if body == globals.player and not globals.player_invisible:
		catch_player()

func catch_player():
	globals.player_caught()
