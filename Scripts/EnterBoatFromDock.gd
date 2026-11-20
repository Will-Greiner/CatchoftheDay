extends Area3D

@onready var boat_player_spawn =%BoatPlayerSpawn
var text = "Press E to board boat"
#stores player reference for later
var player_ref :Node3D = null


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D)-> void:
	print("Player on dock")
	if body.is_in_group("player"):
		#save reference to boat object
		player_ref = body
		
func _physics_process(delta) -> void:
	if Input.is_action_just_pressed("Interact") and player_ref:
		#put boat in the dock position and rotation of the island
		player_ref.position = boat_player_spawn.position
		player_ref.rotation = boat_player_spawn.rotation
		

func _on_body_exited(body: Node3D)-> void:
	player_ref = null
