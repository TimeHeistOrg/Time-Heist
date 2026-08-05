shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 color : source_color = vec4(1.0, 0.0, 0.0, 0.5);
uniform float scan_speed : hint_range(0.0, 10.0) = 2.0;       
uniform float scan_density : hint_range(1.0, 20.0) = 6.0;     
uniform float scan_sharpness : hint_range(0.1, 5.0) = 2.0;    
uniform float edge_softness : hint_range(0.0, 5.0) = 2.0;     

uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;

void fragment() {
    float fresnel = pow(1.0 - dot(NORMAL, VIEW), edge_softness);
    
    float wave = sin((UV.y * scan_density) - (TIME * scan_speed));
    
    float scan_line = pow((wave + 1.0) * 0.5, scan_sharpness);
    
    float depth = texture(depth_texture, SCREEN_UV).r;
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
    vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
    view.xyz /= view.w;
    float linear_depth = -view.z;
    float depth_fade = clamp((linear_depth - -VERTEX.z) / 1.0, 0.0, 1.0);

    vec3 final_color = color.rgb;
    
    final_color += scan_line * 0.5; 

    float final_alpha = color.a;
    final_alpha *= (fresnel + scan_line); 
    final_alpha *= depth_fade;
    
    ALBEDO = final_color;
    ALPHA = clamp(final_alpha, 0.0, 1.0);
	
}