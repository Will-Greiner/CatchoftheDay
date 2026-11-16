extends Path3D

@export var start_node: Node3D
@export var end_node: Node3D
@export var rope_length: float = 10.0
@export var segments: int = 20

func _ready() -> void:
	#makes a new curve if one already exists
	if curve:
		curve = curve.duplicate()
	else:
		curve = Curve3D.new()
		
	# Make unique child polygon
	for child in get_children():
		if child is CSGPolygon3D and child.material:
			child.material = child.material.duplicate()

func _process(_delta: float) -> void:
	if not start_node or not end_node:
		return
		
	var points = get_rope_points(start_node.global_position, end_node.global_position, rope_length, segments)
	
	# Update the curve
	curve.clear_points()
	for p in points:
		curve.add_point(to_local(p))

func get_rope_points(start: Vector3, end: Vector3, length: float, segs: int) -> PackedVector3Array:
	# Take new points in space, calculate the parabola over those segments
	var points := PackedVector3Array()
	var distance := start.distance_to(end)
	var slack = max(0.0, length - distance)
	var sag = -slack * 0.5
	
	for i in range(segs + 1):
		var t := float(i) / float(segs)
		var pos := start.lerp(end, t)
		pos.y += 4.0 * sag * t * (1.0 - t)
		points.append(pos)
	return points
