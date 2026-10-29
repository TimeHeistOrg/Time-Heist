shader_type canvas_item;

uniform vec4 panel_color : source_color = vec4(0.015, 0.12, 0.22, 0.82);
uniform vec4 rim_color : source_color = vec4(0.18, 0.75, 1.0, 1.0);
uniform float scanline_strength : hint_range(0.0, 0.5) = 0.3;
uniform float num_scanlines : hint_range(0.0, 1000.0) = 500.0;
uniform float scanline_speed : hint_range(0.0, 50.0) = 1.5;

void fragment() {
	// rounded rectangle, distance_to_edge = 0 => boundary
	vec2 p = abs(UV - vec2(0.5)) - vec2(0.48, 0.47);
	float distance_to_edge = length(max(p, vec2(0.0))) + min(max(p.x, p.y), 0.0) - 0.02;
	
	// mask -> makes stuff outside the boundary transparent
	float mask = 1.0 - smoothstep(-0.002, 0.002, distance_to_edge);
	
	// rim brightest when near boundary
	float rim = 1.0 - smoothstep(0.0, 0.012, abs(distance_to_edge));
	
	// scanlines + sweep
	float scanlines = 0.5 + 0.5 * sin(UV.y * num_scanlines - TIME * scanline_speed);
	float sweep = pow(max(0.0, 1.0 - abs(fract(UV.y - TIME * 0.035) - 0.5) * 8.0), 3.0);
	float scanline_mask = 1.0 - rim;
	
	vec3 color = panel_color.rgb + rim_color.rgb * (rim * 0.55 + scanlines * scanline_strength * scanline_mask + sweep * 0.06);
	COLOR = vec4(color, (panel_color.a + rim * 0.18) * mask) * COLOR;
}
