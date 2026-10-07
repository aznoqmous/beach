shader_type spatial;
render_mode world_vertex_coords;
uniform sampler2D depth_texture: hint_depth_texture;

group_uniforms Base;
uniform float roughness: hint_range(0.0, 1.0, 0.01);
uniform float specular: hint_range(0.0, 1.0, 0.01);

group_uniforms Colors;
uniform vec4 base_color: source_color;
uniform vec4 coast_color: source_color;
uniform float coast_depth = 1.0;

group_uniforms Foam;
uniform vec4 foam_color: source_color;
uniform sampler2D foam_texture;
uniform float foam_size = 1.0;
uniform float foam_depth = 1.0;
uniform float foam_height = 0.0;
uniform sampler2D foam_wave_noise_texture;
uniform float waves_count = 3.0;
uniform sampler2D flow_voronoi_texture;

group_uniforms Normals;
uniform sampler2D water_normals_texture;
uniform float water_normals_size = 10.0;
uniform vec2 water_normals_speed;

group_uniforms Flow;
uniform sampler2D water_flow_texture;
uniform float water_flow_size;

varying vec3 vVertex;
varying vec3 vOriginalVertex;

void vertex() {
	//VERTEX.y += sin(VERTEX.z + TIME) * 0.1;
	vOriginalVertex = VERTEX;
	VERTEX.y += texture(water_flow_texture, (UV + vec2(TIME, 0.0) * 0.01) / water_flow_size).r * 1.0;
	vVertex = VERTEX;
}

float saturate(float input){
	return clamp(input, 0, 1);
}

float double_step(float value, float minv, float maxv){
	return step(minv, value) - step(maxv, value);
}

void fragment() {
	ROUGHNESS = roughness;
	SPECULAR = specular;
	
	vec3 target_normal = texture(water_normals_texture, UV * water_normals_size + water_normals_speed * TIME).xyz;
	
	NORMAL += TANGENT * (target_normal.x - 0.5);
	NORMAL += BINORMAL * (target_normal.y - 0.5);
	NORMAL = normalize(NORMAL);
	
	float depth = texture(depth_texture, SCREEN_UV).r;
	vec4 ndc = vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec4 world_pos = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * ndc;
	vec3 final_world_position = world_pos.xyz / world_pos.w;
	float water_depth = 1.0 - saturate(abs(final_world_position.y - vVertex.y) / coast_depth);
	ALBEDO = mix(base_color.rgb, coast_color.rgb, water_depth);
	
	float coast_foam_value = saturate(water_depth * coast_depth / 2.0);
	float foam_value = texture(foam_texture, UV * foam_size + vec2(TIME, TIME / 2.0) * 0.01).r;
	//ALBEDO = mix(ALBEDO, foam_color.rgb, saturate(foam_value));
	
	float foam_depth_value = 1.0 - saturate(abs(final_world_position.y - vVertex.y) / foam_depth);
	float foam_mask_time = mod(TIME * 0.1 - foam_depth_value * waves_count, 1.0);
	float foam_mask_start = 0.01 + foam_mask_time;
	float foam_mask_width = 1.0;
	float foam_mask = double_step(coast_foam_value, foam_mask_start, foam_mask_start + foam_mask_width);
	foam_mask = (coast_foam_value - foam_mask_start) / foam_mask_width * foam_mask;
	foam_mask = saturate(0.01 + foam_mask + step(0.99, foam_mask_start) * (foam_depth_value + 0.1));
	//foam_mask *= step(0.1, foam_depth_value);
	float base = 1.0 - foam_mask;
	foam_value = double_step(foam_value, base, 1.0);
	//ALBEDO = mix(ALBEDO, foam_color.rgb, base);
	ALBEDO = mix(ALBEDO, vec3(1.0) - texture(flow_voronoi_texture, UV * 200.0 - vec2(TIME, TIME / 2.0) * 0.01).rgb, 0.1 * foam_depth_value);
	ALBEDO = mix(ALBEDO, texture(flow_voronoi_texture, UV * 200.0 + vec2(TIME, TIME / 2.0) * 0.01).rgb, 0.1 * foam_depth_value);
	
	ALBEDO = mix(ALBEDO, foam_color.rgb, saturate(foam_value));
	ALBEDO = mix(ALBEDO, foam_color.rgb, step(0.99, water_depth));
	
	ALBEDO = vec3(foam_mask);
	
	ALPHA = mix(base_color.a, 0.5, foam_depth_value);
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
