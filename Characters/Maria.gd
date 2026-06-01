extends Node3D

@onready var animation_player = $AnimationPlayer

@export var dialogue: DialogueResource
var balloon_scene := "res://Dialogue/balloon.tscn"
var dial_start_loc := "start"
var dialogue_balloon

func _ready():
	animation_player.play("Intern/idle")

func interact():
	print("interacted")
	if dialogue_balloon and is_instance_valid(dialogue_balloon):
		#print("Already talking to friend")
		return
		
	print("Talking to friend")
	dialogue_balloon = DialogueManager.show_dialogue_balloon_scene(balloon_scene, dialogue, dial_start_loc)
	dialogue_balloon.tree_exited.connect(_on_dialogue_finish)
	get_tree().paused = true

func _on_dialogue_finish() -> void:
	dialogue_balloon = null

func _on_interactable_anon_interacted() -> void:
	print("interacted")
	interact()
