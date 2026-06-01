extends MenuTabPanel
class_name SettingsPanel

@onready var animation_player := $AnimationPlayer
@onready var settings := $HBoxContainer/SettingsVerticality

# Settings nodes
@onready var fullscreen_toggle := %FullscreenToggle
@onready var resolution_options := %ResolutionOptions
@onready var mouse_sens_slider := %"Mouse Sens"
@onready var mute_toggle := %"Mute Button"
@onready var music_slider := %"Music volume"
@onready var sfx_slider := %"SFX volume"

# Default values — change these to whatever feels right for the demo
const DEFAULT_FULLSCREEN := false
const DEFAULT_RESOLUTION := 1
const DEFAULT_MOUSE_SENSITIVITY := 5.0
const DEFAULT_MUTED := false
const DEFAULT_MUSIC_VOLUME := 0.8
const DEFAULT_SFX_VOLUME := 0.8

func _ready() -> void:
	settings.hide()
	_apply_defaults()

func _apply_defaults() -> void:
	# General
	fullscreen_toggle.button_pressed = DEFAULT_FULLSCREEN
	resolution_options.selected = DEFAULT_RESOLUTION
	mouse_sens_slider.value = DEFAULT_MOUSE_SENSITIVITY
	
	# Audio
	mute_toggle.button_pressed = DEFAULT_MUTED
	music_slider.value = DEFAULT_MUSIC_VOLUME
	sfx_slider.value = DEFAULT_SFX_VOLUME
	
	# Apply audio values immediately so they match the sliders
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(DEFAULT_MUSIC_VOLUME)
	)
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(DEFAULT_SFX_VOLUME)
	)

func select():
	super.select()
	globals.new_in_device.emit(false, globals.Device_Tabs.Settings)

func _on_settings_toggled(toggled_on: bool) -> void:
	if toggled_on:
		animation_player.play("settings_open")
	else:
		animation_player.play("settings_close")

func _on_homebase_pressed() -> void:
	SceneManager.change_scene_with_transition(SceneManager.Scene.HOMEBASE)

func _on_quit_pressed() -> void:
	SceneManager.quit_game()

#region Settings
func _on_resolution_options_item_selected(index: int) -> void:
	match index:
		0: DisplayServer.window_set_size(Vector2i(1600, 900))
		1: DisplayServer.window_set_size(Vector2i(1920, 1080))
		2: DisplayServer.window_set_size(Vector2i(2560, 1440))
		3: DisplayServer.window_set_size(Vector2i(3840, 2160))

func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_mouse_sens_value_changed(value: float) -> void:
	globals.input_manager.camera_sens_hor = value

func _on_mute_toggled(toggled_on: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), toggled_on)

func _on_music_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)

func _on_sfx_volume_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)
#endregion
