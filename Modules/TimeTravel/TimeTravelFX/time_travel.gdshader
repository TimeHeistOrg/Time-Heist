shader_type canvas_item;

// Use SCREEN_TEXTURE if applied to a ColorRect.
//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

// The number of "pixels" of color that it is quantized into.
//uniform vec2 screen_res = vec2(960.0, 540.0); 
uniform float color_levels = 8.0;
uniform sampler2D lookup_table : source_color;

uniform float dither_strength = 0.5;
uniform float contrast : hint_range(0.0, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;
uniform float luma_bias : hint_range(-0.1, 0.1) = 0.02;

void fragment() {
    //vec2 uv = floor(SCREEN_UV * screen_res) / screen_res;
    vec2 uv = UV;
	vec3 color = texture(TEXTURE, uv).rgb;
	
	//color = (color - 0.5) * contrast + 0.5;
    //float gray = dot(color, vec3(0.299, 0.587, 0.114));
    //color = mix(vec3(gray), color, saturation);
	color += luma_bias;
	
	ivec2 uv_pixels = ivec2(floor(uv / TEXTURE_PIXEL_SIZE));
    int x = uv_pixels.x % 4;
    int y = uv_pixels.y % 4;
	
	float bayer_matrix[16] = float[](
        0.0, 8.0, 2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0, 1.0, 9.0,
        15.0, 7.0, 13.0, 5.0
    );
	
	float band_size = 1.0 / color_levels;
	
	float dither_shift = (bayer_matrix[y * 4 + x] / 16.0) - 0.5;
	color += dither_shift * (band_size * dither_strength);
    
    float luma = dot(color, vec3(0.299, 0.587, 0.114));
    float bucketed_luma = floor(luma * color_levels) / color_levels;

	vec3 final_color = texture(lookup_table, vec2(bucketed_luma, 0.0)).rgb;
    //vec3 final_color = floor(color * color_levels) / color_levels;
	
    COLOR = vec4(final_color, 1.0);
}