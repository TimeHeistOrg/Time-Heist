extends Marker3D
class_name HidePoint

var player_inside: bool = false
var saved_position: Vector3
var tween: Tween
var tween_duration: float = 0.3

func interact(person: Node) -> void:
	if person == globals.player:
		if not player_inside:
			enter_hide_point(person)
		else:
			exit_hide_point(person)

func enter_hide_point(player: Player) -> void:
	player_inside = true
	player.is_hidden = true
	player.lock_position()
	
	saved_position = player.global_position
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		globals.player,
		"global_position",
		global_position,
		tween_duration
	)
	tween.tween_callback(func():
		player.mesh.visible = false
	)

func exit_hide_point(player: Player) -> void:
	player_inside = false
	player.is_hidden = false
	player.unlock_position()
	
	player.mesh.visible = true
	tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(
		globals.player,
		"global_position",
		saved_position,
		tween_duration
	)
