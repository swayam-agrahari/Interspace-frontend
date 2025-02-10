# network_player.gd
extends CharacterBody2D

func _ready():
	print("network_player ready()")

# Remove _physics_process entirely as network players should only 
# move when receiving position updates from the server

# Add a function to update position smoothly
func update_network_position(new_x: float, new_y: float):
	position.x = new_x
	position.y = new_y
	
	# Update animation based on position change
	var movement = position - Vector2(new_x, new_y)
	if movement.length() > 0:
		if abs(movement.x) > abs(movement.y):
			$AnimatedSprite2D.play("Left")
			$AnimatedSprite2D.flip_h = movement.x > 0
		elif movement.y > 0:
			$AnimatedSprite2D.play("Down")
		else:
			$AnimatedSprite2D.play("Up")
	else:
		$AnimatedSprite2D.play("Idle")
