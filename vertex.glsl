#define ANTS 10
#define ANTS_DATA 4
#define ANTS_TOTAL 40

uniform vec2 pan;
uniform float zoom;
uniform float aspect;

attribute vec4 position;

varying vec3 color;
varying vec3 test[10];
varying float first;
varying vec4 ants[ANTS];
varying vec2 texture1_coord;

// [0] - setup
varying float options[10];

void setup() {
  for(int i = 0; i < ANTS; i++) {
    ants[i][0] = 0.0;
    ants[i][1] = 0.0;
    ants[i][2] = 0.0;
  }
}

void main()
{
  gl_Position = vec4(position.xy, 0.0, 1.0);
  gl_Position.xy += pan;
  gl_Position.xy *= zoom;
  gl_Position.y *= aspect;
  if (position.z < 0.001 && int(position.z) == 0) {
    if (options[0] > 0.0 && int(options[0]) == 1) {
      options[0] = 1.0;
      setup();
    }
  }
  for(int i = 0; i < ANTS; i++) {
    ants[i][0] += 0.0;
    ants[i][1] += 0.0;
    ants[i][2] += 0.0;
  }
  color = gl_Position.xyz + vec3(0.5);
  texture1_coord = position.xy;
}
