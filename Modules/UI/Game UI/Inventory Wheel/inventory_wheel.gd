@tool
extends Node2D

#region Inventory Wheel
@export var radius : float = 350
@export var width : float = 180
@export var gap_width : float = 10
@export var angle : float = 160:
	set(value):
		angle = value
		angle_extended = angle + 2*(angle/num_of_items)
		angle_start_rad = - TAU/4 - deg_to_rad(angle/2)
		angle_start_rad_extended = - TAU/4 - deg_to_rad(angle_extended/2)
		angle_end_rad = - TAU/4 + deg_to_rad(angle/2)
		angle_end_rad_extended = - TAU/4 + deg_to_rad(angle_extended/2)
var angle_extended
var angle_start_rad
var angle_start_rad_extended
var angle_end_rad
var angle_end_rad_extended
var step
@export_range(2,100,1) var num_of_items : int = 3:
	set(value):
		num_of_items = value
		angle_extended = angle + 2*(angle/num_of_items)
		angle_start_rad_extended = - TAU/4 - deg_to_rad(angle_extended/2)
		angle_end_rad_extended = - TAU/4 + deg_to_rad(angle_extended/2)
@export_tool_button("Redraw","CanvasItem") var redraw = queue_redraw
var center = Vector2(-450,-200)

@onready var arc: Node2D = $Arc
@onready var mask: Node2D = $Mask
#endregion
#region Items
var selected_index: int = 0
var window: Array = []
#endregion

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)
	angle_extended = angle + 2*(angle/num_of_items)
	angle_start_rad = - TAU/4 - deg_to_rad(angle/2)
	angle_end_rad = - TAU/4 + deg_to_rad(angle/2)
	angle_start_rad_extended = - TAU/4 - deg_to_rad(angle_extended/2)
	angle_end_rad_extended = - TAU/4 + deg_to_rad(angle_extended/2)
	step = angle/num_of_items
	queue_redraw()

func _draw() -> void:
	#var arcs = calc_arcs()
	#for angle in arcs:
		#draw_arc(Vector2.ZERO,radius,angle[0], angle[1],100,Color(0.043, 0.376, 0.71, 0.659),width,true)
	$Arc.draw_inven_arc(center, radius, angle_start_rad_extended,angle_end_rad_extended,100,Color(0.23, 0.377, 0.82, 0.694),width,true)
	#draw_arc(center, radius, angle_start_rad,angle_end_rad,100,Color(0.23, 0.377, 0.82, 0.694),width,true)
	$Mask.draw_inven_line()
		
func calc_arcs():
	var current_angle = angle_start_rad
	
	var arcs : Array[Vector2]
	var new_angle = angle - ((num_of_items-1)*gap_width)
	var step_rad = deg_to_rad(new_angle/num_of_items)
	for i in range(num_of_items):
		arcs.append(Vector2(current_angle,current_angle+step_rad))
		current_angle += (step_rad + deg_to_rad(gap_width))
	print(arcs)
	return arcs

func rebuild_window() -> void:
	window.clear()
	var total = num_of_items + 2  # visible + 2 ghosts
	var half = total / 2          # slots on each side of selected
	for i in range(total):
		var offset = i - half
		var item_index = (selected_index + offset) % global_inventory.items.size()
		if item_index < 0:
			item_index += global_inventory.items.size()
		window.append(global_inventory.items[item_index])

func scroll(direction: int) -> void:
	selected_index = (selected_index + direction) % global_inventory.items.size()
	if selected_index < 0:
		selected_index += global_inventory.items.size()
	rebuild_window()
	#target_rotation += direction * deg_to_rad(angle / num_of_items) #TODO
	queue_redraw()
