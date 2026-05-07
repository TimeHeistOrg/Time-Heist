extends AppBase

var convos : Array[TextConvo]
enum person {person0, person1}
var which_person : Array[person]

var current_convo : TextConvo

@onready var people: VBoxContainer = $HBoxContainer/People
@onready var chatlog: VBoxContainer = $HBoxContainer/ScrollContainer/Chatlog
@onready var time_manager : TimeManager

var left_bubble := preload("res://Modules/Interaction/Computer/Text App/text_bubble_left.tscn")
var right_bubble := preload("res://Modules/Interaction/Computer/Text App/text_bubble_right.tscn")

func setup(config: TextAppConfig) -> void:
	convos = config.convos
	which_person = config.which_person as Array[person]
	create_convo_buttons()

func _ready() -> void:
	time_manager = globals.time_manager
	default_focus = people.get_child(0)

func set_convo(convo : TextConvo):
	print("veiwing convo between ", convo.person0, " and ", convo.person1)
	current_convo = convo

func update_panel(convo : TextConvo):
	for child in chatlog.get_children():
		child.queue_free()
	var lines := convo.conversation.split("\n", false)
	for line in lines:
		if line.is_empty():
			continue
		var comma_index = line.find(",")
		if comma_index == -1:
			push_error("No time set for text conversation ", convo)
		var time := float(line.substr(0, comma_index))
		var speaker_id := int(line[comma_index + 1])
		var message := line.substr(comma_index + 2).strip_edges()
		var index = convos.find(convo)
		if time <= time_manager.cur_time:
			var bubble = left_bubble if speaker_id != which_person[index] else right_bubble
			var bubble_instance = bubble.instantiate()
			chatlog.add_child(bubble_instance)
			bubble_instance.text(message)
		else:
			return
		
func _process(_delta: float) -> void:
	if current_convo:
		update_panel(current_convo)
	pass
	
func create_convo_buttons():
	for convo in convos:
		var button_instance = Button.new()
		people.add_child(button_instance)
		button_instance.custom_minimum_size.y = 50
		var index = convos.find(convo)
		button_instance.text = convo.person0 if which_person[index] == 1 else convo.person1 # sets the person correctly
		button_instance.focus_entered.connect(set_convo.bind(convo))
