class_name Interactor extends Node3D

@onready var sightline: RayCast3D = $Sightline

var in_range_interactables: Array[Area3D] = []
var targetted: Interactable:
	set(value):
		if targetted != value:
			if targetted:
				#print("untarget: ", targetted)
				targetted.untargetted()
			if value:
				#print("target: ", value)
				value.targetted()
			targetted = value

var can_interact: bool = true

func interact():
	if targetted:
		targetted.interact(globals.player)

func _physics_process(_delta):
	if in_range_interactables and can_interact:
		#print("sorting")
		in_range_interactables.sort_custom(_sort_by_nearest_visible)
		if _check_sightline(in_range_interactables[0]):
			targetted = in_range_interactables[0]
		else:
			targetted = null
	else:
		targetted = null

func _sort_by_nearest_visible(area1: Area3D, area2: Area3D):
	if not _check_sightline(area2):
		return true
	elif not _check_sightline(area1):
		return false
	else:
		var area1_xz = Vector2(area1.global_position.x,area1.global_position.z)
		var area2_xz = Vector2(area2.global_position.x,area2.global_position.z)
		var xz_pos = Vector2(global_position.x,global_position.z)
		var area1_dist = xz_pos.distance_to(area1_xz)
		var area2_dist = xz_pos.distance_to(area2_xz)
		return area1_dist < area2_dist

func _check_sightline(area: Area3D) -> bool:
	sightline.target_position = 2 * sightline.to_local(area.global_position)
	sightline.force_raycast_update()
	var col = sightline.get_collider()
	if col == area:
		return true
	else:
		return false

func _on_interaction_range_area_entered(area):
	in_range_interactables.push_back(area)


func _on_interaction_range_area_exited(area):
	in_range_interactables.erase(area)

func _print_in_range_interactables():
	var formatted = []
	for e: Interactable in in_range_interactables:
		formatted.append("(" + e.get_parent().get_parent().name + "," + str(_check_sightline(e)) + ")")
	print(formatted)
