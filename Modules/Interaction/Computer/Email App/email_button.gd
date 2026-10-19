extends Control
class_name EmailButton

@onready var title: Label = $MarginContainer/VBoxContainer/HBoxContainer/Title
@onready var time: Label = $MarginContainer/VBoxContainer/HBoxContainer/Time
@onready var from: Label = $MarginContainer/VBoxContainer/From
@onready var desc: Label = $MarginContainer/VBoxContainer/Desc
@onready var new_mail: TextureRect = $NewMail

var viewed : bool = false:
	set(value):
		if value:
			viewed = value
			new_mail.hide()
			
			
var email_info : DocumentInfo
var sent : bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"sent",sent)
		sent = value
		if value:
			show()
		else:
			hide()

func set_email_info(doc : DocumentInfo):
	if not doc.is_email:
		push_error("Non email doc %d: %s in email app", [doc.document_id, doc.title])
		assert(false)
	email_info = doc
	title.text = doc.email_heading
	from.text = "From: " + doc.email_from
	desc.text = doc.email_desc
	var total_seconds := int(doc.email_time)
	@warning_ignore("integer_division")
	time.text = "%d:%02d" % [total_seconds/60,total_seconds%60]
	
func _on_focus_entered() -> void:
	if not viewed:
		viewed = true;
		globals.emit_signal("added_doc", email_info)
	#color_rect.color.a = 255
	pass # Replace with function body.
