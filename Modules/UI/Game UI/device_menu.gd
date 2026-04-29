extends UI
class_name DeviceMenu

var first_time : bool = true

#region Tabs
@onready var menu_tabs: PanelContainer = $CanvasLayer2/MarginContainer/HBoxContainer/TextureRect/MarginContainer/VBoxContainer/MenuTabs
var tabs : Array[MenuTabPanel]
@export var focused_tab : int = 0
var tab_assets : Array[Texture] = [
	preload("res://Assets/UI/Device Menu/databaseselect.png"),
	preload("res://Assets/UI/Device Menu/inventoryselect.png"),
	preload("res://Assets/UI/Device Menu/settingsselect.png")
]
@onready var tab_texture: TextureRect = $CanvasLayer2/MarginContainer/HBoxContainer/TextureRect/MarginContainer/VBoxContainer/Tabs/TabTexture
#endregion

@onready var button_move : AudioStreamPlayer = $ButtonMove
@onready var button_confirm : AudioStreamPlayer = $ButtonConfirm

#$MarginContainer/HBoxContainer/TextureRect/MarginContainer/VBoxContainer/MenuTabs/DeviceFiles.select() #TEMP!

func _ready() -> void:
	$CanvasLayer/SubViewportContainer/SubViewport/AnimationPlayer.play("RESET")
	setup_button_sounds(self)
	for tab in menu_tabs.get_children():
		tabs.append(tab)
	select_tab(focused_tab)

func open():
	super.open()
	$CanvasLayer/SubViewportContainer/SubViewport/AnimationPlayer.play("open")
	$CanvasLayer2/MarginContainer.mouse_filter = MOUSE_FILTER_STOP
	select_tab(focused_tab)

func close():
	get_viewport().gui_release_focus()
	$CanvasLayer2/MarginContainer.mouse_filter = MOUSE_FILTER_IGNORE
	$CanvasLayer/SubViewportContainer/SubViewport/AnimationPlayer.play("close")
	if first_time:
		$CanvasLayer/SubViewportContainer/SubViewport/AnimationPlayer.play("RESET")
		first_time = false
		super.close()
	else:
		await get_tree().create_timer(0.4).timeout
		super.close()

#region Tab Functions
func handle_input(_delta):
	super.handle_input(_delta)
	if Input.is_action_just_pressed("ui_tab_forward"):
		focused_tab = (focused_tab + 1) % tabs.size()
		select_tab(focused_tab)
	if Input.is_action_just_pressed("ui_tab_backwards"):
		focused_tab = (focused_tab - 1 + tabs.size()) % tabs.size()
		select_tab(focused_tab)
	if Input.is_action_just_pressed("device_menu"):
		close()
	tabs[focused_tab].handle_input(_delta)
		
func select_tab(selected_tab : int):
	for tab in tabs:
		tab.hide()
	tab_texture.texture = tab_assets[selected_tab]
	tabs[selected_tab].show()
	tabs[selected_tab].select()
	button_move.play()
	
func _on_database_pressed() -> void:
	select_tab(0)
	
func _on_inventory_pressed() -> void:
	select_tab(1)

func _on_settings_pressed() -> void:
	select_tab(2)
#endregion

func setup_button_sounds(node: Node) -> void:
	for child in node.get_children():
		if child is BaseButton:
			child.focus_entered.connect(_on_button_focus_entered)
			child.pressed.connect(_on_button_pressed)
		if child.get_child_count() > 0:
			setup_button_sounds(child)

func _on_button_focus_entered() -> void:
	if button_move:
		if button_move.playing:
			button_move.stop()
		button_move.play()
		
func _on_button_pressed() -> void:
	if button_confirm:
		if button_confirm.playing:
			button_confirm.stop()
		button_confirm.play()
