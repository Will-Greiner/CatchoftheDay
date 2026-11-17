shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

// color inputs
uniform vec4 shallow_color : source_color = vec4(0.20, 0.75, 0.78, 1.0);
uniform vec4 deep_color : source_color = vec4(0.015, 0.12, 0.25, 1.0);
uniform vec4 foam_color : source_color = vec4(0.92, 0.98, 1.0, 1.0);
uniform vec4 crest_color : source_color = vec4(0.55, 0.91, 0.96, 1.0);
uniform float water_opacity : hint_range(0.0, 1.0) = 0.94;
uniform float gradient_depth : hint_range(0.1, 30.0) = 8.0;

// wave controls
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.35;
uniform float wave_frequency : hint_range(0.1, 10.0) = 1.2;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 wave_direction = vec2(1.0, 0.35);
uniform float secondary_wave_strength : hint_range(0.0, 1.0) = 0.65;
uniform float wave_time = 0.0;

// organic wave distortion
uniform float distortion_strength : hint_range(0.0, 3.0) = 0.45;
uniform float distortion_scale : hint_range(0.1, 10.0) = 1.5;
uniform float distortion_speed : hint_range(0.0, 5.0) = 0.3;

// foam controls
uniform float foam_scale : hint_range(0.0, 30.0) = 8.0;
uniform float foam_speed : hint_range(0.0, 5.0) = 0.7;
uniform float foam_amount : hint_range(0.0, 2.0) = 0.2;
uniform float foam_sharpness : hint_range(0.0, 10.0) = 2.0;
uniform float shoreline_width : hint_range(0.01, 5.0) = 0.8;

// tops of waves
uniform float crest_threshold : hint_range(-1.0, 0.8) = 0.55;
uniform float crest_strength : hint_range(0.0, 2.0) = 0.65;

// intensity of refractions
uniform float refraction_strength : hint_range(0.0, 0.1) = 0.012;
uniform float refraction_speed : hint_range(0.0, 5.0) = 0.5;

// get depth and screen textures
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// for passing data
varying vec3 world_position;
varying float vertex_wave;
varying float water_view_depth;
varying vec3 water_normal_view;


// noise from math
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x),mix(c, d, f.x),f.y);
}

// fractal noise for foam and organic detail
float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += noise(p) * amplitude;
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// distort wave coordinates to avoid repetitive patterns
vec2 get_distorted_position(vec2 p) {
    float t = wave_time * distortion_speed;
    float noise_x = noise(p * distortion_scale + vec2(t, t * 0.37));
    float noise_y = noise(p * distortion_scale + vec2(17.3 - t * 0.29, 31.7 + t * 0.43));
    vec2 distortion = vec2(noise_x - 0.5, noise_y - 0.5);
    return p + distortion * distortion_strength;
}

// wave function, matches WaterSurface.gd
float get_wave_height(vec2 world_xz, float t) {
    vec2 direction = wave_direction;
    if (length(direction) < 0.0001) {
        direction = vec2(1.0, 0.0);
    }
    direction = normalize(direction);
    vec2 p = get_distorted_position(world_xz);
    vec2 cross_direction = vec2(-direction.y, direction.x);

    float f = wave_frequency;
    float s = wave_speed;

    // calculate multiple wave directions
    float phase_x = dot(p, direction) * f + t * s;
    float phase_z = dot(p, cross_direction) * f * 0.85 + t * s * 0.85;
    float phase_2 = dot(p, normalize(vec2(-0.45, 1.0))) * f * 1.7 + t * s * 1.3;
    float phase_3 = dot(p, normalize(vec2(1.0, 0.8))) * f * 2.4 - t * s * 0.7;
    float phase_4 = dot(p, normalize(vec2(-0.8, -0.35))) * f * 1.35 - t * s * 0.55;
    float wave = 0.0;

    
    wave = sin(phase_x) * 0.42 + sin(phase_2) * 0.25 * secondary_wave_strength + sin(phase_3) * 0.18 * secondary_wave_strength + sin(phase_4) * 0.15 * secondary_wave_strength;
    return wave * wave_amplitude;
}

void vertex() {
    // convert to world space
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
    // calculate wave displacement from position and time
    float displacement = get_wave_height(world.xz, wave_time);
    world.y += displacement;
	
    // convert back into local space
    VERTEX = (inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;
	
    // store world space information
    world_position = world;
    vertex_wave = displacement;

    // get new normals
    float epsilon = 0.05;
    float height_x = get_wave_height(world.xz + vec2(epsilon, 0.0), wave_time);
    float height_z = get_wave_height(world.xz + vec2(0.0, epsilon), wave_time);

    vec3 tangent_x = vec3(epsilon, height_x - displacement, 0.0);
    vec3 tangent_z = vec3(0.0, height_z - displacement, epsilon);
    vec3 world_normal = normalize(cross(tangent_z, tangent_x));
	
    // convert world normal to view
    water_normal_view = normalize(mat3(VIEW_MATRIX) * world_normal);

    // get water depth
    vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
    water_view_depth = -view_position.z;
}


void fragment() {
    vec2 p = world_position.xz;

    // find depth to next surface
    float raw_depth = texture(depth_texture, SCREEN_UV).r;
    vec3 scene_view_position;

    // Reverse Z:
    // 0.0 = far plane
    // values approaching 1.0 = near plane
    if (raw_depth <= 0.000001) {
        scene_view_position = vec3(0.0, 0.0, -10000.0);
    } else {
        vec4 scene_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
        scene_view_position = scene_view.xyz / scene_view.w;
    }
    float scene_depth = -scene_view_position.z;
    float depth_difference = max(scene_depth - water_view_depth, 0.0);
    float depth_factor = clamp(depth_difference / gradient_depth, 0.0, 1.0);

    // make the pretty colors look good
    vec3 water_color = mix(shallow_color.rgb, deep_color.rgb, depth_factor);

    // make some nice foam
    float foam_time = wave_time * foam_speed;
    vec2 foam_uv = p * foam_scale;
    foam_uv += vec2(foam_time * 0.35, foam_time * 0.20);
    float foam_noise = fbm(foam_uv);
    float foam_pattern = clamp((foam_noise - 0.5) * foam_sharpness + 0.5, 0.0, 1.0);

    // foam at intersections
    float shoreline = 1.0 - smoothstep(0.0, shoreline_width, depth_difference);
    float shoreline_foam = shoreline * smoothstep(0.35, 0.65, foam_pattern) * foam_amount;

    // top of wave color
    float normalized_wave = 0.0;
    if (wave_amplitude > 0.001) {normalized_wave = vertex_wave / wave_amplitude;}

    float crest = smoothstep(crest_threshold, crest_threshold + 0.18, normalized_wave);
    float crest_noise = smoothstep(0.25, 0.8, fbm(p * foam_scale * 0.7 + foam_time * 0.2));
    crest *= crest_noise * crest_strength;

    // generic foam
    float surface_foam = smoothstep(0.68, 0.88, foam_pattern) * foam_amount * 0.12;

    // general light refraction
    vec2 distortion = vec2(noise(p * 2.0 + vec2(wave_time * refraction_speed, 0.0)), noise(p * 2.0 - vec2(0.0, wave_time * refraction_speed))) - 0.5;
    vec2 refracted_uv = clamp(SCREEN_UV + distortion * refraction_strength, vec2(0.001), vec2(0.999));
    vec3 refracted_color = texture(screen_texture,refracted_uv).rgb;

    // now that we have our ingredients, we mix them together
    vec3 final_color = mix(water_color, refracted_color, 0.28);
    float total_foam = clamp(shoreline_foam + surface_foam, 0.0, 1.0);
    final_color = mix(final_color, foam_color.rgb, total_foam);
    final_color = mix(final_color, crest_color.rgb, clamp(crest, 0.0, 1.0));

    // then apply
    NORMAL = normalize(water_normal_view);
    ALBEDO = final_color;

    ROUGHNESS = 0.12;
    METALLIC = 0.0;
    SPECULAR = 0.65;

    ALPHA = water_opacity;
}