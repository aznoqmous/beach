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
uniform float foam_height = 0.0;
uniform sampler2D flow_voronoi_texture;

group_uniforms Waves;
uniform sampler2D foam_wave_noise_texture;
uniform float waves_count = 3.0;
uniform float waves_strength = 1.0;
uniform vec3 wet_sand_color: source_color;

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
	VERTEX.y += texture(water_flow_texture, (UV + vec2(TIME, 0.0) * 0.0) / water_flow_size).r * 1.0;
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
	
	float foam_displacement = + texture(foam_texture, vec2(vVertex.x + TIME * 0.1, vVertex.y + TIME * 0.1) * 0.01).r * 0.05;
	float water_mask = mod(water_depth * waves_count - TIME * 0.2 + foam_displacement, 1.0) * smoothstep(0.0, 0.2, water_depth);
	water_mask = pow(water_mask, waves_strength);
	float water_egde_foam = (1.0 - step(0.01, water_mask)) * step(0.1, water_depth);
	float foam_value = texture(foam_texture, UV * foam_size + vec2(TIME, TIME / 2.0) * 0.01 + texture(water_flow_texture, UV * 0.01).xy).r;
	foam_value = step(1.0 - water_mask, foam_value);
	foam_value = foam_value + water_egde_foam;
	foam_value = saturate(foam_value);
	ALBEDO = mix(ALBEDO, wet_sand_color, smoothstep(0.8, 1.0, water_depth));
	ALBEDO = mix(ALBEDO, foam_color.rgb, foam_value);
	ALPHA = 1.0 - smoothstep(0.4, 1.0, water_depth) + water_mask + water_egde_foam;
	ALPHA = max(ALPHA, foam_value);
	
	//ALBEDO = vec3(mod(water_depth * waves_count, 1.0));
	//ALBEDO = vec3(water_mask);
	

	ALBEDO = mix(ALBEDO, texture(flow_voronoi_texture, UV * 200.0 + vec2(TIME, TIME / 2.0) * 0.01).rgb, 0.05 * (1.0 - foam_value));
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
