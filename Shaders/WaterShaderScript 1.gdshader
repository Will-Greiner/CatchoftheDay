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
uniform float wave_amplitude : hint_range(0.0, 2.0) = 0.22;
uniform float wave_frequency : hint_range(0.1, 10.0) = 1.5;
uniform float wave_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 wave_direction = vec2(1.0, 0.35);
uniform float secondary_wave_strength : hint_range(0.0, 1.0) = 0.5;
uniform float wave_time = 0.0; // Controlled by WaterSurface.gd, without it, no wave motion will happen

// foam controls
uniform float foam_scale : hint_range(0, 30.0) = 8.0;
uniform float foam_speed : hint_range(0.0, 5.0) = 0.7;
uniform float foam_amount : hint_range(0.0, 2.0) = 0.2;
uniform float foam_sharpness : hint_range(0, 10.0) = 2.0;
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

// noise from just math, no textures
float hash(vec2 p) {return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);}
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


// Wave function, matches the other wave function
float get_wave_height(vec2 p, float t) {
    vec2 dir = normalize(wave_direction);
    float w1 = sin(dot(p, dir) * wave_frequency + t * wave_speed);
    float w2 = sin(dot(p, normalize(vec2(-0.45, 1.0))) * wave_frequency * 1.7 + t * wave_speed * 1.3);
    float w3 = sin(dot(p, normalize(vec2(1.0, 0.8))) * wave_frequency * 2.4 - t * wave_speed * 0.7);

    return wave_amplitude * (w1 * 0.50 + w2 * 0.30 * secondary_wave_strength + w3 * 0.20 * secondary_wave_strength);
}

void vertex() {

    // Convert to world space
    vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

    // Calculate wave displacement from position and time
    float displacement = get_wave_height(world.xz,wave_time);
    world.y += displacement;

    // Convert back into local space
    VERTEX = ( inverse(MODEL_MATRIX) * vec4(world, 1.0)).xyz;

    // Store world space information.
    world_position = world;
    vertex_wave = displacement;

    // Get new normals
    float epsilon = 0.05;
    float height_x = get_wave_height(world.xz + vec2(epsilon, 0.0),wave_time);
    float height_z = get_wave_height(world.xz + vec2(0.0, epsilon),wave_time);

    vec3 tangent_x = vec3(epsilon, height_x - displacement, 0.0);
    vec3 tangent_z = vec3(0.0, height_z - displacement, epsilon);

    vec3 world_normal = normalize(cross(tangent_z, tangent_x));

    // Convert world normal to view
    water_normal_view = normalize(mat3(VIEW_MATRIX) * world_normal);

    // Get water depth
    vec4 view_position = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    water_view_depth = -view_position.z;
}

void fragment() {

    vec2 p = world_position.xz;

    // find depth to next
    float raw_depth = texture(depth_texture,SCREEN_UV).r;
    vec3 scene_view_position;

    // Reverse Z:
    // 0.0 = far plane
    // Values approaching 1.0 = near plane.

    if (raw_depth <= 0.000001) {scene_view_position = vec3(0.0,0.0,-10000.0);} 
    else {
        vec4 scene_view = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, raw_depth, 1.0);
        scene_view_position = scene_view.xyz / scene_view.w;
    }

    float scene_depth = -scene_view_position.z;

    float depth_difference = max(scene_depth - water_view_depth, 0.0); 

    float depth_factor = clamp(depth_difference / gradient_depth, 0.0, 1.0);

    // Make the pretty colors look good
    vec3 water_color = mix(shallow_color.rgb, deep_color.rgb, depth_factor);


    // Make some nice foam
    float foam_time = wave_time * foam_speed;
    vec2 foam_uv = p * foam_scale;
    foam_uv += vec2(foam_time * 0.35, foam_time * 0.20);
    float foam_noise = fbm(foam_uv);
    float foam_pattern = clamp((foam_noise - 0.5) * foam_sharpness + 0.5, 0.0, 1.0);


    // Foam at intersections
    float shoreline = 1.0 - smoothstep(0.0, shoreline_width, depth_difference);
    float shoreline_foam = shoreline * smoothstep(0.35, 0.65, foam_pattern) * foam_amount;


    // Top of wave color
    float normalized_wave = 0.0;
    if (wave_amplitude > 0.001) {normalized_wave = vertex_wave / wave_amplitude;}

    float crest = smoothstep(crest_threshold, crest_threshold + 0.18, normalized_wave);
    float crest_noise = smoothstep(0.25,0.8,fbm(p * foam_scale * 0.7 + foam_time * 0.2));

    crest *= crest_noise * crest_strength;

    // generic foam
    float surface_foam = smoothstep(0.68, 0.88, foam_pattern) * foam_amount * 0.12;
    
    // general light refraction
    vec2 distortion = vec2(noise(p * 2.0 + vec2(wave_time * refraction_speed, 0.0)),
        noise(p * 2.0 - vec2(0.0, wave_time * refraction_speed))) - 0.5;

    vec2 refracted_uv = clamp(SCREEN_UV + distortion * refraction_strength,vec2(0.001),vec2(0.999));

    vec3 refracted_color = texture(screen_texture,refracted_uv).rgb;


    // now that we have our ingredients, we mix them together
    vec3 final_color = mix(water_color, refracted_color, 0.28);
    float total_foam = clamp(shoreline_foam + surface_foam, 0.0, 1.0);
    final_color = mix(final_color, foam_color.rgb, total_foam);
    final_color = mix(final_color, crest_color.rgb, clamp(crest, 0.0, 1.0));


    //Then apply!
    NORMAL = normalize(water_normal_view);

    ALBEDO = final_color;

    ROUGHNESS = 0.12;
    METALLIC = 0.0;
    SPECULAR = 0.65;

    ALPHA = water_opacity;
}
