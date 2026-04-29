shader_type canvas_item;
uniform vec2 player_position;
uniform vec4 black = vec4(0, 0, 0,1);

uniform float MULTIPLIER = 1;
uniform float SCALE = 0.5;
uniform float SOFTNESS = 0.8;


void fragment(){
 COLOR = texture(TEXTURE,UV);
 vec3 color = COLOR.rgb;
 float val = distance(vec2(UV.x , UV.y * MULTIPLIER), vec2(player_position.x , player_position.y * MULTIPLIER));
 val = val/SCALE;
 float vignette = smoothstep(1.7, SOFTNESS, val);
 vec3 hi = pow(vec3(vignette),(1.0 - black.rgb)); //setting color
 vec3 multiplyingbase = (hi.rgb) * color; //multiplying the color
 color.rgb = multiplyingbase;
 COLOR = vec4(color,1);
}