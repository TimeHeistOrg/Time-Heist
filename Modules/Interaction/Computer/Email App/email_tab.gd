extends AppBase

var emails
var email_button_instances : Array[EmailButton]  #TIMEVAR
	#set(value):
		#if globals.time_manager and globals.time_manager.logging:
			#globals.time_manager.timelog(self,"email_button_instances",email_button_instances,value)
		#email_button_instances = value
		#print("SET FUNCTION CALLED")
@onready var email_buttons: VBoxContainer = $HBoxContainer/EmailButtons
#@onready var email_resizer: Control = $HBoxContainer/ScrollContainer/EmailResizer
@onready var email_viewer: TextureRect = $HBoxContainer/ScrollContainer/EmailViewer
@onready var scroll_container: ScrollContainer = $HBoxContainer/ScrollContainer

const EmailButtonScene = preload("res://Modules/Interaction/Computer/Email App/email_button.tscn")
var time_manager : TimeManager

var first_time : bool = true #need?
var finished : bool = false : #TIMEVAR
	set(value):
		if globals.time_manager and globals.time_manager.logging:
			globals.time_manager.timelog(self,"finished",finished,value)
		finished = value

func setup(config: EmailAppConfig) -> void:
	emails = config.emails

func _ready() -> void:
	if emails.size() == 0:
		push_error("No emails in this email tab!")
		assert(false)
	emails.sort_custom(custom_email_sort) #sorts them based on time
	setup_emails()
	#next_document_to_add = 0
	#next_time = emails[0].email_time
	#print(emails)
	#print(next_time)
	
	time_manager = globals.time_manager
	
func _process(_delta: float) -> void:
	if not finished:
		for email in email_button_instances:
			if email.email_info.email_time <= time_manager.cur_time:
				if not email.sent:
					email.sent = true
				if email_button_instances[email_button_instances.size()-1].sent:
					finished = true

func view_panel(document: DocumentInfo) -> void:
	email_viewer.texture = document.document_image
	scroll_container.scroll_vertical = 0
	
	if document.document_image:
		var tex_size = document.document_image.get_size()
		# fit width to scroll container, scale height proportionally
		var available_width = scroll_container.size.x
		var scale = available_width / tex_size.x
		email_viewer.custom_minimum_size = Vector2(available_width, tex_size.y * scale)
	
func setup_emails():
	for email in emails:
		var button_instance = EmailButtonScene.instantiate()
		email_buttons.add_child(button_instance)
		email_buttons.move_child(button_instance, 0) # moves to the top
		print(button_instance)
		button_instance.set_email_info(email)
		button_instance.focus_entered.connect(view_panel.bind(email))
		button_instance.hide()
		email_button_instances.append(button_instance)
		
func custom_email_sort(a : DocumentInfo, b : DocumentInfo):
	if not a.email_time:
		a.email_time = 0.0
	if not b.email_time:
		b.email_time = 0.0
	return a.email_time < b.email_time
	
func set_defaults():
	print(email_buttons.get_child(0))
	default_focus = email_buttons.get_child(0)
