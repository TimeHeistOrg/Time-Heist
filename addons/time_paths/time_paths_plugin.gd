@tool
extends EditorPlugin

var path_editor_dock_scene = preload("res://addons/time_paths/path_editor_dock.tscn")

var _dock: PathEditorDock
var _branch_action_inspector_plugin: EditorInspectorPlugin
var _path_follower_gizmo_plugin: EditorNode3DGizmoPlugin

var _editing_path_data: PathData = null

# View menu item ids, found by dumping the "View" MenuButton's popup on a
# real 4.7 editor (see git history / conversation for how these were found).
# These are Godot-internal and could change between versions -- if the view
# switch silently stops working after a Godot upgrade, this table is the
# first place to re-verify via the same dump approach.
const VIEW_ITEM_TOP := 0
const VIEW_ITEM_PERSPECTIVE := 10
const VIEW_ITEM_ORTHOGONAL := 12
const VIEW_ITEM_LOCK_ROTATION := 53

var _pending_view_switch: bool = false
var _view_menu_popup: PopupMenu = null
var _was_rotation_locked_before_edit: bool = false
var _was_orthogonal_before_edit: bool = false
var _previous_camera_transform: Transform3D

# --- vertex click/drag state ------------------------------------------------

var _dragging_vertex_id: int = -1
var _dragging_vertex_was_new: bool = false
var _dragging_vertex_original_pos: Vector3 = Vector3.ZERO

# The vertex currently shown in the dock's inspector -- separate from drag
# state, since a vertex stays selected after you let go of it.
var _selected_vertex_id: int = -1
const SELECTED_VERTEX_COLOR := Color(0.4, 0.7, 1.0)

# --- stacked-vertex disambiguation ------------------------------------------
#
# Stacks form when a vertex gets deliberately dropped on top of an existing
# one (see design conversation -- landing on an existing vertex always
# creates a new one rather than merging). By default, whichever vertex is
# NEWEST (highest id) wins any ambiguous hit -- you almost always just
# created it on top of an older one, so that's what you're most likely
# trying to grab. Holding right-click (no modifier) on a stack instead opens
# an on-screen menu: move the mouse freely to hover a specific candidate,
# then commit with whatever LEFT-click gesture you'd normally use directly
# on a vertex (plain click = select, click+drag = move, Ctrl+drag = branch
# forward, etc) -- the menu only resolves WHICH vertex "hit_id" refers to,
# everything downstream is the same logic as an unambiguous single-vertex hit.
var _vertex_menu_candidates: Array[int] = []  # ascending by id; empty = menu not open
var _vertex_menu_hover_index: int = -1        # index into the array above, -1 = nothing hovered
var _vertex_menu_screen_pos: Vector2 = Vector2.ZERO  # anchor point (where right-click was pressed)

const STACK_RING_COLOR := Color(1.0, 1.0, 1.0, 0.9)
const STACK_BADGE_COLOR := Color(1.0, 1.0, 1.0)
const STACK_PICKER_BG_COLOR := Color(0.0, 0.0, 0.0, 0.8)
const STACK_PICKER_HIGHLIGHT_COLOR := Color(1.0, 1.0, 1.0, 0.18)

# Axis lock: held while dragging an EXISTING vertex to constrain movement to
# just that axis (the other stays pinned at its pre-drag value), Blender-grab
# style. Tracked via raw key state since InputEventKey and InputEventMouseMotion
# arrive as separate events -- we need to know what's currently held at
# whatever moment a motion event comes in.
var _axis_lock_x: bool = false
var _axis_lock_z: bool = false

# Branch/edge creation via modifier-drag off a vertex. _branch_drag_mode is
# one of the MODE_* constants below, "" when no branch drag is in progress.
var _branch_drag_source_id: int = -1
var _branch_drag_mode: String = ""
var _branch_drag_preview_pos: Vector3 = Vector3.ZERO

# Edges that will be repointed if this drag completes (so the main draw loop
# can hide them) and the vertices those repointed edges will connect the new
# vertex to (so the draw loop can preview the resulting segments). Computed
# once when the drag starts -- the affected edges never depend on cursor
# position, only on the source vertex + mode at drag-start time.
var _branch_drag_hidden_edge_ids: Array[int] = []
var _branch_drag_preview_targets: Array[int] = []

const MODE_FORWARD := "forward"    # Ctrl/Cmd: insert/extend forward
const MODE_BACKWARD := "backward"  # Shift: insert/extend backward
const MODE_BRANCH := "branch"      # Alt: always adds a new sibling edge
const MODE_LOOP := "loop"          # Ctrl/Cmd+Alt: connect to an EXISTING vertex, exempt from the one-incoming-edge rule

const VERTEX_RADIUS_PX := 6.0
const VERTEX_HIT_RADIUS_PX := 10.0
const EDGE_HIT_RADIUS_PX := 6.0
const VERTEX_COLOR := Color(0.2, 0.9, 0.4)
const VERTEX_DRAGGING_COLOR := Color(1.0, 0.85, 0.2)
const EDGE_COLOR := Color(0.6, 0.8, 1.0, 0.8)
const LOOP_EDGE_COLOR := Color(0.85, 0.4, 0.9, 0.9)
const EDGE_WIDTH_PX := 2.0

# Root vertex (PathData.get_start_vertex()) gets a slightly bigger radius
# plus a ring, so it stays identifiable even when it's part of a stack --
# a ring rather than an overridden fill color so it doesn't fight with the
# dragging/selected colors, which still take priority for active feedback.
const ROOT_VERTEX_RADIUS_PX := VERTEX_RADIUS_PX + 3.0
const ROOT_RING_COLOR := Color(1.0, 0.85, 0.1, 0.95)

const PREVIEW_COLOR_FORWARD := Color(1.0, 0.55, 0.2, 0.9)
const PREVIEW_COLOR_BACKWARD := Color(0.3, 0.8, 1.0, 0.9)
const PREVIEW_COLOR_BRANCH := Color(0.7, 0.4, 1.0, 0.9)
const PREVIEW_COLOR_LOOP := Color(0.9, 0.2, 0.3, 0.9)

# --- undo/redo ---------------------------------------------------------
#
# Targeted property/method registration per gesture, not whole-graph
# snapshotting -- an earlier version of this snapshotted the entire
# vertices/edges state before/after each gesture and swapped it wholesale
# via a reconcile-by-id restore. That approach had a fundamental flaw for
# object identity: Godot's own EditorInspector registers per-field undo
# entries (e.g. "Set speed_override") that reference a SPECIFIC object
# instance. Any undo/redo that reconstructed rather than genuinely REUSED
# that same instance (most visibly: undo a creation, redo it -- the
# redone object was a fresh PathVertex.new(), not the original) left those
# entries pointing at an orphaned object, so the property silently failed
# to reapply. The fix, applied throughout: for anything that gets
# destroyed and might later come back (undo of a creation, undo of a
# deletion), BIND the actual object into the undo/redo call so Godot's
# UndoRedo holds a live reference to it and redo/undo re-inserts that EXACT
# instance -- never reconstructs. For scalar field changes on an object
# that persists throughout (a plain reposition drag), a direct
# add_do_property/add_undo_property pair is used, identical to how Godot's
# own inspector undo works, since the object's identity never changes.
#
# See _commit_position_change, _commit_seed_creation,
# _register_delete_vertex_undo, _register_delete_loop_edge_undo, and
# _register_branch_creation_undo for the actual registrations.
#
# One important subtlety this raised: `commit_action()` defaults to
# executing the do-side immediately, but every gesture here already
# mutates the live data directly (for the interactive drag/branch preview
# to work at all) BEFORE undo is ever registered. Registering with the
# default would re-run the do a second time redundantly -- harmless for an
# idempotent property set, but WRONG for insert-style methods (would
# create/insert a duplicate). Every registration below uses
# commit_action(false) for exactly this reason.
#
# Known remaining gap: VertexAction sub-resources inside a vertex's
# `actions` array don't have stable ids the way vertices/edges do, so an
# edit to an individual action's own field (e.g. WaitAction.duration) isn't
# covered by any of the identity-preserving registrations here -- only
# vertex/edge-level fields and the vertex/edge creation/deletion itself.


## restore_snapshot() used to make this necessary broadly; now that
## everything below preserves object identity directly, this is kept as a
## safety net for two narrower things: (1) the selected vertex was actually
## deleted/undone-away by this undo/redo, in which case the inspector needs
## to clear rather than point at nothing; (2) forcing a display refresh in
## case EditorInspector doesn't automatically notice an externally-mutated
## bound object's fields changing. Registered as part of each undo action
## itself (not just run once after the initial commit) since undo/redo can
## fire again much later.
func _refresh_inspector_reference() -> void:
	if _selected_vertex_id == -1 or _editing_path_data == null:
		return
	if _editing_path_data.get_vertex_by_id(_selected_vertex_id) == null:
		_selected_vertex_id = -1
		_dock.clear_vertex_inspector()
	else:
		_dock.show_vertex_inspector(_editing_path_data, _selected_vertex_id)


# Vertices are placed/dragged on this plane. Fixed to world Y=0 for now --
# raycasting against actual scene geometry (so vertices land on the ground
# mesh, say) is a reasonable future improvement but adds a bunch of
# complexity (which colliders/meshes count, what happens over empty space)
# we don't need for the first working version.
const DRAG_PLANE := Plane(Vector3.UP, 0.0)


func _enable_plugin():
	# Add autoloads here.
	pass


func _disable_plugin():
	# Remove autoloads here.
	pass


func _enter_tree():
	set_input_event_forwarding_always_enabled()
	set_force_draw_over_forwarding_enabled()
	_dock = path_editor_dock_scene.instantiate()
	_dock.edit_started.connect(_on_edit_started)
	_dock.edit_stopped.connect(_on_edit_stopped)
	_dock.vertex_property_edited.connect(_on_vertex_property_edited_from_dock)
	_dock.path_property_edited.connect(_on_path_property_edited_from_dock)
	_dock.scrub_time_changed.connect(_on_scrub_time_changed_from_dock)
	add_control_to_bottom_panel(_dock, "Time Paths")

	_branch_action_inspector_plugin = BranchActionInspectorPlugin.new()
	_branch_action_inspector_plugin.time_paths_plugin = self
	add_inspector_plugin(_branch_action_inspector_plugin)

	_path_follower_gizmo_plugin = PathFollowerGizmoPlugin.new()
	add_node_3d_gizmo_plugin(_path_follower_gizmo_plugin)


func _exit_tree():
	if _editing_path_data != null:
		_on_edit_stopped()
	remove_control_from_bottom_panel(_dock)
	_dock.queue_free()
	_dock = null

	remove_inspector_plugin(_branch_action_inspector_plugin)
	_branch_action_inspector_plugin = null

	remove_node_3d_gizmo_plugin(_path_follower_gizmo_plugin)
	_path_follower_gizmo_plugin = null


## Used by BranchActionInspectorPlugin's edge dropdown to know which
## vertex's outgoing edges to offer.
func get_selected_vertex_context() -> Dictionary:
	return {"path_data": _editing_path_data, "vertex_id": _selected_vertex_id}


func _on_edit_started(path_data: PathData) -> void:
	var already_editing: bool = _editing_path_data != null
	_editing_path_data = path_data
	print("[TimePaths] Started editing: ", path_data.resource_path if path_data.resource_path != "" else "(unsaved)")
	if not already_editing:
		_apply_top_down_ortho()
	update_overlays()


func _on_edit_stopped() -> void:
	print("[TimePaths] Stopped editing: ", _editing_path_data.resource_path if _editing_path_data else "(none)")
	_editing_path_data = null
	_pending_view_switch = false
	_selected_vertex_id = -1
	_restore_view_state()
	_refresh_all_follower_gizmos()


## Gizmos don't automatically notice when a PathData resource's internal
## vertices/edges change out from under them (see the known-limitation note
## in PathFollowerGizmoPlugin) -- rather than try to track which followers
## are actually using the path that was just edited, just refresh every
## PathFollower in the scene once editing stops. Cheap and simple, and
## edit sessions aren't frequent enough for this to matter perf-wise.
func _refresh_all_follower_gizmos() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group("time_paths_followers"):
		if node is PathFollower:
			node.update_gizmos()


func _select_vertex(vertex_id: int) -> void:
	_selected_vertex_id = vertex_id
	if vertex_id == -1:
		_dock.clear_vertex_inspector()
	else:
		_dock.show_vertex_inspector(_editing_path_data, vertex_id)
	update_overlays()


func _on_vertex_property_edited_from_dock(_vertex_id: int, _property: String) -> void:
	update_overlays()
	_autosave_if_possible()


func _on_path_property_edited_from_dock(_property: String) -> void:
	_autosave_if_possible()


func _on_scrub_time_changed_from_dock() -> void:
	_sync_or_reset_editor_preview_followers()


## Drives the scrub slider forward when "Play" is toggled -- wraps back to
## 0 at the end of the preview window rather than stopping, so it reads as
## a loop-preview rather than a one-shot that needs re-triggering. Setting
## the dock's scrub time cascades through its own value_changed signal
## into _on_scrub_time_changed_from_dock, so this doesn't need to sync
## followers itself.
##
## Independent of whether a specific PathData is being edited -- scrub-sync
## operates on scene-level PathFollower nodes, not on the graph itself.
func _process(delta: float) -> void:
	# Refreshed every frame rather than hooked to a specific signal --
	# whether EditorInspector's property_edited reliably bubbles up from a
	# NESTED sub-resource field (e.g. WaitAction.duration inside the
	# actions array) the same way it does for a top-level vertex field is
	# genuinely uncertain, and this sidesteps needing to know. The
	# computation itself is cheap (a short walk from root to the selected
	# vertex), and refresh_vertex_timing() already no-ops instantly if
	# nothing's selected or we're not editing.
	if _editing_path_data != null:
		_dock.refresh_vertex_timing(_editing_path_data)
		_dock.update_unsaved_warning(_editing_path_data)

	if not _dock.is_scrub_preview_enabled() or not _dock.is_scrub_playing():
		return
	var new_time := _dock.get_scrub_time() + delta
	if new_time > _dock.get_scrub_max_time():
		new_time = _dock.get_scrub_min_time()
	_dock.set_scrub_time(new_time)


## Syncs every enabled PathFollower in the "time_paths_followers" group
## (real scene nodes -- see PathFollower._enter_tree()) to the dock's
## current scrub time, or resets them to their authored start position if
## the master toggle is off. Group-based rather than needing a direct
## reference in either direction, so it works correctly across a
## game-specific PathFollower subclass too.
func _sync_or_reset_editor_preview_followers() -> void:
	var tree := get_tree()
	if tree == null:
		return

	if _dock.is_scrub_preview_enabled():
		var time := _dock.get_scrub_time()
		for node in tree.get_nodes_in_group("time_paths_followers"):
			if node is PathFollower and node.editor_preview_enabled and node.path_data != null:
				node.is_editor_preview = true
				node.start()
				node.seek(time)
				# The gizmo draws in the node's LOCAL space (relative to its
				# own transform), correctly recomputed fresh each redraw --
				# but setting global_position directly from script here
				# doesn't automatically trigger Godot's gizmo-redraw
				# notification the way dragging a move gizmo in the editor
				# does, so without this the gizmo keeps rendering with a
				# stale transform and visually drags along with the node.
				node.update_gizmos()
	else:
		for node in tree.get_nodes_in_group("time_paths_followers"):
			if node is PathFollower and node.path_data != null:
				node.reset_to_start()
				node.update_gizmos()


## Auto-saves the currently-edited PathData to disk at natural "commit"
## points (drag end, edge created, deletion, inspector field committed) --
## avoids the previous "have to Ctrl+S before pressing Play" friction, and
## sidesteps needing to detect "about to run the scene" at all (Godot
## doesn't expose a clean signal for that to plugins). Only kicks in if the
## resource has already been saved once (has a resource_path) -- a
## brand-new unsaved PathData still needs an explicit first Save/Save As.
func _autosave_if_possible() -> void:
	if _editing_path_data != null and _editing_path_data.resource_path != "":
		ResourceSaver.save(_editing_path_data)


func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:

	if _editing_path_data == null:
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not _vertex_menu_candidates.is_empty():
			# Commit whatever's currently hovered (or the newest candidate,
			# per the same default-to-newest rule, if nothing's hovered --
			# e.g. the user right-clicked then immediately left-clicked
			# without moving over the list first).
			var hit_id: int = _vertex_menu_candidates[_vertex_menu_hover_index] if _vertex_menu_hover_index != -1 else _vertex_menu_candidates[-1]
			var mode := _resolve_drag_mode(event)
			_close_vertex_menu()
			_begin_vertex_interaction(viewport_camera, event.position, hit_id, mode)
			update_overlays()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return _on_viewport_click_pressed(viewport_camera, event.position, _resolve_drag_mode(event))

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		return _on_viewport_click_released(viewport_camera, event.position)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if event.is_command_or_control_pressed():
			_handle_delete_click(viewport_camera, event.position)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		var candidates := _hit_test_all_vertices(viewport_camera, event.position)
		if candidates.size() >= 2:
			_vertex_menu_candidates = candidates
			_vertex_menu_hover_index = -1
			_vertex_menu_screen_pos = event.position
			update_overlays()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		if not _vertex_menu_candidates.is_empty():
			_close_vertex_menu()
			update_overlays()
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventMouseMotion and not _vertex_menu_candidates.is_empty():
		_update_vertex_menu_hover(event.position)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if _cancel_current_action():
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		return EditorPlugin.AFTER_GUI_INPUT_PASS

	if event is InputEventKey and event.keycode == KEY_X:
		_axis_lock_x = event.pressed
	if event is InputEventKey and event.keycode == KEY_Z:
		_axis_lock_z = event.pressed

	if event is InputEventMouseMotion and (_dragging_vertex_id != -1 or _branch_drag_source_id != -1):
		_on_viewport_drag(viewport_camera, event.position)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


## Cancels whatever drag is currently in progress, if any. Returns true if
## something was actually cancelled (so the caller knows whether to consume
## the Escape keypress or let it pass through to normal editor handling).
func _cancel_current_action() -> bool:
	if not _vertex_menu_candidates.is_empty():
		_close_vertex_menu()
		update_overlays()
		return true

	if _dragging_vertex_id != -1:
		if _dragging_vertex_was_new:
			# This vertex only exists because this same press created it
			# (the empty-graph seed case) -- cancelling should undo that
			# creation entirely, not just stop dragging it.
			_editing_path_data.remove_vertex(_dragging_vertex_id)
		else:
			var vertex := _editing_path_data.get_vertex_by_id(_dragging_vertex_id)
			if vertex != null:
				vertex.position = _dragging_vertex_original_pos
		_dragging_vertex_id = -1
		_dragging_vertex_was_new = false
		update_overlays()
		return true

	if _branch_drag_source_id != -1:
		# Branch drags don't touch PathData until release, so cancelling is
		# just clearing state -- nothing to undo.
		_branch_drag_source_id = -1
		_branch_drag_mode = ""
		_branch_drag_hidden_edge_ids.clear()
		_branch_drag_preview_targets.clear()
		update_overlays()
		return true

	return false


## Maps held modifier keys to one of the MODE_* constants, or "" if none of
## the recognized combos are held (plain click / unrecognized combo).
## Loop (Ctrl+Alt) is checked before plain Ctrl so it takes priority.
func _resolve_drag_mode(event: InputEventWithModifiers) -> String:
	if event.is_command_or_control_pressed() and event.alt_pressed:
		return MODE_LOOP
	if event.is_command_or_control_pressed():
		return MODE_FORWARD
	if event.shift_pressed:
		return MODE_BACKWARD
	if event.alt_pressed:
		return MODE_BRANCH
	return ""


func _on_viewport_click_pressed(camera: Camera3D, screen_pos: Vector2, mode: String) -> int:
	var hit_id := _hit_test_vertex(camera, screen_pos)
	_begin_vertex_interaction(camera, screen_pos, hit_id, mode)
	update_overlays()
	return EditorPlugin.AFTER_GUI_INPUT_STOP


## The actual "start interacting with this specific vertex (or empty space)"
## logic -- shared by the normal unambiguous-hit path and by whatever the
## vertex menu resolves to, so both end up going through exactly the same
## behavior.
func _begin_vertex_interaction(camera: Camera3D, screen_pos: Vector2, hit_id: int, mode: String) -> void:
	if hit_id != -1:
		_select_vertex(hit_id)
		if mode == "":
			# Reposition: no snapshot needed here -- committed via a direct
			# add_do_property/add_undo_property on `position` at release,
			# using _dragging_vertex_original_pos captured below (a plain
			# Vector3 VALUE, not an object reference, so it can't go stale
			# the way an object-holding snapshot could).
			_dragging_vertex_id = hit_id
			_dragging_vertex_was_new = false
			_dragging_vertex_original_pos = _editing_path_data.get_vertex_by_id(hit_id).position
		else:
			_branch_drag_source_id = hit_id
			_branch_drag_mode = mode
			_branch_drag_preview_pos = _project_to_drag_plane(camera, screen_pos)
			_compute_branch_drag_preview_extras(hit_id, mode)
	elif mode == "":
		# Plain click on empty space: only allowed to create the seed vertex
		# when the graph is completely empty. Every vertex after that must
		# be attached via a modifier-drag off an existing one -- no more
		# free-floating vertices from plain clicks.
		if _editing_path_data.vertices.is_empty():
			var world_pos := _apply_grid_snap(_project_to_drag_plane(camera, screen_pos))
			var new_vertex := _editing_path_data.add_vertex(world_pos)
			_dragging_vertex_id = new_vertex.id
			_dragging_vertex_was_new = true
			_select_vertex(new_vertex.id)
		else:
			# Genuine empty-space click with vertices already present: no-op
			# on the graph, but does deselect -- the "click away" gesture.
			_select_vertex(-1)
	# else: a modifier was held but the press missed every vertex -- no-op,
	# rather than guessing what the user meant to drag from.


func _close_vertex_menu() -> void:
	_vertex_menu_candidates.clear()
	_vertex_menu_hover_index = -1


func _update_vertex_menu_hover(screen_pos: Vector2) -> void:
	var index := _vertex_menu_row_at(screen_pos)
	if index != _vertex_menu_hover_index:
		_vertex_menu_hover_index = index
		update_overlays()


## Shared by both the draw pass and hover hit-testing so their layout math
## can never drift apart (a lesson from the earlier text-position bug).
func _vertex_menu_geometry() -> Dictionary:
	var line_height := float(ThemeDB.fallback_font_size) + 8.0
	var panel_size := Vector2(140.0, line_height * _vertex_menu_candidates.size() + 8.0)
	var anchor := _vertex_menu_screen_pos + Vector2(16.0, -panel_size.y * 0.5)
	return {"anchor": anchor, "line_height": line_height, "panel_size": panel_size}


func _vertex_menu_row_at(screen_pos: Vector2) -> int:
	if _vertex_menu_candidates.is_empty():
		return -1
	var geo := _vertex_menu_geometry()
	var anchor: Vector2 = geo["anchor"]
	var line_height: float = geo["line_height"]
	var panel_size: Vector2 = geo["panel_size"]
	var panel_rect := Rect2(anchor - Vector2(4.0, 4.0), panel_size)
	if not panel_rect.has_point(screen_pos):
		return -1
	var idx := int(floor((screen_pos.y - anchor.y + 2.0) / line_height))
	return clamp(idx, 0, _vertex_menu_candidates.size() - 1)


## Every vertex whose screen position falls within the hit radius of
## screen_pos, sorted ascending by id.
func _hit_test_all_vertices(camera: Camera3D, screen_pos: Vector2) -> Array[int]:
	var result: Array[int] = []
	for v in _editing_path_data.vertices:
		var screen_v := camera.unproject_position(v.position)
		if screen_v.distance_to(screen_pos) <= VERTEX_HIT_RADIUS_PX:
			result.append(v.id)
	result.sort()
	return result


func _on_viewport_click_released(camera: Camera3D, screen_pos: Vector2) -> int:
	if _dragging_vertex_id != -1:
		var vertex_id := _dragging_vertex_id
		var was_new := _dragging_vertex_was_new
		var original_pos := _dragging_vertex_original_pos
		_dragging_vertex_id = -1
		_dragging_vertex_was_new = false
		update_overlays()
		if was_new:
			_commit_seed_creation(vertex_id)
		else:
			_commit_position_change(vertex_id, original_pos)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	if _branch_drag_source_id != -1:
		_finish_branch_drag(camera, screen_pos)
		return EditorPlugin.AFTER_GUI_INPUT_STOP

	return EditorPlugin.AFTER_GUI_INPUT_PASS


## Reposition-drag undo: a direct property toggle on the SAME vertex object
## throughout, exactly like Godot's own per-field inspector undo -- no
## object duplication or array-swapping involved, so there's nothing that
## could go stale.
func _commit_position_change(vertex_id: int, old_pos: Vector3) -> void:
	var vertex := _editing_path_data.get_vertex_by_id(vertex_id)
	if vertex == null or vertex.position == old_pos:
		return  # nothing actually moved

	var ur := get_undo_redo()
	ur.create_action("Move Vertex")
	ur.add_do_property(vertex, "position", vertex.position)
	ur.add_do_method(self, "update_overlays")
	ur.add_undo_property(vertex, "position", old_pos)
	ur.add_undo_method(self, "update_overlays")
	ur.commit_action(false)  # false: the live position is already set from the drag -- don't reapply
	_autosave_if_possible()


## Seed-vertex creation undo: the vertex already exists live (created
## immediately when the graph was empty and the seed click landed). Binds
## the ACTUAL object into the redo call -- remove_vertex() for undo just
## takes it out of the array (the object itself survives, held by this
## undo/redo action), insert_vertex() for redo puts that SAME instance
## back, rather than reconstructing a fresh one from id+position.
func _commit_seed_creation(vertex_id: int) -> void:
	var vertex := _editing_path_data.get_vertex_by_id(vertex_id)
	if vertex == null:
		return

	var ur := get_undo_redo()
	ur.create_action("Create Seed Vertex")
	ur.add_do_method(_editing_path_data, "insert_vertex", vertex)
	ur.add_do_method(self, "update_overlays")
	ur.add_do_method(self, "_refresh_inspector_reference")
	ur.add_undo_method(_editing_path_data, "remove_vertex", vertex_id)
	ur.add_undo_method(self, "update_overlays")
	ur.add_undo_method(self, "_refresh_inspector_reference")
	ur.commit_action(false)  # false: it already exists live from the click -- don't insert it again
	_autosave_if_possible()


func _on_viewport_drag(camera: Camera3D, screen_pos: Vector2) -> void:
	if _dragging_vertex_id != -1:
		var vertex := _editing_path_data.get_vertex_by_id(_dragging_vertex_id)
		if vertex == null:
			_dragging_vertex_id = -1
			return
		var new_pos := _apply_grid_snap(_project_to_drag_plane(camera, screen_pos))
		if not _dragging_vertex_was_new:
			new_pos = _apply_axis_lock(new_pos, _dragging_vertex_original_pos)
		vertex.position = new_pos

	elif _branch_drag_source_id != -1:
		if _branch_drag_mode == MODE_LOOP:
			# Loop mode is the only one where landing on an existing vertex
			# means something -- snap the preview to whatever's hovered.
			var hovered_id := _hit_test_vertex(camera, screen_pos)
			if hovered_id != -1 and hovered_id != _branch_drag_source_id:
				_branch_drag_preview_pos = _editing_path_data.get_vertex_by_id(hovered_id).position
			else:
				_branch_drag_preview_pos = _project_to_drag_plane(camera, screen_pos)
		else:
			# Forward/backward/branch always create a brand-new vertex on
			# release regardless of what's under the cursor -- axis lock
			# anchors to the SOURCE vertex's position (the "previous vertex"
			# you're dragging off), not a drag-start snapshot, since that's
			# the useful reference point when placing a brand-new one.
			_branch_drag_preview_pos = _resolve_branch_drag_target_pos(camera, screen_pos, _branch_drag_source_id)

	update_overlays()


## Shared by the live preview and the final release so they always agree
## exactly -- recomputed from the actual event position each time rather
## than trusting a possibly-one-frame-stale stored preview value.
func _resolve_branch_drag_target_pos(camera: Camera3D, screen_pos: Vector2, source_id: int) -> Vector3:
	var pos := _apply_grid_snap(_project_to_drag_plane(camera, screen_pos))
	var source_v := _editing_path_data.get_vertex_by_id(source_id)
	if source_v != null:
		pos = _apply_axis_lock(pos, source_v.position)
	return pos


func _finish_branch_drag(camera: Camera3D, screen_pos: Vector2) -> void:
	var source_id := _branch_drag_source_id
	var mode := _branch_drag_mode
	_branch_drag_source_id = -1
	_branch_drag_mode = ""
	_branch_drag_hidden_edge_ids.clear()
	_branch_drag_preview_targets.clear()

	if mode == MODE_LOOP:
		var target_id := _hit_test_vertex(camera, screen_pos)
		if target_id == -1 or target_id == source_id:
			# Loop mode only makes sense between two existing, distinct
			# vertices -- empty space or dropping back on the source cancels.
			update_overlays()
			return
		if not _edge_exists(source_id, target_id):
			var e := _editing_path_data.add_edge(source_id, target_id)
			e.is_loop_edge = true
			_register_create_loop_edge_undo(e)
		update_overlays()
		return

	# Forward/backward/branch all create a fresh vertex at the drop position,
	# regardless of what's under the cursor.
	var world_pos := _resolve_branch_drag_target_pos(camera, screen_pos, source_id)
	var new_vertex := _editing_path_data.add_vertex(world_pos)
	var new_edge: PathEdge
	var repoint_field := ""
	var repoint_old: Dictionary = {}

	match mode:
		MODE_FORWARD:
			var info := _apply_forward_connection(source_id, new_vertex.id)
			new_edge = info["new_edge"]
			repoint_field = info["field"]
			repoint_old = info["old_values"]
		MODE_BACKWARD:
			var info := _apply_backward_connection(source_id, new_vertex.id)
			new_edge = info["new_edge"]
			repoint_field = info["field"]
			repoint_old = info["old_values"]
		MODE_BRANCH:
			new_edge = _editing_path_data.add_edge(source_id, new_vertex.id)

	_select_vertex(new_vertex.id)
	update_overlays()
	_register_branch_creation_undo("Create Path Vertex", new_vertex, new_edge, repoint_field, repoint_old)


## Computes, once at drag-start, which existing edges an insert/reroute
## drag will affect -- so the draw loop can hide the originals and preview
## the resulting segments while the user is still dragging, before anything
## is actually committed to PathData. Branch and loop modes never rewrite
## existing edges, so they leave both lists empty.
func _compute_branch_drag_preview_extras(source_id: int, mode: String) -> void:
	_branch_drag_hidden_edge_ids.clear()
	_branch_drag_preview_targets.clear()

	match mode:
		MODE_FORWARD:
			var outgoing := _editing_path_data.get_outgoing_edges(source_id).filter(func(e): return not e.is_loop_edge)
			for e in outgoing:
				_branch_drag_hidden_edge_ids.append(e.id)
				_branch_drag_preview_targets.append(e.to_vertex)
		MODE_BACKWARD:
			var incoming := _editing_path_data.get_incoming_edges(source_id).filter(func(e): return not e.is_loop_edge)
			for e in incoming:
				_branch_drag_hidden_edge_ids.append(e.id)
				_branch_drag_preview_targets.append(e.from_vertex)
		_:
			pass  # MODE_BRANCH and MODE_LOOP never rewrite existing edges


## Ctrl/Cmd-drag off A: extend forward, inserting into or forking the
## existing (non-loop) outgoing structure as needed. Loop edges are left
## alone -- they're deliberate, specific connections, not part of the
## "normal" chain this operation reshapes.
##
## Returns {"new_edge": PathEdge, "field": "to_vertex"|"from_vertex"|"",
## "old_values": {edge_id: old_value}} describing what to feed
## _register_branch_creation_undo -- "field"/"old_values" are empty when
## nothing existing got repointed (the plain zero-outgoing case).
func _apply_forward_connection(source_id: int, new_id: int) -> Dictionary:
	var outgoing := _editing_path_data.get_outgoing_edges(source_id).filter(func(e): return not e.is_loop_edge)

	if outgoing.is_empty():
		var new_edge := _editing_path_data.add_edge(source_id, new_id)
		return {"new_edge": new_edge, "field": "", "old_values": {}}
	elif outgoing.size() == 1:
		var edge: PathEdge = outgoing[0]
		var old_target := edge.to_vertex
		_editing_path_data.set_edge_to_vertex(edge.id, new_id)  # A --edge--> B (repointed)
		var new_edge := _editing_path_data.add_edge(new_id, old_target)  # B -> C (fresh edge)
		return {"new_edge": new_edge, "field": "to_vertex", "old_values": {edge.id: old_target}}
	else:
		var old_values: Dictionary = {}
		for edge in outgoing:
			old_values[edge.id] = edge.from_vertex
			_editing_path_data.set_edge_from_vertex(edge.id, new_id)  # each child now originates from B
		var new_edge := _editing_path_data.add_edge(source_id, new_id)  # A -> B (fresh edge)
		return {"new_edge": new_edge, "field": "from_vertex", "old_values": old_values}


## Shift-drag off A: extend backward, symmetric to _apply_forward_connection.
func _apply_backward_connection(source_id: int, new_id: int) -> Dictionary:
	var incoming := _editing_path_data.get_incoming_edges(source_id).filter(func(e): return not e.is_loop_edge)

	if incoming.is_empty():
		var new_edge := _editing_path_data.add_edge(new_id, source_id)  # B -> A, B becomes the new root
		return {"new_edge": new_edge, "field": "", "old_values": {}}
	else:
		# Invariant guarantees at most one non-loop incoming edge; defensive
		# to only ever touch the first if that's ever violated.
		var edge: PathEdge = incoming[0]
		var old_target := edge.to_vertex
		_editing_path_data.set_edge_to_vertex(edge.id, new_id)  # P --edge--> B (repointed)
		var new_edge := _editing_path_data.add_edge(new_id, source_id)  # B -> A (fresh edge)
		return {"new_edge": new_edge, "field": "to_vertex", "old_values": {edge.id: old_target}}


## Registers undo for a branch-drag creation: a new vertex + a new edge
## connecting it, optionally alongside repointing a set of EXISTING edges
## (repoint_field/repoint_old empty if nothing was repointed -- the plain
## Alt-branch case, or a fresh Ctrl/Shift extension with nothing to insert
## into). Repointed edges get simple property toggles (never destroyed, so
## identity is trivially preserved); the new vertex/edge are bound as
## actual objects and re-inserted on redo rather than reconstructed --
## same reasoning as _commit_seed_creation/_register_delete_vertex_undo.
##
## Uses the non-cascading remove_vertex_only()/explicit remove_edge() for
## undo rather than the normal cascading remove_vertex(), specifically to
## avoid a same-action ordering hazard: at the moment undo begins, a
## repointed edge may still be pointing AT the vertex being removed (its
## field hasn't reverted yet) -- a cascading removal could incorrectly
## sweep it up depending on which order same-action undo operations happen
## to execute in, which isn't something to depend on.
func _register_branch_creation_undo(action_name: String, new_vertex: PathVertex, new_edge: PathEdge, repoint_field: String, repoint_old: Dictionary) -> void:
	var pd := _editing_path_data
	var ur := get_undo_redo()
	ur.create_action(action_name)

	for edge_id in repoint_old:
		var edge := pd.get_edge_by_id(edge_id)
		if edge == null:
			continue
		ur.add_do_property(edge, repoint_field, edge.get(repoint_field))
		ur.add_undo_property(edge, repoint_field, repoint_old[edge_id])

	ur.add_do_method(pd, "insert_vertex", new_vertex)
	ur.add_do_method(pd, "insert_edge", new_edge)
	ur.add_do_method(self, "update_overlays")
	ur.add_do_method(self, "_refresh_inspector_reference")

	ur.add_undo_method(pd, "remove_edge", new_edge.id)
	ur.add_undo_method(pd, "remove_vertex_only", new_vertex.id)
	ur.add_undo_method(self, "update_overlays")
	ur.add_undo_method(self, "_refresh_inspector_reference")

	ur.commit_action(false)  # already applied live -- don't reapply
	_autosave_if_possible()


func _register_create_loop_edge_undo(edge: PathEdge) -> void:
	var pd := _editing_path_data
	var ur := get_undo_redo()
	ur.create_action("Create Loop Edge")
	ur.add_do_method(pd, "insert_edge", edge)
	ur.add_do_method(self, "update_overlays")
	ur.add_undo_method(pd, "remove_edge", edge.id)
	ur.add_undo_method(self, "update_overlays")
	ur.commit_action(false)
	_autosave_if_possible()


func _edge_exists(from_id: int, to_id: int) -> bool:
	for e in _editing_path_data.get_outgoing_edges(from_id):
		if e.to_vertex == to_id:
			return true
	return false


# --- deletion (Ctrl/Cmd + right-click) --------------------------------------

func _handle_delete_click(camera: Camera3D, screen_pos: Vector2) -> void:
	var vertex_id := _hit_test_vertex(camera, screen_pos)
	if vertex_id != -1:
		var info = _delete_vertex(vertex_id)
		update_overlays()
		if info != null:
			_register_delete_vertex_undo(vertex_id, info)
		return

	var loop_edge_id := _hit_test_loop_edge(camera, screen_pos)
	if loop_edge_id != -1:
		var edge := _editing_path_data.get_edge_by_id(loop_edge_id)
		if edge != null:
			_editing_path_data.remove_edge(loop_edge_id)
			update_overlays()
			_register_delete_loop_edge_undo(loop_edge_id, edge)
	# Structural (non-loop) edges aren't directly deletable by clicking the
	# line -- they only exist as a byproduct of vertex structure, so the
	# only way to remove one is to delete one of its endpoint vertices.


## Repointed child edges get simple property toggles (they're never
## destroyed, so identity is trivially fine). The deleted vertex and its
## own now-orphaned edges (the old parent link, any loop edges touching it)
## are held by BINDING the actual objects into the undo call -- redo
## deletes them again, undo re-inserts the SAME instances (never
## reconstructing), so anything else referencing them (most commonly
## Godot's own automatic per-field inspector undo) stays valid.
func _register_delete_vertex_undo(vertex_id: int, info: Dictionary) -> void:
	var pd := _editing_path_data
	var repointed_from: Dictionary = info["repointed_from"]
	var removed_vertex: PathVertex = info["removed_vertex"]
	var removed_edges: Array = info["removed_edges"]

	var ur := get_undo_redo()
	ur.create_action("Delete Vertex")

	for edge_id in repointed_from:
		var edge := pd.get_edge_by_id(edge_id)
		if edge == null:
			continue
		ur.add_do_property(edge, "from_vertex", edge.from_vertex)
		ur.add_undo_property(edge, "from_vertex", repointed_from[edge_id])

	ur.add_do_method(pd, "remove_vertex", vertex_id)
	ur.add_do_method(self, "update_overlays")
	ur.add_do_method(self, "_refresh_inspector_reference")
	ur.add_undo_method(pd, "insert_vertex", removed_vertex)
	for e in removed_edges:
		ur.add_undo_method(pd, "insert_edge", e)
	ur.add_undo_method(self, "update_overlays")
	ur.add_undo_method(self, "_refresh_inspector_reference")

	ur.commit_action(false)  # false: already applied live -- don't reapply
	_autosave_if_possible()


func _register_delete_loop_edge_undo(edge_id: int, edge: PathEdge) -> void:
	var pd := _editing_path_data
	var ur := get_undo_redo()
	ur.create_action("Delete Loop Edge")
	ur.add_do_method(pd, "remove_edge", edge_id)
	ur.add_do_method(self, "update_overlays")
	ur.add_undo_method(pd, "insert_edge", edge)
	ur.add_undo_method(self, "update_overlays")
	ur.commit_action(false)
	_autosave_if_possible()


## Deletes a vertex, splicing the graph back together so nothing gets
## orphaned:
##  - leaf (no children): just removed.
##  - middle vertex (one parent, 1+ children): parent is reconnected
##    directly to each child, preserving each child edge's identity.
##  - root (no non-loop incoming edge): deletion is disallowed entirely --
##    there's no parent to splice onto, and rather than guess a policy for
##    that, the user is expected to create a new PathData to start over.
## Any loop edges touching the deleted vertex (either direction) are simply
## dropped, since they carry no subtree of their own to preserve.
##
## Returns a Dictionary describing what changed (used to register
## object-preserving undo), or null if refused (root deletion).
func _delete_vertex(vertex_id: int) -> Variant:
	var incoming := _editing_path_data.get_incoming_edges(vertex_id).filter(func(e): return not e.is_loop_edge)

	if incoming.is_empty():
		push_warning("[TimePaths] Cannot delete the root vertex. Create a new PathData resource to start over.")
		return null

	var parent_id: int = incoming[0].from_vertex

	var outgoing := _editing_path_data.get_outgoing_edges(vertex_id).filter(func(e): return not e.is_loop_edge)
	var repointed_from: Dictionary = {}  # edge_id -> original from_vertex, for undo
	for child_edge in outgoing:
		repointed_from[child_edge.id] = child_edge.from_vertex
		_editing_path_data.set_edge_from_vertex(child_edge.id, parent_id)

	# Defensive cleanup: don't leave drag/selection state pointing at a
	# vertex we're about to remove.
	if _dragging_vertex_id == vertex_id:
		_dragging_vertex_id = -1
	if _branch_drag_source_id == vertex_id:
		_branch_drag_source_id = -1
		_branch_drag_mode = ""
		_branch_drag_hidden_edge_ids.clear()
		_branch_drag_preview_targets.clear()
	if _selected_vertex_id == vertex_id:
		_select_vertex(-1)
	if vertex_id in _vertex_menu_candidates:
		_close_vertex_menu()

	var removed_vertex := _editing_path_data.get_vertex_by_id(vertex_id)
	var removed_edges: Array = _editing_path_data.edges.filter(func(e): return e.from_vertex == vertex_id or e.to_vertex == vertex_id)

	# remove_vertex() also drops every edge still referencing vertex_id --
	# that's the (now-repointed-away-from) parent edge, plus any loop edges
	# touching it in either direction.
	_editing_path_data.remove_vertex(vertex_id)

	return {
		"removed_vertex": removed_vertex,
		"removed_edges": removed_edges,
		"repointed_from": repointed_from,
	}


func _hit_test_loop_edge(camera: Camera3D, screen_pos: Vector2) -> int:
	var closest_id := -1
	var closest_dist := EDGE_HIT_RADIUS_PX
	for e in _editing_path_data.edges:
		if not e.is_loop_edge:
			continue
		var from_v := _editing_path_data.get_vertex_by_id(e.from_vertex)
		var to_v := _editing_path_data.get_vertex_by_id(e.to_vertex)
		if from_v == null or to_v == null:
			continue
		var p1 := camera.unproject_position(from_v.position)
		var p2 := camera.unproject_position(to_v.position)
		var dist := _distance_point_to_segment(screen_pos, p1, p2)
		if dist <= closest_dist:
			closest_dist = dist
			closest_id = e.id
	return closest_id


func _distance_point_to_segment(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var len_sq := ab.length_squared()
	if len_sq == 0.0:
		return p.distance_to(a)
	var t: float = clamp((p - a).dot(ab) / len_sq, 0.0, 1.0)
	var closest := a + ab * t
	return p.distance_to(closest)


func _apply_grid_snap(pos: Vector3) -> Vector3:
	if not _dock.is_grid_snap_enabled():
		return pos
	var size := _dock.get_grid_snap_size()
	if size <= 0.0:
		return pos
	return pos.snapped(Vector3(size, size, size))


## Constrains pos to move only along whichever axis is held (X or Z),
## pinning the other coordinate to its exact pre-drag value -- if both are
## somehow held simultaneously, movement is fully locked (returns anchor).
func _apply_axis_lock(pos: Vector3, anchor: Vector3) -> Vector3:
	if _axis_lock_x and _axis_lock_z:
		return anchor
	if _axis_lock_x:
		pos.z = anchor.z
	elif _axis_lock_z:
		pos.x = anchor.x
	return pos


func _project_to_drag_plane(camera: Camera3D, screen_pos: Vector2) -> Vector3:
	var ray_origin := camera.project_ray_origin(screen_pos)
	var ray_dir := camera.project_ray_normal(screen_pos)
	var hit = DRAG_PLANE.intersects_ray(ray_origin, ray_dir)
	# Camera is locked top-down, so the ray should never be parallel to the
	# ground plane -- but fall back to the ray origin rather than crashing
	# if that assumption is ever violated (e.g. before the view switch lands).
	return hit if hit != null else ray_origin


## When multiple vertices are stacked at the same spot, defaults to the
## NEWEST one (highest id) rather than whichever happens to be a few pixels
## closer -- you almost always just created it on top of an older one. Use
## the right-click hold menu (see _vertex_menu_candidates) to target a
## specific other one in the stack.
func _hit_test_vertex(camera: Camera3D, screen_pos: Vector2) -> int:
	var candidates := _hit_test_all_vertices(camera, screen_pos)
	return candidates[-1] if not candidates.is_empty() else -1


func _preview_color_for_mode(mode: String) -> Color:
	match mode:
		MODE_FORWARD:
			return PREVIEW_COLOR_FORWARD
		MODE_BACKWARD:
			return PREVIEW_COLOR_BACKWARD
		MODE_BRANCH:
			return PREVIEW_COLOR_BRANCH
		MODE_LOOP:
			return PREVIEW_COLOR_LOOP
		_:
			return EDGE_COLOR


func _forward_3d_force_draw_over_viewport(overlay: Control) -> void:
	if _editing_path_data == null:
		return
	var camera := EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	if camera == null:
		return

	# Computed once and shared by both edge-overlap grouping and vertex-stack
	# drawing below, so "these look like the same spot" always means the
	# exact same thing in both places.
	var clusters := _cluster_vertices_by_screen_pos(camera)
	var cluster_index_by_vertex: Dictionary = {}
	var cluster_centers: Array[Vector2] = []
	for i in clusters.size():
		var cluster: Array[int] = clusters[i]
		var center := Vector2.ZERO
		for id in cluster:
			center += camera.unproject_position(_editing_path_data.get_vertex_by_id(id).position)
		center /= cluster.size()
		cluster_centers.append(center)
		for id in cluster:
			cluster_index_by_vertex[id] = i

	# Group edges by (from_cluster, to_cluster) -- direction matters, so an
	# edge only overlaps another if BOTH endpoints land in the same clusters
	# in the same order. Overlapping edges draw once with a count badge
	# instead of stacking identical-looking lines on top of each other.
	var edge_groups: Dictionary = {}  # Vector2i(from_cluster, to_cluster) -> Array[PathEdge]
	for e in _editing_path_data.edges:
		if e.id in _branch_drag_hidden_edge_ids:
			continue  # about to be repointed by the in-progress drag -- shown as a preview segment instead
		if not cluster_index_by_vertex.has(e.from_vertex) or not cluster_index_by_vertex.has(e.to_vertex):
			continue
		var key := Vector2i(cluster_index_by_vertex[e.from_vertex], cluster_index_by_vertex[e.to_vertex])
		if not edge_groups.has(key):
			edge_groups[key] = []
		edge_groups[key].append(e)

	for key in edge_groups:
		var group: Array = edge_groups[key]
		var p1: Vector2 = cluster_centers[key.x]
		var p2: Vector2 = cluster_centers[key.y]
		var has_loop := false
		for e in group:
			if e.is_loop_edge:
				has_loop = true
				break
		var color := LOOP_EDGE_COLOR if has_loop else EDGE_COLOR
		overlay.draw_line(p1, p2, color, EDGE_WIDTH_PX)
		_draw_edge_arrow(overlay, p1, p2, color)
		if group.size() > 1:
			_draw_edge_count_badge(overlay, p1, p2, group.size(), color)

	if _branch_drag_source_id != -1:
		var source_v := _editing_path_data.get_vertex_by_id(_branch_drag_source_id)
		if source_v != null:
			var preview_color := _preview_color_for_mode(_branch_drag_mode)
			var source_screen := camera.unproject_position(source_v.position)
			var cursor_screen := camera.unproject_position(_branch_drag_preview_pos)

			overlay.draw_line(source_screen, cursor_screen, preview_color, EDGE_WIDTH_PX)
			# MODE_BACKWARD's real resulting edge points TOWARD the source
			# (B -> A), so the preview arrow should too, not source -> cursor.
			if _branch_drag_mode == MODE_BACKWARD:
				_draw_edge_arrow(overlay, cursor_screen, source_screen, preview_color)
			else:
				_draw_edge_arrow(overlay, source_screen, cursor_screen, preview_color)

			# Preview the "far side" segments too -- what each hidden edge
			# will look like once repointed to/from the new vertex.
			for target_id in _branch_drag_preview_targets:
				var target_v := _editing_path_data.get_vertex_by_id(target_id)
				if target_v != null:
					var target_screen := camera.unproject_position(target_v.position)
					overlay.draw_line(cursor_screen, target_screen, preview_color, EDGE_WIDTH_PX)
					if _branch_drag_mode == MODE_BACKWARD:
						_draw_edge_arrow(overlay, target_screen, cursor_screen, preview_color)
					else:
						_draw_edge_arrow(overlay, cursor_screen, target_screen, preview_color)

	var root_vertex := _editing_path_data.get_start_vertex()
	var root_id: int = root_vertex.id if root_vertex != null else -1

	for i in clusters.size():
		var cluster: Array[int] = clusters[i]
		if cluster.size() == 1:
			var v := _editing_path_data.get_vertex_by_id(cluster[0])
			var color := VERTEX_COLOR
			if v.id == _dragging_vertex_id:
				color = VERTEX_DRAGGING_COLOR
			elif v.id == _selected_vertex_id:
				color = SELECTED_VERTEX_COLOR
			var radius := VERTEX_RADIUS_PX
			if v.id == root_id:
				radius = ROOT_VERTEX_RADIUS_PX
				overlay.draw_arc(cluster_centers[i], radius + 3.0, 0.0, TAU, 24, ROOT_RING_COLOR, 2.0)
			overlay.draw_circle(cluster_centers[i], radius, color)
		else:
			_draw_vertex_stack(overlay, camera, cluster, cluster_centers[i], root_id)

	if not _vertex_menu_candidates.is_empty():
		_draw_vertex_menu(overlay)


## Groups vertices whose screen positions fall within VERTEX_HIT_RADIUS_PX of
## each other -- the same threshold used for click hit-testing, so "looks
## stacked" and "click here is ambiguous" always agree.
func _cluster_vertices_by_screen_pos(camera: Camera3D) -> Array:
	var clusters: Array = []
	var assigned: Dictionary = {}
	for v in _editing_path_data.vertices:
		if assigned.has(v.id):
			continue
		var p := camera.unproject_position(v.position)
		var cluster: Array[int] = [v.id]
		assigned[v.id] = true
		for other in _editing_path_data.vertices:
			if assigned.has(other.id):
				continue
			var op := camera.unproject_position(other.position)
			if p.distance_to(op) <= VERTEX_HIT_RADIUS_PX:
				cluster.append(other.id)
				assigned[other.id] = true
		clusters.append(cluster)
	return clusters


func _draw_vertex_stack(overlay: Control, camera: Camera3D, cluster: Array[int], center: Vector2, root_id: int) -> void:
	# Outer ring so a stack reads as visually distinct from a normal vertex
	# at a glance, before the user ever needs to right-click to disambiguate.
	overlay.draw_arc(center, VERTEX_RADIUS_PX + 4.0, 0.0, TAU, 24, STACK_RING_COLOR, 2.0)

	for id in cluster:
		var v := _editing_path_data.get_vertex_by_id(id)
		var color := VERTEX_COLOR
		if id == _dragging_vertex_id:
			color = VERTEX_DRAGGING_COLOR
		elif id == _selected_vertex_id:
			color = SELECTED_VERTEX_COLOR
		var pos := camera.unproject_position(v.position)
		var radius := VERTEX_RADIUS_PX
		if id == root_id:
			radius = ROOT_VERTEX_RADIUS_PX
			overlay.draw_arc(pos, radius + 3.0, 0.0, TAU, 24, ROOT_RING_COLOR, 2.0)
		overlay.draw_circle(pos, radius, color)

	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	overlay.draw_string(font, center + Vector2(VERTEX_RADIUS_PX + 6.0, -VERTEX_RADIUS_PX), "x%d" % cluster.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, STACK_BADGE_COLOR)


## Draws the right-click-hold vertex list, anchored at the press point (not
## the live cursor -- the mouse moves freely to hover rows, but the panel
## itself doesn't follow it around).
func _draw_vertex_menu(overlay: Control) -> void:
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	var geo := _vertex_menu_geometry()
	var anchor: Vector2 = geo["anchor"]
	var line_height: float = geo["line_height"]
	var panel_size: Vector2 = geo["panel_size"]

	overlay.draw_rect(Rect2(anchor - Vector2(4.0, 4.0), panel_size), STACK_PICKER_BG_COLOR)

	for i in _vertex_menu_candidates.size():
		var row_y := anchor.y + i * line_height
		if i == _vertex_menu_hover_index:
			overlay.draw_rect(Rect2(anchor.x - 2.0, row_y - 2.0, panel_size.x - 4.0, line_height), STACK_PICKER_HIGHLIGHT_COLOR)
		var text := "Vertex #%d" % _vertex_menu_candidates[i]
		var color := SELECTED_VERTEX_COLOR if i == _vertex_menu_hover_index else Color(1.0, 1.0, 1.0)
		overlay.draw_string(font, Vector2(anchor.x + 4.0, row_y + font_size), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Small "xN" label offset to the side of the arrow, for edges that overlap
## (same from/to cluster, same direction) -- same visual language as the
## vertex stack badge.
func _draw_edge_count_badge(overlay: Control, p1: Vector2, p2: Vector2, count: int, color: Color) -> void:
	var dir := (p2 - p1)
	if dir.length() < 1.0:
		return
	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	if perp.x < 0.0:
		# draw_string grows text RIGHTWARD from its anchor (left-aligned).
		# If perp points left, the anchor sits left of the line but the text
		# still grows back toward it -- straight into the arrow. Keeping the
		# offset side consistent (always leaning +x) means every badge grows
		# away from the line regardless of which way this particular edge
		# group happens to point.
		perp = -perp
	var anchor := p1.lerp(p2, 0.6) + perp * 14.0
	var font := ThemeDB.fallback_font
	var font_size := ThemeDB.fallback_font_size
	overlay.draw_string(font, anchor, "x%d" % count, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


## Draws a small filled triangle partway along the p1->p2 segment (screen
## space) pointing from p1 toward p2, to make edge direction visible without
## having to infer it from anything else.
func _draw_edge_arrow(overlay: Control, p1: Vector2, p2: Vector2, color: Color) -> void:
	var dir := (p2 - p1)
	if dir.length() < 1.0:
		return  # degenerate/zero-length segment, nothing to point
	dir = dir.normalized()
	var perp := Vector2(-dir.y, dir.x)
	var arrow_size := 16.0
	var anchor := p1.lerp(p2, 0.6)  # partway along, not right on top of the vertex circle
	var tip := anchor + dir * arrow_size * 0.6
	var back := anchor - dir * arrow_size * 0.4
	var left := back + perp * arrow_size * 0.5
	var right := back - perp * arrow_size * 0.5
	overlay.draw_colored_polygon(PackedVector2Array([tip, left, right]), color)


# --- top-down ortho view switch -------------------------------------------
#
# There's no public API for this -- we simulate clicking items in the
# viewport's own "View" menu (a real PopupMenu, found by walking up from the
# active camera) rather than calling any private method directly. Emitting
# id_pressed ourselves triggers whatever's internally connected to it, same
# as a real click would.

func _apply_top_down_ortho() -> void:
	var camera = EditorInterface.get_editor_viewport_3d(0).get_camera_3d()
	var popup := _find_view_menu_popup(camera)
	if popup == null:
		push_warning("[TimePaths] Could not locate the 3D viewport's View menu -- skipping automatic top-down view switch. You can switch manually (Numpad 7, then Numpad 5 if needed).")
		return

	_view_menu_popup = popup

	var ortho_idx := popup.get_item_index(VIEW_ITEM_ORTHOGONAL)
	_was_orthogonal_before_edit = ortho_idx != -1 and popup.is_item_checked(ortho_idx)

	var lock_idx := popup.get_item_index(VIEW_ITEM_LOCK_ROTATION)
	_was_rotation_locked_before_edit = lock_idx != -1 and popup.is_item_checked(lock_idx)

	_previous_camera_transform = camera.transform

	popup.id_pressed.emit(VIEW_ITEM_TOP)
	if not _was_orthogonal_before_edit:
		popup.id_pressed.emit(VIEW_ITEM_ORTHOGONAL)
	if not _was_rotation_locked_before_edit:
		popup.id_pressed.emit(VIEW_ITEM_LOCK_ROTATION)


func _restore_view_state() -> void:
	if _view_menu_popup == null:
		return

	# Only flip things back if they're not already back to how they were --
	# emitting id_pressed on an already-correct checkable item would toggle
	# it the WRONG way.
	var lock_idx := _view_menu_popup.get_item_index(VIEW_ITEM_LOCK_ROTATION)
	if lock_idx != -1 and _view_menu_popup.is_item_checked(lock_idx) != _was_rotation_locked_before_edit:
		_view_menu_popup.id_pressed.emit(VIEW_ITEM_LOCK_ROTATION)

	if not _was_orthogonal_before_edit:
		_view_menu_popup.id_pressed.emit(VIEW_ITEM_PERSPECTIVE)
	
	
	if _previous_camera_transform:
		EditorInterface.get_editor_viewport_3d(0).get_camera_3d().transform = _previous_camera_transform

	_view_menu_popup = null


func _find_view_menu_popup(camera: Camera3D) -> PopupMenu:
	var node: Node = camera
	while node != null:
		if node.get_class() == "Node3DEditorViewport":
			return _find_first_menu_button_popup(node)
		node = node.get_parent()
	return null


func _find_first_menu_button_popup(node: Node) -> PopupMenu:
	if node is MenuButton:
		return node.get_popup()
	for child in node.get_children(true):  # true = include internal children
		var result := _find_first_menu_button_popup(child)
		if result != null:
			return result
	return null
