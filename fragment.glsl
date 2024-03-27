#pragma optimize(off)

#define ANTS_DATA 6
#define ANTS_DATA_TEX_W 512

#define PHERMONE_RECEPTOR_DISTANCE 12.0
#define BLUR_SPEED 0.02

#define ANTS_COORDS_LIMIT 65280
#define SCALE 10
#define PHEREMONE_EVAPORATION_SPEED 0.002
#define PHEREMONE_EVAPORATION_SPEED_RELATIVE 0.0

precision highp float;
precision lowp sampler2D;
precision highp int;

varying vec3 color;
varying vec2 antsTexture_coord;

uniform vec2 f_viewport;
uniform sampler2D antsTexture;
uniform sampler2D pheremonesTexture;
uniform int f_renderMode;
uniform int f_antsDataTexH;
uniform int f_ants;
uniform int f_pointerDown;
uniform vec2 f_pointerPosition;

const float speed = 15.0;
const float movementChangeChance = 0.3;
const float randomChangeDirectionChangeSpeed = 3.0;
const float pheremoneDetectionDirectionChangeSpeed = 3.1;
const float chanceOfGoingLeft = 0.5;
const float RAD = 6.283185307179586;
const float pointerMagneticDistance = 400.0;
const float pmdSquared = (pointerMagneticDistance * pointerMagneticDistance);

const float div255 = 0.0039215686274509803921568627451;
const float ninetyDegressRadians = 1.5708;

const float marginOfError = 0.0000001;
const float scaleDiv = 1.0 / float(SCALE);

// float random(vec2 seed) {
//   return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
// }

float random(vec2 seed, float t)
{
  float r = t * 7.924;
  return fract(sin(seed.y+seed.x)*r+sin(seed.y-seed.x)*r*.7);
}

float max3 (vec4 v) {
  return max(max(v.x, v.y), v.z);
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

float getPheremoneStrength(vec4 texel, float antIndex, int ants) {
  vec4 color = vec4(getColor(antIndex, ants), 1.0);
  return max3(texel);
}

float angleDiff(float a1, float a2) {
  a1 = mod(a1, RAD);
  a2 = mod(a2, RAD);
  float d = a2 - a1;
  if (d > RAD * 0.5) d = d - RAD;
  return d;
}

void main()
{
  int antsDataTotal = f_ants * 2;
  float maxWidth = min((f_viewport.x - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));
  float maxHeight = min((f_viewport.y - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));

  float _maxHeightHO = floor(maxHeight / 255.0);
  float _maxHeightLO = maxHeight - (_maxHeightHO * 255.0);

  float _maxWidthHO = floor(maxWidth / 255.0);
  float _maxWidthLO = maxWidth - (_maxWidthHO * 255.0);

  float maxHeightHO = _maxHeightHO * div255;
  float maxHeightLO = _maxHeightLO * div255;

  float maxWidthHO = _maxWidthHO * div255;
  float maxWidthLO = _maxWidthLO * div255;

  float halfStepW = (1.0 / float(ANTS_DATA_TEX_W)) / 2.0;
  float halfStepH = (1.0 / float(f_antsDataTexH)) / 2.0;

  if (f_renderMode == 1) {
    float antIndex = floor(gl_FragCoord.x) + (floor(gl_FragCoord.y) * float(ANTS_DATA_TEX_W));

    if (mod(antIndex, 2.0) < 1.0) {
      float firstAntX = mod(antIndex, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
      float firstAntY = floor((antIndex) / float(ANTS_DATA_TEX_W)) / float(f_antsDataTexH) + halfStepH;

      vec4 firstComp = texture2D(antsTexture, vec2(firstAntX, firstAntY));

      float secondAntX = mod(antIndex + 1.0, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
      float secondAntY = floor((antIndex + 1.0) / float(ANTS_DATA_TEX_W)) / float(f_antsDataTexH) + halfStepH;

      vec4 secondComp = texture2D(antsTexture, vec2(secondAntX, secondAntY));

      float xHO = firstComp[0];
      float xLO = firstComp[1];
      float yHO = firstComp[2];
      float yLO = secondComp[0];
      float hdg = secondComp[1];

      float radians = hdg * RAD;
      float xDelta = cos(radians) * speed * div255;
      float yDelta = sin(radians) * speed * div255;

      // move accross the x axis
      xLO += xDelta;
      if (xLO > 1.0) {
        float amount = floor(xLO);
        xHO += div255 * amount;
        xLO -= amount;
      } else if (xLO < 0.0) {
        float amount = abs(floor(xLO));

        if (xHO < div255 - marginOfError) {
          xHO = 0.0;
          xLO = 0.0;
        } else {
          xHO -= div255 * amount;
          xLO += amount;
        }
      }

      // check if outside frame
      else if (xHO > (maxWidthHO - marginOfError) && xLO > (maxWidthLO - marginOfError)) {
        xHO = maxWidthHO;
        xLO = maxWidthLO - div255;
      }

      // move accross the y axis
      yLO += yDelta;
      if (yLO > 1.0) {
        float amount = floor(yLO);
        yHO += div255 * amount;
        yLO -= amount;
      } 
      if (yLO < 0.0) {
        float amount = floor(yLO);
        yHO -= div255 * abs(amount);

        // check if outside frame
        if (yHO < 0.0) {
          yHO = 0.0;
          yLO = 0.0;
        } else {
          yLO += abs(amount);
        }
      }

      // check if outside frame
      if (yHO > (maxHeightHO - marginOfError) && yLO > (maxHeightLO - marginOfError)) {
        yHO = maxHeightHO - marginOfError;
      }

      gl_FragColor = vec4(xHO, xLO, yHO, 1.0);
      return;
    } else {
      float firstAntX = mod(antIndex - 1.0, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
      float firstAntY = floor((antIndex - 1.0) / float(ANTS_DATA_TEX_W)) / float(f_antsDataTexH) + halfStepH;

      vec4 firstComp = texture2D(antsTexture, vec2(firstAntX, firstAntY));

      float secondAntX = mod(antIndex, float(ANTS_DATA_TEX_W)) / float(ANTS_DATA_TEX_W) + halfStepW;
      float secondAntY = floor(antIndex / float(ANTS_DATA_TEX_W)) / float(f_antsDataTexH) + halfStepH;

      vec4 secondComp = texture2D(antsTexture, vec2(secondAntX, secondAntY));

      float xHO = firstComp[0];
      float xLO = firstComp[1];
      float yHO = firstComp[2];
      float yLO = secondComp[0];
      float hdg = secondComp[1];
      float unused = secondComp[2];

      float radians = hdg * RAD;
      float xDelta = cos(radians) * speed * div255;
      float yDelta = sin(radians) * speed * div255;

      float x = (xHO * 255.0 + xLO) * scaleDiv * 255.0;
      float y = (yHO * 255.0 + yLO) * scaleDiv * 255.0;

      float pointerX = f_pointerPosition.x * f_viewport.x;
      float pointerY = f_pointerPosition.y * f_viewport.y;

      float pDiffX = x - pointerX;
      float pDiffY = y - pointerY;
      float pDiffXAbs = abs(pDiffX);
      float pDiffYAbs = abs(pDiffY);
      bool isInfluencedByPointer = f_pointerDown > 0 && pDiffXAbs < pointerMagneticDistance && pDiffYAbs < pointerMagneticDistance
        && (pDiffXAbs * pDiffXAbs + pDiffYAbs * pDiffYAbs) < pmdSquared;

      // determine phermone direction
      vec2 pheremoneForwardPixelPos = vec2(cos(radians), sin(radians)) * float(PHERMONE_RECEPTOR_DISTANCE) + vec2(x, y);
      vec4 pheremoneForwardTexel = texture2D(pheremonesTexture, vec2(pheremoneForwardPixelPos.x / f_viewport.x, pheremoneForwardPixelPos.y / f_viewport.y));
      float pheremoneForward = getPheremoneStrength(pheremoneForwardTexel, antIndex, f_ants);

      vec2 pheremoneLeftPixelPos = vec2(cos(radians - ninetyDegressRadians), sin(radians - ninetyDegressRadians)) * float(PHERMONE_RECEPTOR_DISTANCE) + pheremoneForwardPixelPos;
      vec4 pheremoneLeftTexel = texture2D(pheremonesTexture, vec2(pheremoneLeftPixelPos.x / f_viewport.x, pheremoneLeftPixelPos.y / f_viewport.y));
      float pheremoneLeft = getPheremoneStrength(pheremoneLeftTexel, antIndex, f_ants);

      vec2 pheremoneRightPixelPos = vec2(cos(radians + ninetyDegressRadians), sin(radians + ninetyDegressRadians)) * float(PHERMONE_RECEPTOR_DISTANCE) + pheremoneForwardPixelPos;
      vec4 pheremoneRightTexel = texture2D(pheremonesTexture, vec2(pheremoneRightPixelPos.x / f_viewport.x, pheremoneRightPixelPos.y / f_viewport.y));
      float pheremoneRight = getPheremoneStrength(pheremoneRightTexel, antIndex, f_ants);

      if (pheremoneLeft > pheremoneRight && pheremoneLeft > pheremoneForward) {
        // float strengthDelta = pheremoneLeft - pheremoneForward;
        hdg -= div255 * pheremoneDetectionDirectionChangeSpeed;
      }

      else if (pheremoneRight > pheremoneLeft && pheremoneRight > pheremoneForward) {
        // float strengthDelta = pheremoneRight - pheremoneForward;
        hdg += div255 * pheremoneDetectionDirectionChangeSpeed;
      }

      if (random(vec2(antIndex + (2.2 + xHO) * (12.1 + yHO), (yLO + 17.9) * (xLO + 1.2)), hdg) < movementChangeChance) {
        if (random(vec2(antIndex + (3.21 + xHO) * (3.2 + yHO), (yLO + 12.2) * (xLO + 91.2)), hdg) < chanceOfGoingLeft) {
          // go left
          hdg -= div255 * randomChangeDirectionChangeSpeed;
        } else {
          // go right
          hdg += div255 * randomChangeDirectionChangeSpeed;
        }
      }

      if (isInfluencedByPointer) {
        float strength = (pmdSquared / (pDiffXAbs * pDiffXAbs + pDiffYAbs * pDiffYAbs + pmdSquared) - 0.5) * 2.0; // value between 0 - 1

        float pAngle = atan(pDiffY, pDiffX);

        if (f_pointerDown == 1) {
          float pAngleDiff = angleDiff(pAngle, radians);
          hdg -= pAngleDiff * 0.02 * strength;
        }
        if (f_pointerDown == 2) {
          float pAngleDiff = angleDiff(radians, pAngle);
          hdg -= pAngleDiff * 0.02 * strength;
        }
      }

      if (hdg > 1.0) hdg -= 1.0;
      if (hdg < 0.0) hdg += 1.0;

      // move accross the x axis
      xLO += xDelta;
      if (xLO > 1.0) {
        float amount = floor(xLO);
        xHO += div255 * amount;
        xLO -= amount;
      } else if (xLO < 0.0) {
        float amount = abs(floor(xLO));

        // check if outside frame
        if (xHO < div255 - marginOfError) {
          hdg = 0.5 - hdg;
        } else {
          xHO -= div255 * amount;
          xLO += amount;
        }
      }
      
      // check if outside frame
      else if (xHO > (maxWidthHO - marginOfError) && xLO > (maxWidthLO - marginOfError)) {
        hdg = 0.5 - hdg;
      }

      // move accross the y axis
      yLO += yDelta;
      if (yLO > 1.0) {
        float amount = floor(yLO);

        yHO += div255 * amount;
        yLO -= amount;
      } else if (yLO < 0.0) {
        float amount = floor(yLO);

        // check if outside frame
        if (yHO < div255 - marginOfError) {
          yHO = 0.0;
          yLO = 0.0;
          hdg = 1.0 - hdg;
        } else {
          yHO -= div255 * abs(amount);
          yLO += abs(amount);
        }
      }

      // check if outside frame
      if (yHO > (maxHeightHO - marginOfError) && yLO > (maxHeightLO - marginOfError)) {
        hdg = 1.0 - hdg;
        yLO = maxHeightLO - div255;
      }

      if (hdg > 1.0) {
        hdg -= 1.0;
      } else if (hdg < 0.0) {
        hdg += 1.0;
      }

      gl_FragColor = vec4(yLO, hdg, unused, 1.0);
      return;
    }
  } else if (f_renderMode == 2) {
    // blur

    // TODO: try glGenerateTextureMipmap instead

    vec4 texel1 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / f_viewport.x, gl_FragCoord.y / f_viewport.y));

    vec4 texel2 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / f_viewport.x, (gl_FragCoord.y + 1.0) / f_viewport.y)) * BLUR_SPEED;
    vec4 texel3 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / f_viewport.x, gl_FragCoord.y / f_viewport.y)) * BLUR_SPEED;
    vec4 texel4 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / f_viewport.x, (gl_FragCoord.y - 1.0) / f_viewport.y)) * BLUR_SPEED;
    vec4 texel5 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / f_viewport.x, gl_FragCoord.y / f_viewport.y)) * BLUR_SPEED;

    vec4 texel6 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / f_viewport.x, (gl_FragCoord.y + 1.0) / f_viewport.y)) * BLUR_SPEED;
    vec4 texel7 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / f_viewport.x, (gl_FragCoord.y - 1.0) / f_viewport.y)) * BLUR_SPEED;
    vec4 texel8 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / f_viewport.x, (gl_FragCoord.y - 1.0) / f_viewport.y)) * BLUR_SPEED;
    vec4 texel9 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / f_viewport.x, (gl_FragCoord.y + 1.0) / f_viewport.y)) * BLUR_SPEED;

    vec3 average = (texel1.xyz + texel2.xyz + texel3.xyz + texel4.xyz + texel5.xyz + texel6.xyz + texel7.xyz + texel8.xyz + texel9.xyz) / (1.0 + 8.0 * BLUR_SPEED);

    gl_FragColor = vec4(average * (1.0 - PHEREMONE_EVAPORATION_SPEED_RELATIVE) - PHEREMONE_EVAPORATION_SPEED, 1.0);
  } else if (f_renderMode == 3) {
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    gl_FragColor = vec4(color.xyz, 1.0);
  } else if (f_renderMode == 4) {
    gl_FragColor = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / f_viewport.x, gl_FragCoord.y / f_viewport.y));
  }
}
