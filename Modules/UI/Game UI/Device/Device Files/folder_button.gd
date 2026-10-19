extends TextureButton
class_name FolderButton

@onready var label: AutoSizeLabel = $Label
var label_text : String:
	set(value):
		label_text = value
		label.text = value

func _ready() -> void:
	label.text = "HELLO HELLO SHRINK"
