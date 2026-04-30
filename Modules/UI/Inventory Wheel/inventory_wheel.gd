@tool
extends Node2D

#region Inventory Wheel
@export var wheel_color : Color = Color(0.405, 0.493, 0.869, 1.0)
@export var radius : float = 350
@export var width : float = 180
@export var gap_width : float = 15
@export var angle : float = 163.63:
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
var center = Vector2.ZERO

@onready var arc: Node2D = $Arc
@onready var mask: Node2D = $Mask
var is_open : bool = false
#endregion
#region Items
var selected_index: int = 0
var window: Array = []
#endregion

#region Rotation
var rotation_speed = 1
var target_rotation: float = 0.0
var snap_angle: float = 0.0  #one slice
#endregion

func _ready() -> void:
	close()
	get_viewport().size_changed.connect(queue_redraw)
	angle_extended = angle + 2*(angle/num_of_items)
	angle_start_rad = - TAU/4 - deg_to_rad(angle/2)
	angle_end_rad = - TAU/4 + deg_to_rad(angle/2)
	angle_start_rad_extended = - TAU/4 - deg_to_rad(angle_extended/2)
	angle_end_rad_extended = - TAU/4 + deg_to_rad(angle_extended/2)
	step = angle/num_of_items
	
	snap_angle = deg_to_rad(angle / num_of_items)
	target_rotation = 0.0
	$Wheel.rotation = 0.0
	$SlotIcons.setup()
	queue_redraw()

func _draw() -> void:
	#var arcs = calc_arcs()
	$Wheel/Arc.draw_inven_arc()
	$Wheel/Mask.draw_inven_line()
	$MaskBottom.draw_inven_mask()
		
#func calc_arcs():
	#var current_angle = angle_start_rad
	#
	#var arcs : Array[Vector2]
	#var new_angle = angle - ((num_of_items-1)*gap_width)
	#var step_rad = deg_to_rad(new_angle/num_of_items)
	#for i in range(num_of_items):
		#arcs.append(Vector2(current_angle,current_angle+step_rad))
		#current_angle += (step_rad + deg_to_rad(gap_width))
	#print(arcs)
	#return arcs
	
func open() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	rebuild_window()
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.15) \
		 .from(Vector2.ZERO) \
		 .set_ease(Tween.EASE_OUT) \
		 .set_trans(Tween.TRANS_BACK)

func close() -> void:
	if not is_open:
		return
	is_open = false
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.1) \
		 .set_ease(Tween.EASE_IN) \
		 .set_trans(Tween.TRANS_QUAD)
	tween.tween_callback(func(): visible = false)

func rebuild_window() -> void:
	#print(global_inventory.items)
	window.clear()
	if global_inventory.items.is_empty():
		return
	print(selected_index)
	print(global_inventory.items[selected_index])
	window.clear()
	var total = num_of_items + 2  # visible + 2 ghosts
	var half = total / 2          # slots on each side of selected
	for i in range(total):
		var offset = i - half
		var item_index = (selected_index + offset) % global_inventory.items.size()
		if item_index < 0:
			item_index += global_inventory.items.size()
		window.append(global_inventory.items[item_index])
	if $SlotIcons:
		$SlotIcons.update_icons(window, $Wheel.rotation)

func scroll(direction: int) -> void:
	#print("SCROLL")
	if global_inventory.items.is_empty():
		return
	selected_index = (selected_index + direction) % global_inventory.items.size()
	if selected_index < 0:
		selected_index += global_inventory.items.size()
	rebuild_window()
	target_rotation -= direction * snap_angle
	queue_redraw()

func _process(delta: float) -> void:
	# Lerp toward target — wheel snaps to slot positions
	$Wheel.rotation = lerp($Wheel.rotation, target_rotation, delta * 12.0)
	
	# update slot pictures
	$SlotIcons.update_icons(window, $Wheel.rotation)
	
	# Stop redrawing once settled
	if abs($Wheel.rotation - target_rotation) > 0.001:
		queue_redraw()
