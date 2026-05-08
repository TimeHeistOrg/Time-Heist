extends UI
class_name DesktopViewer

const COMPUTER_UI = preload("res://Modules/Interaction/Computer/computer_ui.tscn")
var external_display: Computer

func display_computer(data: ComputerData) -> void:
	clear_display(self)
	var comp_ui = COMPUTER_UI.instantiate() as ComputerUI
	add_child(comp_ui)
	comp_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	comp_ui.load_computer(data)
	open()

func display_computer_on_model(computer: Computer, subviewport: SubViewport, data: ComputerData) -> void:
	external_display = computer
	clear_display(subviewport)
	var comp_ui = COMPUTER_UI.instantiate() as ComputerUI
	subviewport.add_child(comp_ui)
	comp_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	comp_ui.load_computer(data)
	open()
	
## Below is legacy support

func display_desktop(computer_ui : PackedScene):
	if computer_ui:
		var comp_ui = computer_ui.instantiate()
		#if comp_ui is not ComputerUI:
			#push_error("Non computer ui passed to desktop viewer")
		clear_display(self)
		add_child(comp_ui)
		get_child(0).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		#animation_player.play("open")
		open()
		
func display_security(security_ui : PackedScene, cameras : Node):
	if security_ui:
		var sec_ui = security_ui.instantiate()
		#if comp_ui is not ComputerUI:
			#push_error("Non computer ui passed to desktop viewer")
		clear_display(self)
		add_child(sec_ui)
		sec_ui.set_cameras(cameras.get_children())
		get_child(0).set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		#animation_player.play("open")
		open()
		
func clear_display(node):
	if node.get_child_count() > 0:
		node.get_child(0).queue_free()
		
func handle_input(_delta):
	if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("player_interact"):
		print("DESKTOP_VIEWER HANDLED INPUT")
		if external_display:
			external_display.close_computer()
			external_display = null
		if get_child_count() != 0:
			get_child(0).queue_free()
		#animation_player.play("close")
		call_deferred("close")
	
