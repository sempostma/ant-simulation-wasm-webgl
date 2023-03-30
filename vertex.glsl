uniform vec2 pan;
uniform float zoom;
uniform float aspect;
attribute vec4 position;
varying vec3 color;
void main()
{
    gl_Position = vec4(position.xyz, 1.0);
    gl_Position.xy += pan;
    gl_Position.xy *= zoom;
    gl_Position.y *= aspect;
    color = gl_Position.xyz + vec3(0.5);
}