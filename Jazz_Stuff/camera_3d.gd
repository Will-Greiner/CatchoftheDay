extends Camera3D

@onready var target := %Player
@export var zoomedInFOV = 75.0
@export var zoomedOutFOV = 100.0
@onready var boat := $"../Boat"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var active_target = boat if target.driving else target
	
	if active_target:
		global_position = Vector3(active_target.global_position.x, 18.0, active_target.global_position.z)

func zoomOut():
	self.fov = zoomedOutFOV
	
func zoomIn():
	self.fov = zoomedInFOV
	
