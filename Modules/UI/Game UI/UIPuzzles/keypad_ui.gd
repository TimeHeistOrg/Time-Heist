extends UI
class_name KeypadUI

@export var correct_code: String = "1234"
@export var max_digits: int = 4

signal code_accepted
signal code_rejected

var current_input: String = ""

@onready var grid: GridContainer = %Keys
@onready var submit: Button = %Submit
@onready var reset: Button = %Reset
@onready var code_display: Label = %CodeDisplay

func _ready() -> void:
	close()
	# connect all number buttons
	for child in grid.get_children():
		if child is Button:
			child.pressed.connect(_on_number_pressed.bind(child.text))
	
	submit.pressed.connect(_on_submit_pressed)
	reset.pressed.connect(_on_reset_pressed)

func _on_number_pressed(number: String) -> void:
	if current_input.length() >= max_digits:
		return
	current_input += number
	update_display()

func _on_submit_pressed() -> void:
	if current_input == correct_code:
		code_accepted.emit()
		show_feedback(true)
	else:
		code_rejected.emit()
		show_feedback(false)

func _on_reset_pressed() -> void:
	reset_input()

func reset_input() -> void:
	current_input = ""
	update_display()

func update_display() -> void:
	# show dots so the code is hidden
	#code_display.text = "●".repeat(current_input.length())
	## or show the actual digits:
	code_display.text = current_input

func show_feedback(success: bool) -> void:
	# flash the panel green or red
	var panel = $Panel
	var original_color = panel.modulate
	var feedback_color = Color("46af56ff") if success else Color("d73438ff")
	
	var tween = create_tween()
	tween.tween_property(panel, "modulate", feedback_color, 0.1)
	tween.tween_interval(0.5)
	tween.tween_property(panel, "modulate", original_color, 0.2)
	
	if success:
		tween.tween_callback(func(): close())
	else:
		tween.tween_callback(reset_input)
		
