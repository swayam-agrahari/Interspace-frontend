#menu.gd
extends Node2D

signal join_space_requested(space_id: String, token: String)

@onready var space_id_input = $VBoxContainer/SpaceId
@onready var token_input = $VBoxContainer/Token
@onready var join_button = $VBoxContainer/JoinButton
@onready var feedback_label = $VBoxContainer/Label




func _on_join_button_pressed() -> void:
	var space_id = space_id_input.text.strip_edges()
	var token = token_input.text.strip_edges()
	if space_id == "" or token == "":
		feedback_label.text = "Please enter both Space ID and Token."
		return

	feedback_label.text = "Joining space..."
	emit_signal("join_space_requested", space_id, token)
