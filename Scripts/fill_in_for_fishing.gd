extends Interact_Abstract
@onready var fish_label = $"../../../Game_Manager/CanvasLayer/BoxContainer/fish label"
@onready var game_manager = $"../../../Game_Manager"
var fish_types = ["Tuna", "Snapper", "Salmon"]
func Interact(object) -> void:
	
	#note: this is a standin for paiges script. 
	var fish_type = fish_types.pick_random()
	print("caught", fish_type)
	game_manager.IncrementFish(fish_type)
	
	
	
	
