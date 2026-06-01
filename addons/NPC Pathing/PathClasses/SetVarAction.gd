class_name SetVarAction extends InstantAction

@export var property: String = ""

enum types {none, int, float, string, bool}

@export_node_path var object: NodePath
@export var type: types
@export var int_value: int
@export var float_value: float
@export var string_value: String
@export var bool_value: bool

func progress(npc: PathFollower, from: float, to: float):
	if type == types.none:
		return true
	var node = npc.get_node(object)
	var value
	match type:
		types.int:
			value = int_value
		types.float:
			value = float_value
		types.string:
			value = string_value
		types.bool:
			value = bool_value
	node.set(property,value)
	return true


#func _validate_property(property: Dictionary):
	#if property.name == "int_value":
		#if type == types.int:
			#property.usage |= PROPERTY_USAGE_DEFAULT
		#else:
			#property.useage = PROPERTY_USAGE_NONE
	#if property.name == "float_value":
		#if type == types.float:
			#property.usage |= PROPERTY_USAGE_DEFAULT
		#else:
			#property.useage = PROPERTY_USAGE_NONE
	#if property.name == "string_value":
		#if type == types.string:
			#property.usage |= PROPERTY_USAGE_DEFAULT
		#else:
			#property.useage = PROPERTY_USAGE_NONE
	#if property.name == "bool_value":
		#if type == types.bool:
			#property.usage |= PROPERTY_USAGE_DEFAULT
		#else:
			#property.useage = PROPERTY_USAGE_NONE
