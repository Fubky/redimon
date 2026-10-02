shader_type canvas_item;
render_mode unshaded;
uniform sampler2D visibility : filter_linear, repeat_disable;
uniform vec4 fog_color : source_color = vec4(0.07,0.13,0.20,1.0);
uniform vec4 sun_color : source_color = vec4(1.0,0.85,0.56,1.0);
uniform bool town = false;
uniform float daylight = 1.0;
void fragment() {
    float visibility_value = town ? 1.0 : texture(visibility,UV).r;
    float visible = smoothstep(0.10,0.80,visibility_value);
    float fog = (1.0-visible)*mix(0.98,0.64,step(0.05,visibility_value));
    float clouds = smoothstep(0.25,0.90,sin(UV.x*12.0+UV.y*9.0+TIME*0.045)*sin(UV.y*18.0-UV.x*3.0+TIME*0.025));
    float ray = pow(max(0.0,sin(UV.x*17.0+UV.y*8.0+TIME*0.015)),14.0)*0.025*daylight;
    float edge = smoothstep(0.28,0.73,length(UV-vec2(0.5)))*0.07;
    vec3 tint = mix(fog_color.rgb,sun_color.rgb,(ray/(clouds*0.10+edge+ray+0.001))*visible);
    float alpha = max(fog, (clouds*0.10+edge+ray)*visible);
    COLOR=vec4(tint,alpha);
}
