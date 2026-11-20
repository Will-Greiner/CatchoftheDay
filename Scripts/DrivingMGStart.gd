extends Area3D
@onready var camera := $"../../../Top Down Camera"
var text = "Drive"
var isDriving = false
var timer = 0.0
@onready var player := %Player
@onready var boat := %BoatBody
var inBoat = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
func Drive():
	#start minigame
	#zoom out
	if not isDriving:
		player.driving = true
		player.set_physics_process(false)
		camera.zoomOut()
		isDriving = true
		startGame()

func _on_body_entered(body: Node3D)-> void:
	if body.is_in_group("player"):
		#display text
		print("it works")
		$"../../Player/CanvasLayer/BoxContainer/Label".show()
		inBoat = true
		#Drive()
func _on_body_exited(body: Node3D)-> void:
	if body.is_in_group("player"):
		#display text
		$"../../Player/CanvasLayer/BoxContainer/Label".hide()
		#Drive()
		inBoat = false
		
		
func startGame():
	print("minigame started")
	await get_tree().create_timer(0.2).timeout
	boat.set_physics_process(true)
	boat.driving = true
	
func endGame():
	print("ending game")
	isDriving = false
	camera.zoomIn()
	player.set_physics_process(true)
	player.driving = false
	boat.driving = false
	inBoat = false

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact") and not isDriving and inBoat:
		Drive()
		$"../../Player/CanvasLayer/BoxContainer/Label".hide()
