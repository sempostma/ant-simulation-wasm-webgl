#define ANTS 10922
#define ANTS_DATA 6
#define ANTS_DATA_TOTAL 65532
#define ANTS_TEX_DIM 256
#define SCALE 10
#define WINDOW_WIDTH 1920.0
#define WINDOW_HEIGHT 1080.0

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

const float halfStep = 1.0 / float(ANTS_DATA_TOTAL) / 2.0;

float lerp(float a, float b, float ratio) {
  if (ratio < 0.0) return a;
  if (ratio > 1.0) return b;
  return a + (b - a) * ratio;
}

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
    float antX = mod(antIndex * 2.0, float(ANTS_TEX_DIM));
    float antY = (antIndex * 2.0) / float(ANTS_TEX_DIM);

    vec4 firstComp = texture2D(v_antsTexture, vec2(antX - 1.0, antY + 0.5));
    vec4 secondComp = texture2D(v_antsTexture, vec2(antX, antY + 0.5));

    float xHO = firstComp[0];
    float xLO = firstComp[1];
    float yHO = firstComp[2];
    float yLO = secondComp[0];

    float x = (xHO * 255.0 + xLO) * scaleDiv * 255.0 / WINDOW_WIDTH * 2.0;
    float y = (yHO * 255.0 + yLO) * scaleDiv * 255.0 / WINDOW_HEIGHT * 2.0;

    gl_Position = vec4(x -1.0, y - 1.0, 0.0, 1.0);
    gl_PointSize = 2.0;

    float ratio = antIndex / float(ANTS);
    float r = lerp(1.0, 0.0, abs(1.0 - ratio) * 2.0);
    float g = lerp(1.0, 0.0, abs(1.0 - (ratio + 0.55)) * 2.0);
    float b = lerp(1.0, 0.0, abs(1.0 - (ratio + 1.0)) * 2.0);

    color = vec3(r, g, b);
    
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
