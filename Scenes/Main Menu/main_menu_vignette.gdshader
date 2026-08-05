shader_type canvas_item;

uniform float strength : hint_range(0.0, 1.0) = 0.4;
uniform float radius : hint_range(0.0, 1.0) = 0.75;
uniform vec4 vignette_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float vignette = smoothstep(radius, radius - 0.3, length(uv));
    float alpha = (1.0 - vignette) * strength;
    COLOR = vec4(vignette_color.rgb, alpha);
}