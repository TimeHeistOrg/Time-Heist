shader_type spatial;
render_mode blend_mix, depth_draw_never, shadows_disabled, cull_back, unshaded;

uniform float opacity : hint_range(0.0, 1.0) = 0.04;
uniform vec4 cone_color : source_color = vec4(0.9, 0.05, 0.05, 1.0);
uniform float edge_softness : hint_range(0.0, 0.5) = 0.3;
uniform float tip_falloff : hint_range(0.0, 1.0) = 0.05;
uniform float outline_strength : hint_range(0.0, 1.0) = 0.15;

void fragment() {
    float edge_dist = abs(UV.x - 0.5) * 2.0;
    float edge_fade = smoothstep(1.0, 1.0 - edge_softness, edge_dist);

    // Outline — brighten near the edges
    float outline = smoothstep(0.6, 1.0, edge_dist) * outline_strength;

    float depth_fade = mix(1.0, tip_falloff, UV.y);

    ALBEDO = cone_color.rgb;
    ALPHA = (opacity * edge_fade + outline) * depth_fade;
}