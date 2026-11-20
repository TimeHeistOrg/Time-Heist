@tool
extends VBoxContainer

var folder_path := "res://Content/Documents/Resources/"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reload()
	
func reload() -> void:
	for button in $ScrollContainer/DocumentListContainer.get_children():
		button.queue_free()
	for file_name in DirAccess.get_files_at(folder_path):
		var path := folder_path.path_join(file_name)
		var file := load(path)
		if file is not DocumentInfo:
			push_warning(path + " - non-DocumentInfo object found in Document folder")
			return
		var button := Button.new()
		button.name = file.title
		button.text = file.title
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_down.connect(func():
			EditorInterface.get_file_system_dock().navigate_to_path(path)
			EditorInterface.edit_resource(file)
		)
		$ScrollContainer/DocumentListContainer.add_child(button)
	
func search(text: String = "") -> void:
	for button in $ScrollContainer/DocumentListContainer.get_children():
		var btn: Button = button
		if text == "":
			button.visible = true
		else:
			button.visible = button.text.to_lower().contains(text.to_lower())

func _upload(file_path: String) -> void:
	var text := FileAccess.get_file_as_string(file_path)
	if file_path.ends_with(".csv"):
		pass
	elif file_path.ends_with(".json"):
		pass

func _on_reload_button_down() -> void:
	reload()

func _on_upload_button_down() -> void:
	var file_dialog = EditorFileDialog.new()
	file_dialog.use_native_dialog = true
	file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	file_dialog.add_filter("*.csv, *.json");
	file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	file_dialog.file_selected.connect(_upload)
	EditorInterface.get_base_control().add_child(file_dialog)
	file_dialog.popup_centered_ratio()


func _on_new_button_down() -> void:
	var i := 0
	while true:
		if i == 0:
			if FileAccess.file_exists(folder_path.path_join("new_document.tres")):
				i += 1
			else:
				break
		elif FileAccess.file_exists(folder_path.path_join("new_document (%d).tres" % i)):
			i += 1
		else:
			break
	var newPath: String
	if i == 0:
		newPath = folder_path.path_join("new_document.tres")
	else:
		newPath = folder_path.path_join("new_document (%d).tres" % i)
	var newDocument := DocumentInfo.new()
	ResourceSaver.save(newDocument, newPath)
	EditorInterface.edit_resource(newDocument)
	EditorInterface.select_file(newPath)
	reload()


func _on_search_text_changed(new_text: String) -> void:
	search(new_text)

# Short confirm window to prevent accidental database deletions
var initialPress := false
func _on_clear_button_down() -> void:
	if not initialPress:
		$HBoxContainer/Clear.text = "Sure?"
		$HBoxContainer/Clear.disabled = true
		await get_tree().create_timer(1).timeout
		$HBoxContainer/Clear.text = "2.."
		await get_tree().create_timer(1).timeout
		$HBoxContainer/Clear.text = "1.."
		await get_tree().create_timer(1).timeout
		$HBoxContainer/Clear.text = "Confirm"
		$HBoxContainer/Clear.disabled = false
		initialPress = true
		await get_tree().create_timer(5).timeout
		if initialPress:
			$HBoxContainer/Clear.text = "Clear"
			initialPress = false
	else:
		$HBoxContainer/Clear.text = "..."
		$HBoxContainer/Clear.disabled = true
		initialPress = false
		for file_name in DirAccess.get_files_at(folder_path):
			DirAccess.remove_absolute(folder_path.path_join(file_name))
		reload()
		$HBoxContainer/Clear.text = "Cleared!"
		await get_tree().create_timer(2).timeout
		$HBoxContainer/Clear.text = "Clear"
		$HBoxContainer/Clear.disabled = false
		
