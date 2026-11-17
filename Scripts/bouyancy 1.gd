
extends Node3D
class_name WaterBuoyancy

## get the water
@export var water_mesh: WaterSurface

## float info
@export_group("Floating")
@export var float_height: float = 0.25
@export var follow_speed: float = 4.0
@export var sample_radius: Vector2 = Vector2(0.5, 0.5)


## tilt settings
@export_group("Floating Rotation")
@export var enable_tilt: bool = true

@export_range(0.0, 2.0, 0.01)
var tilt_strength: float = 1.0
@export_range(0.0, 20.0, 0.1)
var rotation_speed: float = 4.0
@export_range(0.0, 90.0, 1.0)
var max_tilt_angle: float = 35.0

## sample points around object
var sample_offsets: Array[Vector2] = [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]

## keep track of the water state
var elapsed_time: float = 0.0

func _ready() -> void:
	if water_mesh == null:
		push_error("WaterBuoyancy: Assign a WaterSurface.")
		set_physics_process(false)
		return

## update floating position and rotation
func _physics_process(delta: float) -> void:
	if water_mesh == null:
		return
		
	## use the water's own clock to stay synchronized
	elapsed_time = water_mesh.wave_clock

	var total_height: float = 0.0
	var left_height: float = 0.0
	var right_height: float = 0.0
	var back_height: float = 0.0
	var front_height: float = 0.0
	var left_count: int = 0
	var right_count: int = 0
	var back_count: int = 0
	var front_count: int = 0

	## sample the water at each corner of the object
	for offset in sample_offsets:
		var local_offset := Vector3(offset.x * sample_radius.x, 0.0, offset.y * sample_radius.y)
		var sample_position: Vector3 = global_transform * local_offset
		var sample_height: float = water_mesh.get_surface_height(Vector2(sample_position.x, sample_position.z))

		total_height += sample_height
		## collect heights from each side
		if offset.x < 0.0:
			left_height += sample_height
			left_count += 1
		else:
			right_height += sample_height
			right_count += 1
		if offset.y < 0.0:
			back_height += sample_height
			back_count += 1
		else:
			front_height += sample_height
			front_count += 1


	## calculate average water height
	var average_height: float = total_height / float(sample_offsets.size())
	var target_y: float = average_height + float_height

	## smoothly follow the water surface
	var weight: float = 1.0 - exp(-follow_speed * delta)
	global_position.y = lerpf(global_position.y,target_y,weight)

	## calculate rotation from the wave heights
	if enable_tilt:
		left_height /= maxf(float(left_count), 1.0)
		right_height /= maxf(float(right_count), 1.0)
		back_height /= maxf(float(back_count), 1.0)
		front_height /= maxf(float(front_count), 1.0)

		## calculate the slope
		var slope_x: float = (right_height - left_height) / maxf(sample_radius.x * 2.0, 0.001)
		var slope_z: float = (front_height - back_height) / maxf(sample_radius.y * 2.0, 0.001)

		## Get object's rotations
		var axis_x := global_basis.x
		var axis_z := global_basis.z
		axis_x.y = 0.0
		axis_z.y = 0.0
		axis_x = axis_x.normalized()
		axis_z = axis_z.normalized()

		## get the water normal
		var gradient := (axis_x * slope_x + axis_z * slope_z)
		var water_normal := Vector3(-gradient.x, 1.0, -gradient.z).normalized()

		## limit the maximum angle
		var angle: float = acos(clampf(water_normal.dot(Vector3.UP), -1.0, 1.0))
		var maximum_angle: float = deg_to_rad(max_tilt_angle)
		if angle > maximum_angle and angle > 0.001:
			var axis := Vector3.UP.cross(water_normal).normalized()
			water_normal = Vector3.UP.rotated(axis,maximum_angle)
			
		water_normal = Vector3.UP.lerp(water_normal, tilt_strength).normalized()
		
		## keep the object facing the correct direction
		var forward := -global_basis.z
		forward -= water_normal * forward.dot(water_normal)
		if forward.length_squared() < 0.0001:
			forward = Vector3.FORWARD
		forward = forward.normalized()

		## get new target
		var right := forward.cross(water_normal).normalized()
		var corrected_forward := water_normal.cross(right).normalized()
		var target_basis := Basis(right,water_normal,-corrected_forward).orthonormalized()


		## get tilted!
		var rotation_weight: float = 1.0 - exp(-rotation_speed * delta)
		var current_rotation: Quaternion = global_basis.get_rotation_quaternion()
		var target_rotation: Quaternion = target_basis.get_rotation_quaternion()
		global_basis = Basis(current_rotation.slerp(target_rotation,rotation_weight))
