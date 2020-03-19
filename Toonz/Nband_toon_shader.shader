//N bands cell shader by hasenn
shader_type spatial;
render_mode ambient_light_disabled;
//tints the whole object
uniform vec4 main_color : hint_color = vec4(1.);

//how smooth the transition is between shadow and light
uniform float light_smoothness : hint_range(0.00, 1.0, 0.001) = 0.05;
uniform int n_bands : hint_range(2,8,1) = 2;
uniform float expand_light : hint_range(0.00, 1.0, 0.001);
//ambient color used as a multiplier for the shaded part
uniform vec4 ambient_color : hint_color = vec4(1.);
uniform float ambient_strength : hint_range(0.00, 2.0, 0.01) = 0.5;
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
uniform sampler2D main_texture : hint_white;

float bandstep(float start, float smoothness,float x){
	float ans = 0.;
	float d = (1.-start)/float(n_bands-1);
	float offset = 0.;
	for (int i=0;i<n_bands-1;i++){
		ans += smoothstep(start + offset,start + offset + smoothness,x);
		offset += d;
	}
	return ans/float(n_bands-1);
}
void light(){
	float NdotL = dot(NORMAL, LIGHT);
	vec3 V = normalize(VIEW);
	float is_lit = bandstep(-expand_light,light_smoothness,NdotL) ;
	vec3 base_color = texture(main_texture, UV).rgb * main_color.rgb;
	//diffuse_light
	vec3 diffuse = 0.5*is_lit * base_color.rgb * LIGHT_COLOR;
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
		diffuse += LIGHT_COLOR * specular * specular_color.rgb * amplitude * is_lit;
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
	vec3 ambient = ambient_strength * ambient_color.rgb * base_color;
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
