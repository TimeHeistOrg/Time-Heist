@tool
class_name SceneConfig extends Node

@export var managers: Array[String] = []
@export var load_worldenv := false
@export var load_shader := false
@export var temp: bool = false

func _validate_property(property: Dictionary) -> void:
	if property.name == "managers":
		property.hint = PROPERTY_HINT_TYPE_STRING
		var manager_list: String = ""
		for manager in SceneManager.managers:
			manager_list += manager.get_global_name() + ","
		property.hint_string = "%d/%d:%s" % [TYPE_STRING, PROPERTY_HINT_ENUM, manager_list]
