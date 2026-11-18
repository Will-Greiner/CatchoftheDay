class_name interactable
extends Interact_Abstract

@export var text = "Press E to Interact"

func Interact(object):
	reparent(object)
	print("Interacted")
