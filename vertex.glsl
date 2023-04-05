#define ANTS 200
#define ANTS_DATA 6
#define ANTS_DATA_TOTAL 400
#define SCALE 10
#define WINDOW_WIDTH 640.0
#define WINDOW_HEIGHT 640.0

uniform vec2 pan;
uniform float zoom;
uniform float aspect;
uniform int v_renderMode;
uniform sampler2D v_antsTexture;

attribute vec4 position;

varying vec3 color;
varying vec2 antsTexture_coord;
varying vec2 pheremonesTexture_coord;

const float scale = float(SCALE);
const float scaleDiv = 1.0 / float(SCALE);

const float halfStep = 1.0 / float(ANTS_DATA_TOTAL);

void main()
{
  if (v_renderMode == 1) {
    // render ants data pixel
    gl_Position = vec4(position.xy, 0.0, 1.0);
    antsTexture_coord = position.xy;
  }
  else if (v_renderMode == 2) {
    gl_Position = vec4(position.xy, 0.0, 1.0);
    pheremonesTexture_coord = position.xy;
  }
  else if (v_renderMode == 3) {
    // render ants location

    float antIndex = position.x;

    vec4 firstComp = texture2D(v_antsTexture, vec2((antIndex * 2.0) / float(ANTS_DATA_TOTAL - 1), 0.5));
    vec4 secondComp = texture2D(v_antsTexture, vec2(((antIndex * 2.0 + 1.0)) / float(ANTS_DATA_TOTAL - 1), 0.5));

    float xHO = firstComp[0];
    float xLO = firstComp[1];
    float yHO = firstComp[2];
    float yLO = secondComp[0];

    float x = (xHO * 255.0 + xLO) * scaleDiv * 255.0 / WINDOW_WIDTH * 2.0;
    float y = (yHO * 255.0 + yLO) * scaleDiv * 255.0 / WINDOW_HEIGHT * 2.0;

    gl_Position = vec4(x -1.0, y - 1.0, 0.0, 1.0);
    gl_PointSize = 2.0;
    antsTexture_coord = position.xy;
  } else if (v_renderMode == 4) {
    // render final result to the screen

    gl_Position = vec4(position.xy, 0.0, 1.0);
    gl_Position.xy += pan;
    gl_Position.xy *= zoom;
    gl_Position.y *= aspect;

    color = gl_Position.xyz + vec3(0.5);
    pheremonesTexture_coord = position.xy;
  }
}
