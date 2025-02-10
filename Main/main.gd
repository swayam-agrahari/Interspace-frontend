# Main.gd
extends Node

var menu_scene = preload("res://Menu/menu.tscn")
var world_scene = preload("res://World/world.tscn")


func _on_play_pressed():
	# Instance the menu
	var menu_instance = menu_scene.instantiate()
	add_child(menu_instance)
	# Make sure we're connecting to the correct type
	if menu_instance.has_signal("join_space_requested"):
		menu_instance.join_space_requested.connect(handle_menu_join)
	else:
		print("Error: Menu scene doesn't have join_space_requested signal")
	# Hide the play/quit buttons
	$Play.hide()
	$Quit.hide()

func handle_menu_join(space_id: String, token: String):
	# Remove menu
	for child in get_children():
		if child is Control and child != $Play and child != $Quit:
			child.queue_free()
	# Instance world
	var world_instance = world_scene.instantiate()
	add_child(world_instance)
	var network = world_instance.get_node("Network") # Ensure this is the correct path
	if network:
		print("Network node found!")
		network.join_space(space_id, token)  # This should work if the path is correct
	else:
		print("Error: Network node not found!")

func _on_quit_pressed():
	get_tree().quit()
