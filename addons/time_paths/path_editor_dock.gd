@tool
class_name PathEditorDock extends VBoxContainer

signal edit_started(path_data: PathData)
signal edit_stopped
signal vertex_property_edited(vertex_id: int, property: String)
signal path_property_edited(property: String)
signal scrub_time_changed

@onready var _picker: EditorResourcePicker = %EditorResourcePicker
@onready var _edit_button: Button = %EditButton
@onready var _status_label: Label = %Status

# --- path properties (default_speed, path_type, etc) ------------------------
#
# Points a plain EditorInspector at the currently-edited PathData itself.
# vertices/edges are hidden from the editor entirely at the data layer (see
# PathData._validate_property), so this only ever shows path-wide settings,
# not the structural graph data.
@onready var _path_props_label: Label = %PathPropertiesLabel
@onready var _path_props_inspector: EditorInspector = %PathPropertiesInspector

# --- grid snap (tool preference, not saved path data) -----------------------
@onready var _grid_snap_check: CheckBox = %GridSnapCheck
@onready var _grid_snap_size: SpinBox = %GridSnapSize

# --- time scrub preview (tool preference, not saved path data) --------------
#
# Independent of whether a specific PathData is being edited via the picker
# above -- this syncs whatever REAL PathFollower nodes exist in the open
# scene to a shared scrub time (see the plugin's group-based sync, which
# queries the "time_paths_followers" group rather than needing any direct
# reference to this dock or these controls). Real nodes actually move, so
# Godot renders them normally with whatever mesh/visual they have -- no
# custom drawing here. See PathFollower.is_editor_preview for why
# BranchAction/InteractAction don't do anything "real" while this drives
# them.
@onready var _scrub_section: Control = %ScrubSection
@onready var _scrub_enabled_check: CheckBox = %ScrubEnabledCheck
@onready var _scrub_slider: HSlider = %ScrubSlider
@onready var _scrub_time_label: Label = %ScrubTimeLabel
@onready var _scrub_min_time: SpinBox = %ScrubMinTime
@onready var _scrub_max_time: SpinBox = %ScrubMaxTime
@onready var _scrub_play_button: Button = %ScrubPlayButton

var _is_editing: bool = false

# --- vertex inspector --------------------------------------------------
#
# Edits the REAL vertex directly (no duplicate layer -- see conversation:
# a duplicate-based approach was tried first for protection against
# half-finished edits, but caused two real problems -- adding an array
# element via "Add Element" crashed on a null placeholder, and nested
# VertexAction field edits inside the array never re-fired property_edited
# on the outer PathVertex, so they silently never reached the real data.
# The mid-type "click away commits what was typed" behavior this leaves us
# with is acceptable, so it's not worth the complexity to prevent.

@onready var _vertex_section_label: Label = %VertexInspectorLabel
@onready var _vertex_timing_label: Label = %VertexTimingLabel
@onready var _inspector: EditorInspector = %VertexInspector

var _inspected_vertex_id: int = -1


func _init():
	name = "Paths"


func _ready() -> void:
	_picker.resource_changed.connect(_on_resource_changed)
	_edit_button.toggled.connect(_on_edit_toggled)
	_inspector.property_edited.connect(_on_vertex_property_edited)

	_path_props_inspector.property_edited.connect(_on_path_property_edited)

	_scrub_enabled_check.button_pressed = true
	_scrub_enabled_check.toggled.connect(_on_scrub_setting_changed)
	_scrub_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scrub_slider.custom_minimum_size.x = 100.0
	_scrub_slider.value_changed.connect(_on_scrub_slider_changed)
	_scrub_min_time.value_changed.connect(_on_scrub_range_changed)
	_scrub_max_time.value_changed.connect(_on_scrub_range_changed)
	_scrub_play_button.toggled.connect(_on_scrub_play_toggled)
	_update_scrub_slider_range()
	_update_scrub_time_label()
	# Independent of whether a specific PathData is being edited -- this
	# operates on whatever PathFollower nodes exist in the open scene, not
	# on the graph itself, so it's always available.
	_scrub_section.visible = true


func _on_scrub_setting_changed(_pressed: bool) -> void:
	scrub_time_changed.emit()


func _on_scrub_slider_changed(_value: float) -> void:
	_update_scrub_time_label()
	scrub_time_changed.emit()


func _on_scrub_range_changed(_value: float) -> void:
	_update_scrub_slider_range()
	scrub_time_changed.emit()


func _on_scrub_play_toggled(pressed: bool) -> void:
	_scrub_play_button.text = "Pause" if pressed else "Play"


func _update_scrub_slider_range() -> void:
	var min_t := _scrub_min_time.value
	var max_t: float = maxf(_scrub_max_time.value, min_t + 0.01)  # guard against an inverted/degenerate range
	_scrub_slider.min_value = min_t
	_scrub_slider.max_value = max_t
	_update_scrub_time_label()


func _update_scrub_time_label() -> void:
	_scrub_time_label.text = "%.2fs" % _scrub_slider.value


func is_scrub_preview_enabled() -> bool:
	return _scrub_enabled_check.button_pressed


func get_scrub_time() -> float:
	return _scrub_slider.value


func set_scrub_time(t: float) -> void:
	_scrub_slider.value = clampf(t, _scrub_slider.min_value, _scrub_slider.max_value)
	_update_scrub_time_label()


func get_scrub_min_time() -> float:
	return _scrub_min_time.value


func get_scrub_max_time() -> float:
	return _scrub_max_time.value


func is_scrub_playing() -> bool:
	return _scrub_play_button.button_pressed


func _on_resource_changed(resource):
	_edit_button.disabled = (resource == null)
	
	if resource == null:
		_stop_editing()
	else:
		_start_editing()


func _on_edit_toggled(pressed: bool):
	if pressed:
		_start_editing()
	else:
		_stop_editing()

func _start_editing():
	var path_data: PathData = _picker.edited_resource
	if path_data == null:
		_edit_button.button_pressed = false
		return
	_edit_button.set_pressed_no_signal(true)
	_is_editing = true
	_edit_button.text = "Stop Editing"
	update_unsaved_warning(path_data)
	_path_props_label.visible = true
	_path_props_inspector.edit(path_data)
	_path_props_inspector.visible = true  # respect whatever fold state was left, don't force-expand
	edit_started.emit(path_data)

func _stop_editing():
	if not _is_editing:
		return
	_is_editing = false
	_edit_button.set_pressed_no_signal(false)
	_edit_button.text = "Edit Path"
	_status_label.text = ""
	_status_label.remove_theme_color_override("font_color")
	_path_props_inspector.edit(null)
	_path_props_inspector.visible = false
	clear_vertex_inspector()
	edit_stopped.emit()


## Called at edit-start and every frame thereafter (see the plugin's
## _process()) so the warning disappears the instant the resource is
## actually saved -- e.g. via the resource picker's own Save option --
## rather than only refreshing on the next selection change.
func update_unsaved_warning(path_data: PathData) -> void:
	if path_data == null:
		return
	if path_data.resource_path == "":
		_status_label.text = "⚠ Editing: (unsaved) -- will be LOST on editor restart unless saved"
		_status_label.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	else:
		_status_label.text = "Editing: %s" % path_data.resource_path.get_file()
		_status_label.remove_theme_color_override("font_color")


# --- vertex inspector API (called by the plugin on selection change) -------

func show_vertex_inspector(path_data: PathData, vertex_id: int) -> void:
	var vertex := path_data.get_vertex_by_id(vertex_id)
	if vertex == null:
		clear_vertex_inspector()
		return

	_inspected_vertex_id = vertex_id
	_vertex_section_label.text = "Vertex #%d" % vertex_id
	_vertex_section_label.visible = true
	_inspector.edit(vertex)
	_inspector.visible = true
	_update_vertex_timing_label(path_data, vertex_id)


func clear_vertex_inspector() -> void:
	_inspected_vertex_id = -1
	_inspector.edit(null)
	_inspector.visible = false
	_vertex_timing_label.text = ""


## Called by the plugin after edits that could affect the SELECTED vertex's
## timing (a property edit, a completed reposition drag) -- recomputes
## without touching the inspector binding itself. Harmless no-op if
## nothing's currently selected.
##
## NOTE: only wired up at a few specific commit points, not every possible
## graph mutation -- editing an UPSTREAM vertex, or a branch-drag creation/
## deletion elsewhere in the graph, won't refresh an unrelated currently-
## selected vertex's displayed timing. Reselecting the vertex always
## recomputes fresh if the numbers look stale.
func refresh_vertex_timing(path_data: PathData) -> void:
	if _inspected_vertex_id == -1 or path_data == null:
		return
	_update_vertex_timing_label(path_data, _inspected_vertex_id)


func _update_vertex_timing_label(path_data: PathData, vertex_id: int) -> void:
	var timing := path_data.compute_vertex_timing(vertex_id)
	if timing["reachable"]:
		_vertex_timing_label.text = "Arrival: %.4fs   Departure: %.4fs" % [timing["arrival"], timing["departure"]]
	else:
		_vertex_timing_label.text = "Arrival: unreachable"


func _on_vertex_property_edited(property: String) -> void:
	# The inspector already mutated the real vertex directly -- just let the
	# plugin know something changed so it can redraw the 3D overlay (matters
	# most for `position`, which the overlay draws from every frame).
	vertex_property_edited.emit(_inspected_vertex_id, property)


func _on_path_property_edited(property: String) -> void:
	path_property_edited.emit(property)


# --- grid snap API (polled by the plugin during drags) ----------------------

func is_grid_snap_enabled() -> bool:
	return _grid_snap_check.button_pressed


func get_grid_snap_size() -> float:
	return _grid_snap_size.value
