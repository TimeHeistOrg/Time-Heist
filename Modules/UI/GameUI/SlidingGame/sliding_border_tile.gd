@tool
extends Control
class_name SlidingBorderTile

# Represents a 1x1 block that is used to create the border for the game
# Set the below inspector values and _ready() will handle visually creating it (panel) and adding collision (staticbody2d)

## This should be set automatically when the board is generated
@export var is_exit: bool = false:
	set(v):
		is_exit = v
		queue_redraw()
		_draw_tile()
		if not Engine.is_editor_hint():
			_apply_collision()

## Represents which side of the board the tile is
@export_enum("Top", "Bottom", "Left", "Right") var side: int = 0

var _panel: Panel
var _body: StaticBody2D

const WALL_COLOR := Color(0.30, 0.18, 0.08)
const EXIT_COLOR := Color(0.0, 0.0, 0.0, 0.0)
const CELL_SIZE := 64.0

func _ready() -> void:
	_draw_tile()
	if not Engine.is_editor_hint():
		_apply_collision()

# Creates the tile itself
func _draw_tile() -> void:
	for c in get_children():
		c.free()
		
	# Get cell size from parent (sliding_border), create panel and stylebox for visual representation
	_panel = Panel.new()
	_panel.size = Vector2(CELL_SIZE, CELL_SIZE)
	var sb = StyleBoxFlat.new()
	sb.bg_color = EXIT_COLOR if is_exit else WALL_COLOR
	sb.corner_radius_top_left = 4
	sb.corner_radius_top_right = 4
	sb.corner_radius_bottom_left = 4
	sb.corner_radius_bottom_right = 4
	_panel.add_theme_stylebox_override("panel", sb)
	add_child(_panel)

	# Create static body for collision handling
	if not Engine.is_editor_hint():
		_body = StaticBody2D.new()
		var shape_owner := _body.create_shape_owner(_body)
		var rect_shape := RectangleShape2D.new()
		rect_shape.size = Vector2(CELL_SIZE, CELL_SIZE)
		_body.shape_owner_add_shape(shape_owner, rect_shape)
		_body.position = Vector2(CELL_SIZE * 0.5, CELL_SIZE * 0.5)
		add_child(_body)

# Applies/unapplies collision based on is_exit
func _apply_collision() -> void:
	if _body == null:
		return
	_body.set_collision_layer_value(1, not is_exit)
	_body.set_collision_mask_value(1, not is_exit)

# Update the cell size
func set_cell_size(cell: float) -> void:
	if _panel:
		_panel.size = Vector2(cell, cell)
	if _body:
		_body.position = Vector2(cell * 0.5, cell * 0.5)
		var owner_shape = _body.get_shape_owners()[0]
		var shape = _body.shape_owner_get_shape(owner_shape, 0) as RectangleShape2D
		if shape:
			shape.size = Vector2(cell, cell)
