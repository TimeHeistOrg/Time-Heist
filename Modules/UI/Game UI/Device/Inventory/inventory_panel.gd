extends MenuTabPanel
class_name InventoryPanel

@onready var inventory_grid: GridContainer = $HBoxContainer/VBoxContainer/GridContainer
@onready var item_info: RichTextLabel = $HBoxContainer/VBoxContainer/Panel/ItemInfo
var inventory_slot : PackedScene = preload("res://Modules/UI/Game UI/Device/Inventory/inventory_slot.tscn")


func _ready() -> void:
	#globals.connect("collect_item", collect_item) both of these handled by global inventory which calls update
	#globals.connect("remove_item", remove_item)
	globals.connect("collect_clearance", collect_clearance)
	globals.update_items.connect(update_items) #for time traveling

func select():
	super.select()
	globals.new_in_device.emit(false, globals.Device_Tabs.Inventory)

#region items
func collect_item(item:PickupItem):
	print("adding item into panel: ", item.name)
	var slot = inventory_slot.instantiate()
	inventory_grid.add_child(slot)
	slot.set_data(item)
	slot.mouse_entered.connect(view_info.bind(slot.item))
	slot.mouse_exited.connect(empty_info)

func remove_item(requested_item:PickupItem):
	print("removing item ", requested_item.name)
	for item_slot in inventory_grid.get_children():
		if item_slot.item == requested_item:
			item_slot.queue_free()
			return # removed the FIRST item of this kind
			
func update_items():
	for item in global_inventory.items: # adds items into panel that are in global inven
		if not panel_has_item(item):
			collect_item(item)
	for item_slot in inventory_grid.get_children(): # delete items from panel that are not in global inven
		if not global_inventory.has_item(item_slot.item):
			remove_item(item_slot.item)

func panel_has_item(search_item:PickupItem) -> bool:
	for item_slot in inventory_grid.get_children():
		if item_slot.item == search_item:
			return true
	return false

func view_info(item: PickupItem):
	item_info.text = item.description
	
func empty_info():
	item_info.text = ""
#endregion

#region clearances
func collect_clearance(clearance : globals.Clearances):
	if clearance == globals.Clearances.Security:
		$HBoxContainer/Inventory/Clearance/Security.show()
	if clearance == globals.Clearances.Lab:
		$HBoxContainer/Inventory/Clearance/Lab.show()
	if clearance == globals.Clearances.Upper_Office:
		$"HBoxContainer/Inventory/Clearance/Upper Office".show()
	if clearance == globals.Clearances.Utility:
		$HBoxContainer/Inventory/Clearance/Utility.show()
	if clearance == globals.Clearances.LabII:
		$HBoxContainer/Inventory/Clearance/LabII.show()
#endregion
