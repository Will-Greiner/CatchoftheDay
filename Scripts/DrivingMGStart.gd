extends Area3D
@onready var camera := $"../../Top Down Camera"
var text = "Drive"
var isDriving = false
var timer = 0.0
@onready var player := $%Player
@onready var boat := $".."
	
func Drive():
	#start minigame
	#zoom out
	if not isDriving:
		camera.zoomOut()
		isDriving = true
		startGame()
	 
func startGame():
	print("minigame started")
	boat.set_physics_process(true)
	boat.driving = true
	
func endGame():
	print("ending game")
	isDriving = false
	camera.zoomIn()
	player.set_physics_process(true)
	player.driving = false
	boat.driving = false

			
