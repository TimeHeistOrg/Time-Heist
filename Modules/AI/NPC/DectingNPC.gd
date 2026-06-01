@tool
class_name DetectingNPC extends PathFollower

const alert_mat = preload("res://Modules/AI/NPC/AlertMaterial.tres")
const inactive_mat = preload("res://Modules/AI/NPC/InactiveMaterial.tres")

@onready var body_mesh: MeshInstance3D = $Skeleton3D/torso_002
@onready var hair_mesh: MeshInstance3D = $Skeleton3D/torso_001
@onready var detector: PlayerDetector = $PlayerDetector
@export var catch_enabled: bool = true : #TIMEVAR
	set(value):
		if not Engine.is_editor_hint():
			if globals.time_manager and globals.time_manager.logging:
				globals.time_manager.timelog(self,"catch_enabled",catch_enabled)
		catch_enabled_setter(value)
		catch_enabled = value

func _ready():
	super._ready()
	catch_enabled_setter(catch_enabled)

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

func disable_catch():
	catch_enabled = false

func enable_catch():
	catch_enabled = true

func set_catch_enabled(value: bool):
	catch_enabled = value

func catch_enabled_setter(value: bool):
	if not is_node_ready():
		return
	if value:
		hair_mesh.mesh.surface_set_material(0,alert_mat)
		body_mesh.mesh.surface_set_material(0,alert_mat)
	else:
		hair_mesh.mesh.surface_set_material(0,inactive_mat)
		body_mesh.mesh.surface_set_material(0,inactive_mat)
