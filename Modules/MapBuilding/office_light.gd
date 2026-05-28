extends Light3D
class_name OfficeLight

var energy_on
var energy_off := 0.0
var target_energy = energy_off
var is_on : bool = true

static var fade_speed := 5


func _ready() -> void:
	energy_on = light_energy
	pass

func off():
	target_energy = energy_off
	is_on = false

func on():
	target_energy = energy_on
	is_on = true
	
func toggle():
	if is_on:
		off()
	else:
		on()
	
func set_light(flip: bool):
	@warning_ignore("standalone_ternary")
	on() if flip else off()
		
func set_light_opposite(flip: bool):
	@warning_ignore("standalone_ternary")
	on() if not flip else off()

func _process(delta: float) -> void:
	light_energy = lerpf(light_energy, target_energy, fade_speed * delta)
