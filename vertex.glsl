#pragma optimize(off)

#define ANTS_DATA 6
#define ANTS_DATA_TEX_W 512

#define SCALE 10

precision highp float;
precision highp int;
precision lowp sampler2D;
 
uniform vec2 pan;
uniform vec2 v_viewport;
uniform float zoom;
uniform float aspect;
uniform int v_renderMode;
uniform sampler2D v_antsTexture;
uniform int v_antsDataTexH;
uniform int v_ants;
uniform int v_pointerDown;
uniform vec2 v_pointerPosition;

attribute vec4 position;

varying vec3 color;
varying vec2 antsTexture_coord;
varying vec2 pheremonesTexture_coord;

const float scale = float(SCALE);
const float scaleDiv = 1.0 / float(SCALE);

float lerp(float a, float b, float ratio) {
  if (ratio < 0.0) return a;
  if (ratio > 1.0) return b;
  return a + (b - a) * ratio;
}

vec3 hsl2rgb(in vec3 c)
{
  vec3 rgb = clamp(abs(mod(c.x*6.0+vec3(0.0,4.0,2.0),6.0)-3.0)-1.0, 0.0, 1.0);

  return c.z + c.y * (rgb-0.5)*(1.0-abs(2.0*c.z-1.0));
}

vec3 getColor(float antIndex, int ants) {
  float hue = 0.5 + antIndex / float(ants) * 0.6;
  if (hue > 0.8) hue = hue - (hue - 0.8) * 2.0;
  return hsl2rgb(vec3(hue, 1, 0.5));
}

void main()
{
  int antsDataTotal = v_ants * 2;
  float halfStepW = (1.0 / float(ANTS_DATA_TEX_W)) / 2.0;
  float halfStepH = (1.0 / float(v_antsDataTexH)) / 2.0;

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

    float antIndex = position.x + position.y * float(ANTS_DATA_TEX_W);

    float firstAntX = mod(antIndex * 2.0, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
    float firstAntY = floor((antIndex * 2.0) / float(ANTS_DATA_TEX_W)) / float(v_antsDataTexH) + halfStepH;

    vec4 firstComp = texture2D(v_antsTexture, vec2(firstAntX, firstAntY));

    float secondAntX = mod(antIndex * 2.0 + 1.0, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
    float secondAntY = floor((antIndex * 2.0 + 1.0) / float(ANTS_DATA_TEX_W)) / float(v_antsDataTexH) + halfStepH;

    vec4 secondComp = texture2D(v_antsTexture, vec2(secondAntX, secondAntY));

    float xHO = firstComp[0];
    float xLO = firstComp[1];
    float yHO = firstComp[2];
    float yLO = secondComp[0];

    float x = (xHO * 255.0 + xLO) * scaleDiv * 255.0 / v_viewport.x * 2.0;
    float y = (yHO * 255.0 + yLO) * scaleDiv * 255.0 / v_viewport.y * 2.0;

    gl_Position = vec4(x -1.0, y - 1.0, 0.0, 1.0);
    gl_PointSize = 2.0;

    color = getColor(antIndex, v_ants);
    
    antsTexture_coord = position.xy;
  } else if (v_renderMode == 4) {
    // render final result to the screen

    gl_Position = vec4(position.xy, 0.0, 1.0);
//    gl_Position.xy += pan;
//    gl_Position.xy *= zoom;
//    gl_Position.y *= aspect;

    color = gl_Position.xyz + vec3(0.5);
    pheremonesTexture_coord = position.xy;
  }
}
