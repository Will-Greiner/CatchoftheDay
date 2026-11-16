shader_type spatial;
uniform vec3 colorShadow: source_color;
uniform vec3 colorHighlight: source_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
}

void light() {
	float light_intesity = clamp(dot(NORMAL,LIGHT), 0.0,1.0);
	vec3 dynamic_albedo = mix(colorShadow, colorHighlight, light_intesity);
	DIFFUSE_LIGHT += dynamic_albedo * LIGHT_COLOR * ATTENUATION;
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
}
