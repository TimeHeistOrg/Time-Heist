class_name InventorySlot extends Button

var item : PickupItem
@onready var sprite: TextureRect = $Texture


func set_data(new_item:PickupItem):
	item = new_item
	sprite.texture = new_item.image
	
