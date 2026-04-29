extends Node

@onready var anim_tree: AnimationTree = $"../AnimationTree"
@onready var player : Player = globals.player
@onready var blend_space: AnimationNodeBlendSpace1D = anim_tree.tree_root.get_node("walk_run")

func _ready() -> void:
	anim_tree.active = true

func _physics_process(_delta: float) -> void:
	
	blend_space.set_blend_point_position(2, globals.player.max_speed_running)
	blend_space.set_blend_point_position(1, globals.player.max_speed_walking)
	anim_tree.set("parameters/walk_run/blend_position", globals.player.speed)
	anim_tree.set("parameters/crouching/blend_position", globals.player.speed / globals.player.max_speed_crouching)
	#anim_tree.set("parameters/walking/blend_position", globals.player.speed/globals.player.max_speed_walking)
	#anim_tree.set("parameters/running/blend_position", globals.player.speed/globals.player.max_speed_running)
