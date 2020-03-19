//2band toon with volumetric dotting by hasenn
shader_type spatial;
render_mode ambient_light_disabled;
//tints the whole object
uniform vec4 main_color : hint_color = vec4(1.);
uniform float dots_scale : hint_range(0., 50., 0.25) = 20.;
uniform float dots_size : hint_range(0., 0.5, 0.01) = 0.3;
uniform float dots_smooth : hint_range(0., 0.5, 0.01) = 0.1;
//how smooth the transition is between shadow and light
uniform float light_smoothness : hint_range(0.00, 1.0, 0.001) = 0.05;

//ambient color used as a multiplier for the shaded part
uniform vec4 ambient_color : hint_color = vec4(1.);
uniform float ambient_strength : hint_range(0.00, 2.0, 0.01) = 0.5;
//Shadows and light attenuation
uniform bool shade = true;
uniform vec4 shade_tint : hint_color = vec4(1.,1.,1.,1.);
uniform float shade_treshold : hint_range(0.00, 1.0, 0.001) = 0.8;
uniform float shade_intensity : hint_range(0.00, 1.0, 0.001) = 1.;//1 = ambient light 0 = black
uniform float shade_smoothness : hint_range(0.00, 0.5, 0.001) = 0.01;
//textures
uniform sampler2D main_texture : hint_white;

float polkadot(float r, float s, vec3 pt){
	return smoothstep(r,r+s,distance(pt,vec3(0.5,0.5,0.5)));
}
void fragment() {
	vec3 pt = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	pt = pt * dots_scale;
	ALBEDO = vec3(polkadot(dots_size,dots_smooth,fract(pt)));
}
void light(){
	float NdotL = dot(NORMAL, LIGHT);
	vec3 V = normalize(VIEW);
	float is_lit = smoothstep(0.,light_smoothness,NdotL) ;
	vec3 base_color = texture(main_texture, UV).rgb * main_color.rgb;
	//diffuse_light
	vec3 diffuse = 0.5*is_lit * base_color.rgb * LIGHT_COLOR;
	
	//ambient light applied to the whole object
	vec3 ambient = ALBEDO * ambient_strength * ambient_color.rgb * base_color;
	diffuse += ambient;
	if (shade){
		float shd = smoothstep(
			shade_treshold,
			shade_treshold+shade_smoothness,
			dot(ATTENUATION,ATTENUATION)
			);
		DIFFUSE_LIGHT += shd*diffuse + (1.-shd)*ambient*shade_tint.rgb*shade_intensity;
	}
	if (! shade) DIFFUSE_LIGHT += diffuse;
}
