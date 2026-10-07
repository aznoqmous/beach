shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D depth_texture: hint_depth_texture;

group_uniforms Base;
uniform float roughness: hint_range(0.0, 1.0, 0.01);
uniform float specular: hint_range(0.0, 1.0, 0.01);
uniform vec3 base_color: source_color;
uniform vec3 border_color: source_color;
uniform vec3 wet_color: source_color;

uniform sampler2D grain_texture; 
uniform float grain_size = 1.0;

group_uniforms SandSteep;
uniform sampler2D sand_steep_texture;
uniform float sand_steep_size = 1.0;
uniform float water_height = 1.0;
varying vec3 vVertex;

void vertex() {
	vVertex = VERTEX;
	// Called for every vertex the material is visible on.
}
float saturate(float input){
	return clamp(input, 0, 1);
}

uniform float rim_power;
uniform float rim_strength;

float rim_color(vec3 N, vec3 V)
{
    float rim = 1.0 - saturate(dot(N, V));
    rim = saturate(pow(rim, rim_power) * rim_strength);
    rim = max(rim, 0);
    return rim;
}
void fragment() {
	ROUGHNESS = roughness;
	ALBEDO = base_color;
	
	float wet_value = 1.0 - smoothstep(0.5, 0.52, (vVertex.y + water_height));
	ALBEDO = mix(ALBEDO, wet_color, wet_value);
	vec3 view = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	ALBEDO = mix(ALBEDO, border_color, rim_color(NORMAL, VIEW));

	SPECULAR = specular * wet_value;

	vec3 target_normal = texture(sand_steep_texture, UV * sand_steep_size).xyz;
	target_normal = normalize(mix(target_normal, texture(grain_texture, UV * grain_size).rgb, 0.5));
	NORMAL += TANGENT * (target_normal.x - 0.5);
	NORMAL += BINORMAL * (target_normal.y - 0.5);
	NORMAL = normalize(NORMAL);
	
	//ALBEDO = texture(depth_texture, SCREEN_UV).rgb;
	
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
