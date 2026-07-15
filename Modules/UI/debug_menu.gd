class_name DebugMenu extends ScrollContainer

@export var options: Array[DebugOption] = []

class DebugOption extends Resource:
	enum OptionType {String, Integer, Float, Boolean, Button, Info}
	@export var type: OptionType
	@export var string_default: String
	@export var int_default: int
	@export var float_default: float
	@export var bool_default: bool
	
	func _validate_property(property):
		if property.name == "string_default" and type != OptionType.String:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		if property.name == "int_default" and type != OptionType.Integer:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		if property.name == "float_default" and type != OptionType.Float:
			property.usage = PROPERTY_USAGE_NO_EDITOR
		if property.name == "bool_default" and type != OptionType.Boolean:
			property.usage = PROPERTY_USAGE_NO_EDITOR
