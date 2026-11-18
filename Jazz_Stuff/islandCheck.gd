extends Area3D
@onready var boat = $"../Boat"
@export var islandTransform = Vector3(-4.5, 0, -161)
@export var islandRotation = Vector3(0,0,0)

func _on_body_entered(body: Node3D) -> void:
	print("Boat entered island area")
	boat.reachedIsland = true
	boat.currentIsland = self
