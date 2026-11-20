extends Area3D

@onready var dock_position =$BoatSpawn
@onready var spawnPosition = $IslandSpawn
var text = "Press E to dock the boat"
var present_body: Node3D = null
@onready var label = $CanvasLayer/BoxContainer/Label
@onready var player = %Player
var temp: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	label.hide()

func _on_body_entered(body: Node3D)-> void:
	"boat"
	if body.is_in_group("boat_group"):
		#save reference to boat object
		present_body = body
		
		#display button to leave boat 
		label.show()

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("Interact") and present_body :
		#put boat in the dock position and rotation of the island
		#
		present_body.global_position = dock_position.global_position
		present_body.rotation = dock_position.global_rotation
		
		#spawn player on island
		player.global_position = spawnPosition.global_position
		player.global_rotation = spawnPosition.global_rotation
		
		label.hide()
		temp = present_body
		present_body = null


func _on_body_exited(body: Node3D)-> void:
	present_body = null
	label.hide()
