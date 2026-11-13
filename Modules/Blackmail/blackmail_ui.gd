extends Control

# UI REFS
@onready var names_view: VBoxContainer = $NamesView
@onready var names_vbox: VBoxContainer = $NamesView/ScrollContainer/NamesListVBox
@onready var form_view: VBoxContainer = $FormView
@onready var form_title: Label = $"FormView/Form Text"
@onready var fields_container: VBoxContainer = $FormView/ScrollContainer/InfoHolder
@onready var error_label: Label = $"FormView/Error Text"
@onready var document_view: VBoxContainer = $DocView
@onready var document_text: Label = $"DocView/DocBody Text"
@onready var document_image: TextureRect = $"DocView/DocBody Img"
@onready var delete_button: Button = $"DocView/HBoxContainer/Delete Button"

const BM_NAME_BTN_SCN = preload("res://Modules/Blackmail/bm_name_button.tscn")
const BM_FORM_FLD_SCN = preload("res://Modules/Blackmail/bm_form_field.tscn")

var cur_record: BlackmailRecord
var info_edits: Dictionary[String, LineEdit] = {}

func _ready() -> void:
	error_label.hide()
	$"FormView/Submit Button".pressed.connect(_on_submit_info)
	$"DocView/HBoxContainer/Back Button".pressed.connect(_show_names_view)
	$"DocView/HBoxContainer/Delete Button".pressed.connect(_on_delete_bm)

# VIEW FUNCS
func _show_names_view():
	# clear names
	_clear_children(names_vbox)
	# create name for each record
	var records = BlackmailManager.database.bm_records
	for record in records:
		var name_button: BmNameButton = BM_NAME_BTN_SCN.instantiate()
		name_button.setup(record)
		name_button.name_selected.connect(_on_click_name)
		names_vbox.add_child(name_button)
	# set view to names
	_set_view(names_view)

func _show_form_view(record: BlackmailRecord):
	# setup form view with record info
	cur_record = record
	form_title.text = "Enter Information on %s:" % record.person_name
	error_label.hide()
	_clear_children(fields_container)
	info_edits.clear()
	# create form fields
	for field_name in record.person_info.keys():
		var form_field: BmFormField = BM_FORM_FLD_SCN.instantiate()
		form_field.setup(field_name)
		fields_container.add_child(form_field)
		info_edits[field_name] = form_field.get_form()
	# set view to form
	_set_view(form_view)

func _show_doc_view(record: BlackmailRecord):
	# show image
	if record.document_image:
		document_image.texture = record.document_image
		document_image.show()
		document_text.hide()
	# show text instead
	else:
		document_text.text = record.document_text
		document_text.show()
		document_image.hide()
	delete_button.visible = not record.blackmail_deleted
	# set view to doc
	_set_view(document_view)

func _set_view(view: Control):
	names_view.hide()
	form_view.hide()
	document_view.hide()
	view.show()


# HANDLERS
func _on_click_name(record: BlackmailRecord):
	_show_form_view(record)

func _on_submit_info():
	for field_name in info_edits.keys():
		var entered = info_edits[field_name].text.strip_edges().to_lower()
		var expected = cur_record.person_info[field_name].strip_edges().to_lower()
		# not correct answer
		if entered != expected:
			error_label.text = "Information Mismatch"
			error_label.show()
			return
	# correct answers
	error_label.hide()
	_show_doc_view(cur_record)
	
func _on_delete_bm():
	cur_record.blackmail_deleted = true
	BlackmailManager.save_data()
	_show_names_view()

func _on_visibility_changed() -> void:
	# when shown
	if is_visible_in_tree():
		_show_names_view()

func _on_form_back_button_pressed() -> void:
	_show_names_view()


# HELPERS
func _clear_children(node: Node):
	for child in node.get_children():
		child.queue_free()
