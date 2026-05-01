extends Node2D
class_name InventoryWheel

const APPLE = preload("uid://2u7ypb7xpscs")
const ARCHIVE_KEY = preload("uid://bl3wymmqufqh2")
const BASEMENT_ALBUS_KEYCARD = preload("uid://ixu3w8mgsrxm")
const BASEMENT_SECURITY_LOCKBOX_KEY_1 = preload("uid://ccb6qtg54rgyj")
const BASEMENT_SECURITY_LOCKBOX_KEY_2 = preload("uid://gue75w7rapn5")
const TUTORIAL_DOOR_KEY = preload("uid://c7atpkdvr2gl0")
var items : Array[PickupItem] = [APPLE,ARCHIVE_KEY,BASEMENT_ALBUS_KEYCARD,BASEMENT_SECURITY_LOCKBOX_KEY_1,BASEMENT_SECURITY_LOCKBOX_KEY_2, TUTORIAL_DOOR_KEY]


@onready var slot_icons: Node2D = $SlotIcons
@onready var chosen_slot_drawer: Node2D = $ChosenSlot
@onready var arc_drawer: Node2D = $Wheel/Arc
@onready var mask_drawer: Node2D = $Wheel/Mask
@onready var mask_bottom_drawer: Node2D = $MaskBottom

#region Inventory Wheel
@export var wheel_color : Color = Color(0.405, 0.493, 0.869, 1.0)
@export var selected_color : Color = Color(0.27, 0.342, 0.726, 1.0)
@export var wheel_radius : float = 350
@export var wheel_width : float = 180

@export var angle : float = 154.29:
	set(value):
		angle = value
const num_of_items : int = 9
const num_of_items_visible : int = 5
var center = Vector2.ZERO

const start = -TAU/4 - slot_width/2

#var slots := [0,1,2, 3, 4, 5, 6, 7, 8, 9]
const slot_width = deg_to_rad(360/num_of_items)
#const slot_width := full_slot_width - slot_gap_width
const slot_gap_width : float = 15
@onready var arc: Node2D = $Arc
@onready var mask: Node2D = $Mask

var is_open : bool = false

var selected_index: int = 0
var window: Array = []
var window_start : int = 0
var window_end : int = num_of_items_visible-1

#region Rotation
var rotation_speed = 1
var target_rotation: float = 0.0
var snap_angle: float = 0.0  #one slice
#endregion

func _ready() -> void:
	close()
	get_viewport().size_changed.connect(queue_redraw)
	rebuild_window()
	
	#snap_angle = deg_to_rad(ang/ num_of_items)
	target_rotation = 0.0
	$Wheel.rotation = 0.0
	slot_icons.setup()
	queue_redraw()

func _draw() -> void:
	arc_drawer.draw_inven_arc()
	mask_drawer.draw_inven_line()
	mask_bottom_drawer.draw_inven_mask()
	chosen_slot_drawer.draw_inven_selected()
	
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
	window_start = selected_index
	window_end = selected_index
	while validate_index(window_start-1) and selected_index - (window_start-1) <= num_of_items_visible/2:
		window_start -= 1
	while validate_index(window_end+1) and (window_end+1) - selected_index <= num_of_items_visible/2:
		window_end += 1
	for i in range(window_start,window_end+1):
		window.append(items[i])
	if slot_icons:
		slot_icons.update_icons(window, $Wheel.rotation)
	
func validate_index(index):
	return index >= 0 and index < items.size()

func scroll(direction: int) -> void:
	if selected_index+direction >= 0 and selected_index+direction < items.size():
		selected_index = selected_index+direction
		target_rotation -= direction * slot_width
	rebuild_window()
	print(selected_index)
	print(window)

func _process(delta: float) -> void:
	# Lerp toward target — wheel snaps to slot positions
	$Wheel.rotation = lerp($Wheel.rotation, target_rotation, delta * 12.0)
	
	# update slot pictures
	slot_icons.update_icons(window, $Wheel.rotation)
	
	# Stop redrawing once settled
	if abs($Wheel.rotation - target_rotation) > 0.001:
		queue_redraw()
