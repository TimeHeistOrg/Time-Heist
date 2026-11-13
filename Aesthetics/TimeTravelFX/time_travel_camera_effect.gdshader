shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_nearest;

group_uniforms Effect_State;
uniform float intensity : hint_range(0.0, 1.0) = 0.0; // Animate this 0 -> 1 -> 0

group_uniforms Prismatic_Properties;
uniform float chromatic_spread : hint_range(0.0, 50.0) = 15.0; // How wide the rainbow splits
uniform float warp_amount : hint_range(0.0, 2.0) = 0.8;        // How much the screen "pinches" inward
uniform float radial_blur_power : hint_range(0.0, 1.0) = 0.2;  // Speed blur factor

group_uniforms Color_Boost;
uniform vec4 tint : source_color = vec4(0.8, 0.9, 1.0, 1.0);   // Bright, almost white-blue
uniform float brightness : hint_range(1.0, 5.0) = 1.5;         // Blow out the highlights

void fragment() {
    vec2 center = vec2(0.5, 0.7);
    vec2 uv = SCREEN_UV;
    vec2 dir = center - uv; 
    float dist = length(dir);
    
    vec2 dir_norm = (dist > 0.0) ? dir / dist : vec2(0.0);
    
    // We pull pixels towards the center based on intensity
    float warp_factor = pow(dist, 2.0) * warp_amount * intensity;
    vec2 warped_uv = uv + dir * warp_factor;

    // Instead of just splitting R/G/B, we blur them radially towards the center
    float spread = chromatic_spread * intensity * 0.005;
    
    // Sample Red (pulled furthest)
    vec4 r_col = texture(SCREEN_TEXTURE, warped_uv + dir_norm * spread * 2.0);
    // Sample Green (pulled medium)
    vec4 g_col = texture(SCREEN_TEXTURE, warped_uv + dir_norm * spread * 1.0);
    // Sample Blue (stays closer to anchor)
    vec4 b_col = texture(SCREEN_TEXTURE, warped_uv);
    
    // We mix a few samples along the vector to create a trail
    vec4 blur_acc = vec4(0.0);
    int samples = 8;
    for(int i = 0; i < samples; i++) {
        float t = float(i) / float(samples);
        // Sample slightly further out for each step
        vec2 blur_uv = warped_uv + dir * (t * radial_blur_power * intensity);
        blur_acc += texture(SCREEN_TEXTURE, blur_uv);
    }
    vec4 blurred_tex = blur_acc / float(samples);
    
    vec3 final_color = vec3(r_col.r, g_col.g, b_col.b);
    final_color = mix(final_color, blurred_tex.rgb, 0.5);
    float luminance = dot(final_color, vec3(0.299, 0.587, 0.114));
    vec3 white_light = vec3(luminance) * brightness;
    final_color = mix(final_color, white_light, intensity * 0.5);
    final_color *= tint.rgb;

    COLOR = vec4(final_color, 1.0);
}