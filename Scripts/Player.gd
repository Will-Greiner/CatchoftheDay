extends CharacterBody3D
@export var target_velocity = Vector3.ZERO
@export var movementSpeed = 4.0
var requiredtime = 1.0
@export var hasChild = false
var child = null
var holdtime = 0.0
@export var driving = false
@onready var boat = %BoatBody


func _physics_process(delta: float) -> void:
	if driving:
		return
		
	var input_dir = Input.get_vector("move_right","move_left", "move_back","move_forward")
	var direction = (Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:
		velocity.x = direction.x * movementSpeed
		velocity.z = direction.z * movementSpeed
		
		var angle = atan2(direction.x, direction.z)
		rotation.y = angle
	else:
		velocity.x = move_toward(velocity.x, 0, movementSpeed)
		velocity.z = move_toward(velocity.z, 0, movementSpeed)
		
	move_and_slide()
	
	var raycast = %RayCast3D
	var StationRC = %StationRC
	if raycast.is_colliding():
		var target = raycast.get_collider()
		#$CanvasLayer/BoxContainer/Label.show()
		if target.has_method("Interact") and not hasChild:
			$CanvasLayer/BoxContainer/Label.text = target.text
			$CanvasLayer/BoxContainer/Label.show()
			if Input.is_action_just_pressed("Interact"):
				target.Interact(self)
				hasChild = true
				child = target
				$CanvasLayer/BoxContainer/Label.hide()
		elif target.has_method("Drive") and not hasChild and not target.isDriving:
			$CanvasLayer/BoxContainer/Label.text = target.text
			$CanvasLayer/BoxContainer/Label.show()
			if Input.is_action_just_pressed("Interact"):
				$CanvasLayer/BoxContainer/Label.hide()
				if not target.isDriving:
					driving = true
					set_physics_process(false)
					target.Drive()
			
		else:
			$CanvasLayer/BoxContainer/Label.hide()
	else:
		$CanvasLayer/BoxContainer/Label.hide()
			
	if Input.is_action_pressed("Interact") and hasChild:
		holdtime += delta
		if not StationRC.is_colliding() and holdtime >= requiredtime:
			#drop item
			drop()
	elif Input.is_action_just_released("Interact"):
		holdtime = 0.0
	
func drop():
	if hasChild:
		hasChild = false
		child.reparent(get_tree().root, true)
		
		
