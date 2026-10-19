extends UI
class_name DocumentViewer

@onready var doc_texture : TextureRect = $DocTexture
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func display_document(doc_id: int):
	doc_texture.texture = document_database.get_document(doc_id).document_image
	#animation_player.play("open")
	open()

func handle_input(_delta):
	if Input.is_action_just_pressed("escape") or Input.is_action_just_pressed("ui_tab_forward") or Input.is_action_just_pressed("player_interact"):
		#print("closing document")
		#animation_player.play("close")
		call_deferred("close")
	
