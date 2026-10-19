@tool
extends Node

var editor: ScriptEditor
var replacement_string:String = ": #TIMEVAR\n\tset(value):\n\t\tif globals.time_manager and globals.time_manager.logging:\n\t\t\tglobals.time_manager.timelog(self,\"VARNAME\",VARNAME)\n\t\tVARNAME = value"
var undo_redo: EditorUndoRedoManager

func _ready():
	editor = EditorInterface.get_script_editor()

func _process(delta):
	if Engine.is_editor_hint() and editor.get_current_script() and editor.get_current_script().resource_path != "res://addons/time_tracker/time_tracker_replacement.gd":
		var edit_control:CodeEdit = editor.get_current_editor().get_base_editor()
		var index = edit_control.text.find("@TIMEVAR")
		if index != -1:
			undo_redo.create_action("Adding Time Tracker Autofill")
			var starting_line = edit_control.get_caret_line()
			var var_i = edit_control.text.rfind("var",index)
			var dec_line = edit_control.text.substr(var_i,index-var_i)
			dec_line = dec_line.get_slice(" ",1)
			var var_name = dec_line.substr(0,dec_line.find(":"))
			undo_redo.add_do_method(edit_control,"start_action",TextEdit.ACTION_TYPING)
			undo_redo.add_do_property(edit_control,"text",edit_control.text.replace("@TIMEVAR",replacement_string.replace("VARNAME",var_name)))
			undo_redo.add_do_method(edit_control,"set_caret_line",starting_line + 4)
			undo_redo.add_do_method(edit_control,"set_caret_column",var_name.length()+10)
			undo_redo.add_do_method(edit_control,"start_action",TextEdit.ACTION_NONE)
			undo_redo.add_undo_method(edit_control,"undo")
			undo_redo.commit_action()
