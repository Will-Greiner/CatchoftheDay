extends Node3D
class_name WaterBuoyancy
## Get the water
@export var water_mesh: MeshInstance3D

## These values must match the shader uniforms.
@export_group("Wave Settings")
@export var wave_amplitude: float = 0.22
@export var wave_frequency: float = 1.5
@export var wave_speed: float = 1.0
@export var wave_direction: Vector2 = Vector2(1.0, 0.35)
@export_range(0.0, 1.0) var secondary_wave_strength: float = 0.5

## Float info
@export_group("Floating")
@export var float_height: float = 0.25
@export var follow_speed: float = 4.0
@export var sample_radius: Vector2 = Vector2(0.5, 0.5)

## Four sampling points from the water around the object's footprint.
var sample_offsets: Array[Vector2] = [Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(-1.0, 1.0), Vector2(1.0, 1.0)]

## Keep track of the water state
var water_material: ShaderMaterial
var elapsed_time: float = 0.0

func _ready() -> void:
	if water_mesh == null:
		push_error("WaterBuoyancy: Assign a WaterMesh.")
		set_physics_process(false)
		return

	water_material = water_mesh.material_override as ShaderMaterial

	if water_material == null:
		water_material = water_mesh.get_surface_override_material(0) as ShaderMaterial

	if water_material == null:
		push_error("WaterBuoyancy: Could not find the water ShaderMaterial.")
		set_physics_process(false)
		return

func _physics_process(delta: float) -> void:
	elapsed_time += delta

	if water_material == null:
		return

	# Synchronize the shader's geometric wave clock.
	water_material.set_shader_parameter("wave_time", elapsed_time)

	var total_height: float = 0.0

	for offset in sample_offsets:
		var local_offset := Vector3(offset.x * sample_radius.x, 0.0, offset.y * sample_radius.y)

		var sample_position: Vector3 = global_transform * local_offset

		var height := get_wave_height(Vector2(sample_position.x, sample_position.z), elapsed_time)

		total_height += height

	var average_height: float = total_height / sample_offsets.size()

	# The water plane's global Y is its base height.
	var water_base_y: float = water_mesh.global_position.y

	var target_y: float = (water_base_y + average_height + float_height)

	# Smoothly follow the water surface.
	var weight := 1.0 - exp(-follow_speed * delta)

	global_position.y = lerpf(global_position.y, target_y, weight)


## Must match get_wave_height() in the water shader
func get_wave_height(p: Vector2, t: float) -> float:
	var direction := wave_direction.normalized()
	var w1 := sin(p.dot(direction) * wave_frequency + t * wave_speed)
	var dir2 := Vector2(-0.45, 1.0).normalized()
	var w2 := sin(p.dot(dir2) * wave_frequency * 1.7 + t * wave_speed * 1.3)
	var dir3 := Vector2(1.0, 0.8).normalized()
	var w3 := sin(p.dot(dir3) * wave_frequency * 2.4 - t * wave_speed * 0.7)

	return wave_amplitude * (w1 * 0.50 + w2 * 0.30 * secondary_wave_strength + w3 * 0.20 * secondary_wave_strength)
