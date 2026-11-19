extends CharacterBody3D

var movementSpeed = 24.0
var done_docking = false
var driving = false

@onready var wheel = $BoatThingy/WheelArea
var t = 0.0

var rotation_speed =3
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# checks if in minigame

	if not driving:
		return
	#basic input 
	var input_dir = Input.get_vector("move_right","move_left",  "move_back", "move_forward")
	var direction = (Vector3(input_dir.x, 0, input_dir.y)).normalized()
		
	if direction:
		velocity.x = direction.x * movementSpeed
		velocity.z = direction.z * movementSpeed
			
			#rotation
		#rotate_y(-direction.x *delta * 3)
		var angle = atan2(direction.x, direction.z)
		rotation.y =lerp_angle(rotation.y, angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, movementSpeed)
		velocity.z = move_toward(velocity.z, 0, movementSpeed)
			
	move_and_slide()
	
	if Input.is_action_just_pressed("Interact"):
		Exit_minigame()
		
func Exit_minigame():
	wheel.endGame()
	set_physics_process(false)
