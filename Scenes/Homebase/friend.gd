extends Node3D

var resource := load("res://Content/Dialogue/Homebase/lauren_linda_friend.dialogue")
var balloon_scene := "res://Dialogue/balloon.tscn"
var dial_start_loc := "start"
var dialogue_balloon

func interact():
	if dialogue_balloon and is_instance_valid(dialogue_balloon):
		#print("Already talking to friend")
		return
		
	#print("Talking to friend")
	dialogue_balloon = DialogueManager.show_dialogue_balloon_scene(balloon_scene, resource, dial_start_loc)
	dialogue_balloon.tree_exited.connect(_on_dialogue_finish)
	get_tree().paused = true

func _on_dialogue_finish() -> void:
	dialogue_balloon = null

func _on_interactable_anon_interacted() -> void:
	interact()
