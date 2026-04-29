extends Node3D

var lights
@export var room_area: Area3D
@export var lights_node: Node3D
@export var room_id: String = "room_01"

@export var fade_speed: float = 5.0
var target_alpha: float = 1.0
var target_energy: float = 6.0

var contains_player: bool = false

func _ready() -> void:
	room_area.body_entered.connect(_on_body_entered)
	room_area.body_exited.connect(_on_body_exited)
	lights = lights_node.get_children() as Array[OfficeLight]

func _on_body_entered(body: Node3D) -> void:
	if body == globals.player:
		#lights_on()
		contains_player = true
		for light in lights:
			light.on()
		print("Entered ", room_id)
		
func _on_body_exited(body: Node3D) -> void:
	if body == globals.player:
		#lights_off()
		contains_player = false
		for light in lights:
			light.off()
		print("Exited ", room_id)

#func _process(delta: float) -> void:
	#if not lights:
		#return
	#for light in lights:
		#light.light_energy = lerpf(light.light_energy, target_energy, fade_speed * delta)
