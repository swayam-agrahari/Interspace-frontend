# Main.gd
extends Node

var world_scene = preload("res://World/world.tscn")

func _on_play_pressed():
	# Configure the dialog for both space ID and token input
	ConfirmationDialogJsLoader.set_snippet_content(
		false,  # textarea_readonly
		"",     # textarea_text
		"Space ID\nToken",  # textarea_placeholder
		"Enter Space Details",  # title_text
		"Please paste your Space ID on the first line and Token on the second line",  # subtitle_text
		"Join",  # accept_button_text
		"Cancel"   # cancel_button_text
	)
	
	# Show dialog and wait for result
	var result = await ConfirmationDialogJsLoader.eval_snippet(self)
	if result != "":
		# Split the result into space_id and token
		var lines = result.split("\n", false)
		if lines.size() >= 2:
			var space_id = lines[0].strip_edges()
			var token = lines[1].strip_edges()
			
			if space_id != "" and token != "":
				handle_join(space_id, token)
			else:
				print("Invalid input: Please provide both Space ID and Token")
		else:
			print("Invalid input format: Please provide both Space ID and Token")
	else:
		# User canceled
		$Play.show()
		$Quit.show()

func handle_join(space_id: String, token: String):
	# Instance world
	var world_instance = world_scene.instantiate()
	add_child(world_instance)
	var network = world_instance.get_node("Network")
	if network:
		print("Network node found!")
		network.join_space(space_id, token)
	else:
		print("Error: Network node not found!")

func _on_quit_pressed():
	get_tree().quit()
