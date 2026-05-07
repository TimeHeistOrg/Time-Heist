extends UI
class_name AppWindow

@onready var panel: Panel = $VBoxContainer/Panel
@onready var bar: NinePatchRect = $VBoxContainer/Bar

var content
const MAX_WIN_SIZE = Vector2(900, 700)  #max window size

var dragging : bool = false
var offset : Vector2

func _ready() -> void:
	#print("window READY")
	hide()

func setup(new_content: AppBase) -> void:
	#print("window SETUP")
	content = new_content
	panel.add_child(content)
	#content.reparent(panel)

#region dragging
func _physics_process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() - offset

func _on_drag_pressed():
	dragging = true
	offset = get_global_mouse_position() - global_position
	move_to_front()

func _on_drag_button_up() -> void:
	dragging = false
	
func get_random_position() -> Vector2:
	var x = randi_range(10,800)
	var y = randi_range(10,400)
	return Vector2(x,y)
#endregion

func _on_close_pressed() -> void:
	close_tab()
	
func open_tab():
	show()
	global_position = get_random_position()
	content.open_process()
	if content.has_method("get_fit_size"): #this is for resizing the window to fit a file
		var fit = content.get_fit_size()
		if fit != Vector2.ZERO:
			var scale_factor = min(
				MAX_WIN_SIZE.x / fit.x,
				MAX_WIN_SIZE.y / fit.y,
				1.0
			)
			# actual rendered image size after scaling
			var fitted_width = fit.x * scale_factor
			var fitted_height = fit.y * scale_factor
			size = Vector2(fitted_width, fitted_height + bar.size.y)
			custom_minimum_size = size

func close_tab():
	queue_free()

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed:
		#if get_global_rect().has_point(get_global_mouse_position()):
			#var parent = get_parent()
			#var is_on_top = parent.get_child(parent.get_child_count() - 1) == self
			#if not is_on_top:
				#move_to_front()
				#get_viewport().set_input_as_handled()
