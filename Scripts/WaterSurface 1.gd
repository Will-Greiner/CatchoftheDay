
extends MeshInstance3D
class_name WaterSurface

## wave settings
@export_group("Wave Settings")
@export_range(0.0, 2.0, 0.01)
var wave_amplitude: float = 0.35
@export_range(0.1, 10.0, 0.01)
var wave_frequency: float = 1.2
@export_range(0.0, 5.0, 0.01)
var wave_speed: float = 1.0
@export var wave_direction: Vector2 = Vector2(1.0, 0.35)
@export_range(0.0, 1.0, 0.01)
var secondary_wave_strength: float = 0.65

## organic wave distortion
@export_group("Wave Distortion")
@export_range(0.0, 3.0, 0.01)
var distortion_strength: float = 0.45
@export_range(0.1, 10.0, 0.1)
var distortion_scale: float = 1.5
@export_range(0.0, 5.0, 0.01)
var distortion_speed: float = 0.3

## keep track of own information
var wave_clock: float = 0.0
var water_material: ShaderMaterial

func _ready() -> void:

	water_material = get_active_material(0) as ShaderMaterial

	if water_material == null:
		push_error("WaterSurface: No ShaderMaterial found on WaterMesh. Assign FlatKitWater.gdshader to the mesh.")
		set_process(false)
		return

	update_shader_parameters()


func _process(delta: float) -> void:

	if water_material == null:
		return

	wave_clock += delta

	water_material.set_shader_parameter("wave_time", wave_clock)


## send all wave parameters to the shader
func update_shader_parameters() -> void:
	if water_material == null:
		return
	water_material.set_shader_parameter("wave_amplitude", wave_amplitude)
	water_material.set_shader_parameter("wave_frequency", wave_frequency)
	water_material.set_shader_parameter("wave_speed", wave_speed)
	water_material.set_shader_parameter("wave_direction", wave_direction)
	water_material.set_shader_parameter("secondary_wave_strength", secondary_wave_strength)
	water_material.set_shader_parameter("distortion_strength", distortion_strength)
	water_material.set_shader_parameter("distortion_scale", distortion_scale)
	water_material.set_shader_parameter("distortion_speed", distortion_speed)
	water_material.set_shader_parameter("wave_time", wave_clock)

## generate noise
func hash_noise(p: Vector2) -> float:
	var value: float = sin(p.dot(Vector2(127.1, 311.7))) * 43758.5453
	return value - floor(value)

func noise(p: Vector2) -> float:
	var i: Vector2 = p.floor()
	var f: Vector2 = p - i
	f = f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	
	var a: float = hash_noise(i)
	var b: float = hash_noise(i + Vector2(1.0, 0.0))
	var c: float = hash_noise(i + Vector2(0.0, 1.0))
	var d: float = hash_noise(i + Vector2(1.0, 1.0))

	return lerpf(lerpf(a, b, f.x), lerpf(c, d, f.x), f.y)


## fractal noise for organic variation
func fbm(p: Vector2) -> float:
	var value: float = 0.0
	var amplitude: float = 0.5
	for i in range(4):
		value += noise(p) * amplitude
		p *= 2.0
		amplitude *= 0.5
	return value


## distort noise
func get_distorted_position(p: Vector2) -> Vector2:
	var t: float = wave_clock * distortion_speed
	var noise_x: float = noise(p * distortion_scale + Vector2(t, t * 0.37))
	var noise_y: float = noise(p * distortion_scale + Vector2(17.3 - t * 0.29, 31.7 + t * 0.43))
	var distortion := Vector2(noise_x - 0.5, noise_y - 0.5)
	return p + distortion * distortion_strength


## must match the shader to calculate correctly
func get_wave_height(world_xz: Vector2) -> float:
	var direction: Vector2 = wave_direction.normalized()
	if direction.length_squared() < 0.0001:
		direction = Vector2.RIGHT
	## distort!
	var p: Vector2 = get_distorted_position(world_xz)
	var cross_direction := Vector2(-direction.y, direction.x)
	var f: float = wave_frequency
	var s: float = wave_speed
	var t: float = wave_clock
	## calculate wave directions
	var phase_x: float = p.dot(direction) * f + t * s
	var phase_z: float = p.dot(cross_direction) * f * 0.85 + t * s * 0.85
	var phase_2: float = p.dot(Vector2(-0.45, 1.0).normalized()) * f * 1.7 + t * s * 1.3
	var phase_3: float = p.dot(Vector2(1.0, 0.8).normalized()) * f * 2.4 - t * s * 0.7
	var phase_4: float = p.dot(Vector2(-0.8, -0.35).normalized()) * f * 1.35 - t * s * 0.55
	var wave: float = 0.0

	wave = (sin(phase_x) * 0.42 + sin(phase_2) * 0.25 * secondary_wave_strength + sin(phase_3) * 0.18 * secondary_wave_strength + sin(phase_4) * 0.15 * secondary_wave_strength)
	return wave * wave_amplitude

## calculate world space height
func get_surface_height(world_xz: Vector2) -> float:
	return global_position.y + get_wave_height(world_xz)

## calculate new normal
func get_surface_normal(world_xz: Vector2) -> Vector3:
	var epsilon: float = 0.05
	var center_height: float = get_wave_height(world_xz)
	var height_x: float = get_wave_height(world_xz + Vector2(epsilon, 0.0))
	var height_z: float = get_wave_height(world_xz + Vector2(0.0, epsilon))
	var tangent_x := Vector3(epsilon, height_x - center_height, 0.0)
	var tangent_z := Vector3(0.0, height_z - center_height, epsilon)
	return tangent_z.cross(tangent_x).normalized()
