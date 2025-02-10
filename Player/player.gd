#player.gd
extends CharacterBody2D

var speed = 50
var network 
var user_id: String = "" 
func _ready():
	# Get reference to the Network node where the WebSocket communication happens
	network = get_node("/root/Main/World/Network")
func _process(_delta) -> void:
	if velocity != Vector2.ZERO:
		print("in here",user_id)
		network.send_movement(position.x, position.y)



func _physics_process(_delta: float) -> void:
	# Reset velocity each frame
	velocity = Vector2.ZERO
	
	# Print the position of the CharacterBody2D
	#print("before", position)

	# Check for movement input
	if Input.is_action_pressed("ui_right"):
		velocity.x = speed
		$AnimatedSprite2D.play("Left")
		$AnimatedSprite2D.flip_h = true
	elif Input.is_action_pressed("ui_left"):
		velocity.x = -speed
		$AnimatedSprite2D.play("Left")
		$AnimatedSprite2D.flip_h = false
	elif Input.is_action_pressed("ui_down"):
		velocity.y = speed
		$AnimatedSprite2D.play("Down")
	elif Input.is_action_pressed("ui_up"):
		velocity.y = -speed
		$AnimatedSprite2D.play("Up")
	else:
		$AnimatedSprite2D.play("Idle")

	# Move the character using move_and_slide, passing the velocity vector
	move_and_slide()
