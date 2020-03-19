//gradient cell shader by hasenn
shader_type spatial;
render_mode ambient_light_disabled;
//tints the whole object
uniform vec4 main_color : hint_color = vec4(1.);
//specular blob parameters
uniform bool specular_blob = true;
uniform vec4 specular_color : hint_color = vec4(1.);
uniform float blob_size : hint_range(0.00, 1.0, 0.001) = 0.2;
uniform float glossiness : hint_range(0.00, 1.0, 0.001) = 0.5;
uniform float specular_smoothness : hint_range(0.00, 0.2, 0.001) = 0.01;

//rim lighting parameters
uniform bool rim_lighting = true;
uniform vec4 rim_tint : hint_color = vec4(1.);
uniform float rim_threshold : hint_range(0.00, 1.0, 0.001) = 0.25;
uniform float rim_spread : hint_range(0.00, 1.0, 0.001) = 0.5;
uniform float rim_softness : hint_range(0.00, 1.0, 0.001) = 0.05;
//Shadows and light attenuation
uniform bool shade = true;
uniform vec4 shade_tint : hint_color = vec4(1.,1.,1.,1.);
uniform float shade_treshold : hint_range(0.00, 1.0, 0.001) = 0.8;
uniform float shade_intensity : hint_range(0.00, 1.0, 0.001) = 1.;//1 = ambient light 0 = black
uniform float shade_smoothness : hint_range(0.00, 0.5, 0.001) = 0.01;
//textures
uniform sampler2D gradient : hint_white;
uniform sampler2D main_texture : hint_white;

void light(){
	float NdotL = dot(NORMAL, LIGHT);
	vec3 V = normalize(VIEW);
	float is_lit = 0.5*NdotL+0.5 ;
	vec3 base_color = texture(main_texture, UV).rgb * main_color.rgb;
	vec3 grad_result = texture(gradient,vec2(0.5*is_lit+0.5)).rgb;
	//diffuse_light
	vec3 diffuse = 0.5* grad_result* base_color.rgb * LIGHT_COLOR;
	//specular blob
	if (specular_blob){
		float amplitude = glossiness * glossiness;
		float specularity = 1. - blob_size;
		float NdotH = dot(NORMAL,0.5*(V+LIGHT));
		float specular = smoothstep(
			specularity,
			specularity  + specular_smoothness,
			(NdotH)
		);
		//accounts for light color
		diffuse += LIGHT_COLOR * specular * specular_color.rgb * amplitude;
	}
	if (rim_lighting){
		float iVdotN = 1.-dot(V,NORMAL);
		float i_rim_spread = 1. - rim_spread;
		float i_rim_treshold = 1. - rim_threshold;
		float rim_value = iVdotN * pow(NdotL, i_rim_spread);
		rim_value = smoothstep(
			i_rim_treshold - rim_softness,
			i_rim_treshold + rim_softness,
			rim_value
			);
		//Rim lighting color is tinted and accounts for light color
		diffuse += rim_tint.rgb * rim_value * is_lit * LIGHT_COLOR;
	}
	//ambient light applied to the whole object
	//Adding the result for the current light depending on attenuation 
	//(shadows and distance from light)
	if (shade){
		float shd = smoothstep(
			shade_treshold,
			shade_treshold+shade_smoothness,
			dot(ATTENUATION,ATTENUATION)
			);
		DIFFUSE_LIGHT += 
			shd * diffuse +
			(1.-shd) * shade_tint.rgb * shade_intensity * base_color.rgb;
	}
	if (! shade) DIFFUSE_LIGHT += diffuse;
}
