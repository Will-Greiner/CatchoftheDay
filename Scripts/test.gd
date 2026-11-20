extends Area3D
@onready var leave_label = $"../Area3D/CanvasLayer/BoxContainer/Label"
@onready var boat_player_spawn =$"../BoatBody/BoatPlayerSpawn"
#stores player reference for later
var player_ref :Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	leave_label.hide()

func _on_body_entered(body: Node3D)-> void:
	#if player enters area, display label, save reference
	print("Entered")
	if body.is_in_group("player"):
		
		leave_label.text = "Press E to board boat"
		leave_label.show()
		player_ref = body


func _on_body_exited(body: Node3D)-> void:
	leave_label.hide()
	player_ref = null
	
#func _input(event: InputEvent) -> void:
#	if Input.is_action_just_pressed("Interact"):
#w		player_ref.position = boat_player_spawn.position
#		leave_label.hide()
		
