extends Node3D
class_name DialogueArea

@export var dialogue: DialogueResource
var balloon_scene := "res://Dialogue/balloon.tscn"
var dial_start_loc := "start"
var dialogue_balloon


	
func _on_dialogue_finish() -> void:
	dialogue_balloon = null

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		if dialogue_balloon and is_instance_valid(dialogue_balloon):
			#print("Already trying to leave")
			return
		
		#print("Trying to leave")
		dialogue_balloon = DialogueManager.show_dialogue_balloon_scene(balloon_scene, dialogue, dial_start_loc)
		dialogue_balloon.tree_exited.connect(_on_dialogue_finish)
		get_tree().paused = true
