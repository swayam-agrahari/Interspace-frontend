# GameManager.gd
extends Node

signal join_space_requested(space_id: String, token: String)

func connect_signals(menu_scene, network_node):
	# Connect menu signals to network
	menu_scene.join_space_requested.connect(
		network_node.join_space
	)
