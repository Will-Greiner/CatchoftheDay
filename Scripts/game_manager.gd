extends Node3D

var fish_types = ["Tuna", "Snapper", "Salmon" ]
var salmon_counter = 0
var tuna_counter = 0
var snapper_counter = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func Increment_Fish(fish_type)-> void:
	match fish_type:
		"Tuna":
			tuna_counter+=1
		"Snapper":
			snapper_counter+=1
		"Salmon":
			salmon_counter +=1
