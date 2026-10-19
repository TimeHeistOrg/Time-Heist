extends Node3D
class_name RedPlant

const GARDEN_SCISSORS = preload("uid://byt5mxt5py6iu")
@onready var plant: MeshInstance3D = $Plant

var cut : bool = false
	
func interact():
	if global_inventory.has_item(GARDEN_SCISSORS):
		cut = true
		plant.hide()
