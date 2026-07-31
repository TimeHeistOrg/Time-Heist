shader_type canvas_item;

uniform float color_levels : hint_range(2.0, 32.0, 1.0) = 8.0;
uniform sampler2D lookup_table : source_color;

uniform float dither_strength : hint_range(0.0, 1.0) = 0.5;

uniform float highlight_start : hint_range(0.0, 1.0) = 0.65;
uniform float highlight_smoothing : hint_range(0.0, 1.0) = 0.45;

uniform float contrast : hint_range(0.0, 2.0) = 1.1;
uniform float saturation : hint_range(0.0, 2.0) = 1.2;
uniform float luma_bias : hint_range(-0.1, 0.1) = 0.02;


void fragment() {
	vec2 uv = UV;

	vec4 texture_color = texture(TEXTURE, uv);
	vec3 color = texture_color.rgb;

	// Optional contrast and saturation adjustments.
	// color = (color - 0.5) * contrast + 0.5;
	// float gray = dot(color, vec3(0.299, 0.587, 0.114));
	// color = mix(vec3(gray), color, saturation);

	color += luma_bias;
	color = clamp(color, vec3(0.0), vec3(1.0));

	ivec2 pixel_position = ivec2(floor(uv / TEXTURE_PIXEL_SIZE));

	int x = pixel_position.x % 4;
	int y = pixel_position.y % 4;

	float bayer_matrix[16] = float[](
		0.0,  8.0,  2.0, 10.0,
		12.0, 4.0, 14.0,  6.0,
		3.0, 11.0,  1.0,  9.0,
		15.0, 7.0, 13.0, 5.0
	);

	float steps = max(color_levels - 1.0, 1.0);
	float band_size = 1.0 / steps;

	float bayer_value =
		(bayer_matrix[y * 4 + x] / 16.0) - 0.5;

	float original_luma = dot(
		color,
		vec3(0.299, 0.587, 0.114)
	);

	// Apply ordered dithering to luminance.
	float dithered_luma =
		original_luma +
		bayer_value * band_size * dither_strength;

	dithered_luma = clamp(dithered_luma, 0.0, 1.0);

	// Keep hard quantization for the pixelated appearance.
	float quantized_luma =
		round(dithered_luma * steps) / steps;

	/*
	Only smooth the brightest part of the image.

	Below highlight_start, the image remains fully quantized.
	Above it, some original luminance is gradually restored.
	*/
	float highlight_amount = smoothstep(
		highlight_start,
		1.0,
		original_luma
	);

	float final_luma = mix(
		quantized_luma,
		original_luma,
		highlight_amount * highlight_smoothing
	);

	vec3 final_color;

	if (original_luma > 0.001) {
		final_color =
			color * (final_luma / original_luma);
	} else {
		final_color = color;
	}

	final_color = clamp(
		final_color,
		vec3(0.0),
		vec3(1.0)
	);

	COLOR = vec4(final_color, texture_color.a);
}