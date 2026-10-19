class_name BmNameButton
extends Button

signal name_selected(record: BlackmailRecord)

var record: BlackmailRecord

func setup(r: BlackmailRecord):
	record = r
	text = record.person_name
	if record.blackmail_deleted:
		text += " [DELETED]"
		disabled = true
	pressed.connect(func(): name_selected.emit(record))
