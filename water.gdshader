shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D depth_texture: hint_depth_texture;

group_uniforms Colors;
uniform vec4 base_color: source_color;
uniform vec4 coast_color: source_color;
uniform float coast_depth = 1.0;

group_uniforms Foam;
uniform vec4 foam_color: source_color;
uniform sampler2D foam_texture;
uniform float foam_size = 1.0;
uniform float foam_height = 0.0;

group_uniforms Normals;
uniform sampler2D water_normals_texture;
uniform float water_normals_size = 10.0;
uniform vec2 water_normals_speed;
uniform sampler2D water_flow_texture;

varying vec3 vVertex;

void vertex() {
	VERTEX.y += sin(VERTEX.z + TIME) * 0.1;
	vVertex = VERTEX;
}
float saturate(float input){
	return clamp(input, 0, 1);
}

float double_step(float value, float minv, float maxv){
	return step(minv, value) - step(maxv, value);
}

void fragment() {
	NORMAL = mix(NORMAL, texture(water_normals_texture, UV * water_normals_size + water_normals_speed * TIME).xyz, 0.5);
	
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec4 world_pos = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * ndc;
	vec3 final_world_position = world_pos.xyz / world_pos.w;
	float water_depth = 1.0 - saturate(abs(final_world_position.y - vVertex.y) / coast_depth);
	ALBEDO = mix(base_color.rgb, coast_color.rgb, water_depth);
	
	float cost_foam_value = saturate(water_depth * coast_depth / 2.0);
	float foam_value = texture(foam_texture, UV * foam_size).r;
	float base = 1.0 - water_depth;
	foam_value = double_step(foam_value, base, 1.0);
	
	float fh = step(0.9, abs(water_depth - foam_height));
	ALBEDO = mix(ALBEDO, foam_color.rgb, saturate(foam_value));
	
	ALPHA = base_color.a;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
