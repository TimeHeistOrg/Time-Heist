class_name BmFormField
extends VBoxContainer

func setup(name: String):
	$Label.text = name.capitalize()
	$LineEdit.placeholder_text = "Enter %s..." % name

func get_form() -> LineEdit:
	return $LineEdit
