extends Node
class_name Stashable

var has_item : bool
@export var is_locked : bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"is_locked",is_locked)
		is_locked = value
@export var held_item : PickupItem = null : #TIMEVAR
	set(value):
		print("\tSTASHABLE SET BEING CALLED. HELD_IMEM IS NOW ", value)
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"held_item",held_item)
		held_item = value
		has_item = true if value else false
		print("\tHAS ITEM??? ", has_item)
@export var expected_item : PickupItem

func interact(person : Node):
	if person == globals.player:
		print("player touching plant")
		if not is_locked:
			if has_item:
				globals.collect_item.emit(held_item)
				held_item = null
			else:
				if global_inventory.has_item(expected_item):
					globals.remove_item.emit(expected_item)
					held_item = expected_item
				else:
					print("\tplayer doesnt have item")
		else:
			print("\tlocked! suckaaaa")
			return
	else:
		print("\tnpc touching plant")
		if has_item: # NPC interaction is kinda temp rn. NPCs should honestly have an inventory
			held_item = null
		else:
			held_item = expected_item
	pass

func unlock():
	is_locked = false
