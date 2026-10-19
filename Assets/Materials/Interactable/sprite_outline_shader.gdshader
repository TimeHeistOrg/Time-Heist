shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color;
uniform float outline_width = 1.0;

void vertex() {
    vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
    
    // Expand outward from center using UV coordinates (0..1 -> -1..1)
    vec2 uv_centered = UV * 2.0 - 1.0;
    vec2 offset = normalize(uv_centered) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;
    
    clip_position.xy += offset;
    POSITION = clip_position;
}

void fragment() {
    ALBEDO = outline_color.rgb;
    ALPHA = outline_color.a;
}