extends Node
class_name GlobalInventory

var items : Array[PickupItem] : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"items",items,value)
		items = value
		print(items)
		globals.update_items.emit()
@export var items_to_start_with : Array[PickupItem] = []
var documents : Array[DocumentInfo] = [preload("res://Assets/Documents/Resources/basement_goal_note.tres")]
var clearances : Array[globals.Clearances]
signal update_device_files

func _ready() -> void:
	items = items_to_start_with
	globals.connect("collect_item",add_item)
	globals.connect("remove_item", remove_item)
	globals.connect("added_doc", add_doc)
	globals.connect("collect_clearance", add_clearance)
	
func add_item(item:PickupItem):
	if not has_item(item):
		#print("added item to the global inventory: ", item)
		globals.new_in_device.emit(true, globals.Device_Tabs.Inventory) # for device notif
		var temp_items = items.duplicate(1)
		temp_items.append(item)
		items = temp_items

func reset_items():
	items = items_to_start_with
	
func remove_item(item:PickupItem):
	if has_item(item):
		var temp_items = items.duplicate(1)
		temp_items.erase(item)
		items = temp_items

func has_item(item:PickupItem):
	return items.has(item)

func add_doc(doc:DocumentInfo):
	if not has_doc(doc):
		documents.append(doc)
		emit_signal("update_device_files", doc)
		globals.new_in_device.emit(true, globals.Device_Tabs.Files) # for device notif
	
func has_doc(doc:DocumentInfo):
	return documents.has(doc)

func add_clearance(clearance:globals.Clearances):
	if not has_clearance(clearance):
		clearances.append(clearance)
		globals.new_in_device.emit(true, globals.Device_Tabs.Inventory) # for device notif
	
func has_clearance(clearance:globals.Clearances):
	return clearances.has(clearance)
