extends MeshInstance3D
class_name WaterSurface

## Wave settings need to match the shader's
@export_group("Wave Settings")
@export_range(0.0, 2.0, 0.01)

var wave_amplitude: float = 0.22
@export_range(0.1, 10.0, 0.01)
var wave_frequency: float = 1.5
@export_range(0.0, 5.0, 0.01)
var wave_speed: float = 1.0
@export var wave_direction: Vector2 = Vector2(1.0, 0.35)
@export_range(0.0, 1.0, 0.01)
var secondary_wave_strength: float = 0.5

## Keep track of own information
var wave_clock: float = 0.0
var water_material: ShaderMaterial

func _ready() -> void:
	water_material = get_active_material(0) as ShaderMaterial
	if water_material == null:
		push_error("WaterSurface: No ShaderMaterial found on WaterMesh. " + "Assign FlatKitWater.gdshader to the mesh.")
		set_process(false)
		return
	# Send all wave parameters to the shader.
	update_shader_parameters()

func _process(delta: float) -> void:
	if water_material == null:
		return
	wave_clock += delta
	water_material.set_shader_parameter("wave_time", wave_clock)

func update_shader_parameters() -> void:
	if water_material == null:
		return

	water_material.set_shader_parameter("wave_amplitude", wave_amplitude)
	water_material.set_shader_parameter("wave_frequency", wave_frequency)
	water_material.set_shader_parameter("wave_speed", wave_speed)
	water_material.set_shader_parameter("wave_direction", wave_direction)
	water_material.set_shader_parameter("secondary_wave_strength", secondary_wave_strength)
	water_material.set_shader_parameter("wave_time", wave_clock)

## Must match the shader to calculate correctly
func get_wave_height(world_xz: Vector2) -> float:
	var direction := wave_direction.normalized()
	var w1 := sin(world_xz.dot(direction) * wave_frequency + wave_clock * wave_speed)
	var dir2 := Vector2(-0.45, 1.0).normalized()
	var w2 := sin(world_xz.dot(dir2) * wave_frequency * 1.7 + wave_clock * wave_speed * 1.3)
	var dir3 := Vector2(1.0, 0.8).normalized()
	var w3 := sin(world_xz.dot(dir3) * wave_frequency * 2.4 - wave_clock * wave_speed * 0.7)
	return wave_amplitude * (w1 * 0.50 + w2 * 0.30 * secondary_wave_strength + w3 * 0.20 * secondary_wave_strength)

## calculate wave height
func get_surface_height(world_xz: Vector2) -> float:
	return global_position.y + get_wave_height(world_xz)

## get new normal
func get_surface_normal(world_xz: Vector2) -> Vector3:
	var epsilon := 0.05
	var center_height := get_wave_height(world_xz)
	var height_x := get_wave_height(world_xz + Vector2(epsilon, 0.0))
	var height_z := get_wave_height(world_xz + Vector2(0.0, epsilon))
	var tangent_x := Vector3(epsilon, height_x - center_height, 0.0)
	var tangent_z := Vector3(0.0, height_z - center_height, epsilon)
	return tangent_z.cross(tangent_x).normalized()
