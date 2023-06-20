#define ANTS 5000
#define ANTS_DATA 6
#define ANTS_DATA_TOTAL 10000
#define WINDOW_WIDTH 1920.0
#define WINDOW_HEIGHT 1080.0
#define PHERMONE_RECEPTOR_DISTANCE 12.0
#define BLUR_SPEED 0.05

#define ANTS_COORDS_LIMIT 65280
#define SCALE 10
#define PHEREMONE_EVAPORATION_SPEED 0.004

precision mediump float;

varying vec3 color;
varying vec2 antsTexture_coord;

uniform sampler2D antsTexture;
uniform sampler2D pheremonesTexture;
uniform int f_renderMode;

const float speed = 20.0;
const float movementChangeChance = 0.15;
const float randomChangeDirectionChangeSpeed = 2.0;
const float pheremoneDetectionDirectionChangeSpeed = 3.5;
const float chanceOfGoingLeft = 0.1;
const float RAD = 6.283185307179586;
const float maxWidth = min((WINDOW_WIDTH - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));
const float maxHeight = min((WINDOW_HEIGHT - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));

const float div255 = 0.0039215686274509803921568627451;
const float ninetyDegressRadians = 1.5708;

const float _maxHeightHO = floor(maxHeight / 255.0);
const float _maxHeightLO = maxHeight - (_maxHeightHO * 255.0);

const float _maxWidthHO = floor(maxWidth / 255.0);
const float _maxWidthLO = maxWidth - (_maxWidthHO * 255.0);

const float maxHeightHO = _maxHeightHO * div255;
const float maxHeightLO = _maxHeightLO * div255;

const float maxWidthHO = _maxWidthHO * div255;
const float maxWidthLO = _maxWidthLO * div255;

const float marginOfError = 0.0000001;
const float scaleDiv = 1.0 / float(SCALE);

float random(vec2 seed) {
  return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
  if (f_renderMode == 1) {
    float index = gl_FragCoord.x;

    if (mod(index, 2.0) < 1.0) {
      vec4 firstComp = texture2D(antsTexture, vec2(index / float(ANTS_DATA_TOTAL), 0.5));
      vec4 secondComp = texture2D(antsTexture, vec2((index + 1.0) / float(ANTS_DATA_TOTAL), 0.5));

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
      vec4 firstComp = texture2D(antsTexture, vec2((index - 1.0) / float(ANTS_DATA_TOTAL), 0.5));
      vec4 secondComp = texture2D(antsTexture, vec2((index) / float(ANTS_DATA_TOTAL), 0.5));

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

      // determine phermone direction
      vec2 pheremoneForwardPixelPos = vec2(cos(radians), sin(radians)) * float(PHERMONE_RECEPTOR_DISTANCE) + vec2(x, y);
      vec4 pheremoneForwardTexel = texture2D(pheremonesTexture, vec2(pheremoneForwardPixelPos.x / WINDOW_WIDTH, pheremoneForwardPixelPos.y / WINDOW_HEIGHT));

      vec2 pheremoneLeftPixelPos = vec2(cos(radians - ninetyDegressRadians), sin(radians - ninetyDegressRadians)) * float(PHERMONE_RECEPTOR_DISTANCE) + pheremoneForwardPixelPos;
      vec4 pheremoneLeftTexel = texture2D(pheremonesTexture, vec2(pheremoneLeftPixelPos.x / WINDOW_WIDTH, pheremoneLeftPixelPos.y / WINDOW_HEIGHT));

      vec2 pheremoneRightPixelPos = vec2(cos(radians + ninetyDegressRadians), sin(radians + ninetyDegressRadians)) * float(PHERMONE_RECEPTOR_DISTANCE) + pheremoneForwardPixelPos;
      vec4 pheremoneRightTexel = texture2D(pheremonesTexture, vec2(pheremoneRightPixelPos.x / WINDOW_WIDTH, pheremoneRightPixelPos.y / WINDOW_HEIGHT));

      if (pheremoneLeftTexel.x > pheremoneRightTexel.x && pheremoneLeftTexel.x > pheremoneForwardTexel.x) {
        // float strengthDelta = pheremoneLeftTexel.x - pheremoneForwardTexel.x;
        hdg -= div255 * pheremoneDetectionDirectionChangeSpeed;
      }

      else if (pheremoneRightTexel.x > pheremoneLeftTexel.x && pheremoneRightTexel.x > pheremoneForwardTexel.x) {
        // float strengthDelta = pheremoneRightTexel.x - pheremoneForwardTexel.x;
        hdg += div255 * pheremoneDetectionDirectionChangeSpeed;
      }

      if (random(vec2(index + (2.2 + xHO) * (12.1 + yHO), (yLO + 17.9) * (xLO + 1.2))) < movementChangeChance) {
        if (random(vec2(index + (3.21 + xHO) * (3.2 + yHO), (yLO + 12.2) * (xLO + 91.2))) < chanceOfGoingLeft) {
          // go left
          hdg -= div255 * randomChangeDirectionChangeSpeed;
        } else {
          // go right
          hdg += div255 * randomChangeDirectionChangeSpeed;
        }
        if (hdg > 1.0) hdg -= 1.0;
        if (hdg < 0.0) hdg += 1.0;
      }

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

    vec4 texel1 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / WINDOW_WIDTH, gl_FragCoord.y / WINDOW_HEIGHT));

    vec4 texel2 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / WINDOW_WIDTH, (gl_FragCoord.y + 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel3 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / WINDOW_WIDTH, gl_FragCoord.y / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel4 = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / WINDOW_WIDTH, (gl_FragCoord.y - 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel5 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / WINDOW_WIDTH, gl_FragCoord.y / WINDOW_HEIGHT)) * BLUR_SPEED;

    vec4 texel6 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / WINDOW_WIDTH, (gl_FragCoord.y + 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel7 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x + 1.0) / WINDOW_WIDTH, (gl_FragCoord.y - 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel8 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / WINDOW_WIDTH, (gl_FragCoord.y - 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;
    vec4 texel9 = texture2D(pheremonesTexture, vec2((gl_FragCoord.x - 1.0) / WINDOW_WIDTH, (gl_FragCoord.y + 1.0) / WINDOW_HEIGHT)) * BLUR_SPEED;

    vec3 average = (texel1.xyz + texel2.xyz + texel3.xyz + texel4.xyz + texel5.xyz + texel6.xyz + texel7.xyz + texel8.xyz + texel9.xyz) / (1.0 + 8.0 * BLUR_SPEED);

    gl_FragColor = vec4(average - PHEREMONE_EVAPORATION_SPEED, 1.0);
  } else if (f_renderMode == 3) {
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
    gl_FragColor = vec4(color.xyz, 1.0);
  } else if (f_renderMode == 4) {
    gl_FragColor = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / WINDOW_WIDTH, gl_FragCoord.y / WINDOW_HEIGHT));
  }
}
