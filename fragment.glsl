#define ANTS 200
#define ANTS_DATA 6
#define ANTS_DATA_TOTAL 400
#define WINDOW_WIDTH 640.0
#define WINDOW_HEIGHT 640.0

#define ANTS_COORDS_LIMIT 65280
#define SCALE 10

precision mediump float;

varying vec3 color;
varying vec2 antsTexture_coord;

uniform sampler2D antsTexture;
uniform sampler2D pheremonesTexture;
uniform int f_renderMode;

const float speed = 10.0;
const float movementChangeChance = 0.5;
const float chanceOfGoingLeft = 0.5;
const float RAD = 6.283185307179586;
const float maxWidth = min((WINDOW_WIDTH - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));
const float maxHeight = min((WINDOW_HEIGHT - 1.0) * float(SCALE), float(ANTS_COORDS_LIMIT - 1));

const float div255 = 0.0039215686274509803921568627451;

const float _maxHeightHO = floor(maxHeight / 255.0);
const float _maxHeightLO = maxHeight - (_maxHeightHO * 255.0);

const float _maxWidthHO = floor(maxWidth / 255.0);
const float _maxWidthLO = maxWidth - (_maxWidthHO * 255.0);

const float maxHeightHO = _maxHeightHO * div255;
const float maxHeightLO = _maxHeightLO * div255;

const float maxWidthHO = _maxWidthHO * div255;
const float maxWidthLO = _maxWidthLO * div255;

const float marginOfError = 0.0000001;

float random(vec2 seed) {
  return fract(sin(dot(seed, vec2(12.9898, 78.233))) * 43758.5453);
}

void main()
{
  if (f_renderMode == 1) {
    float x = gl_FragCoord.x;

    if (mod(x, 2.0) < 1.0) {
      vec4 firstComp = texture2D(antsTexture, vec2(x / float(ANTS_DATA_TOTAL), 1.0));
      vec4 secondComp = texture2D(antsTexture, vec2((x + 1.0) / float(ANTS_DATA_TOTAL), 1.0));

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
        xHO -= div255 * amount;

        // check if outside frame
        if (xHO < 0.0) {
          xHO = 0.0;
          xLO = 0.0;
        } else {
          xLO += amount;
        }
      }

      // check if outside frame
      if (xHO > (maxWidthHO - marginOfError) && xLO > (maxWidthLO - marginOfError)) {
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
      vec4 firstComp = texture2D(antsTexture, vec2((x - 1.0) / float(ANTS_DATA_TOTAL), 1.0));
      vec4 secondComp = texture2D(antsTexture, vec2((x) / float(ANTS_DATA_TOTAL), 1.0));

      float xHO = firstComp[0];
      float xLO = firstComp[1];
      float yHO = firstComp[2];
      float yLO = secondComp[0];
      float hdg = secondComp[1];
      float unused = secondComp[2];

      float radians = hdg * RAD;
      float xDelta = cos(radians) * speed * div255;
      float yDelta = sin(radians) * speed * div255;

      if (random(vec2((2.2 + xHO) * (12.1 + yHO), (yLO + 17.9) * (xLO + 1.2))) > movementChangeChance) {
        if (random(vec2((3.21 + xHO) * (3.2 + yHO), (yLO + 12.2) * (xLO + 91.2))) < chanceOfGoingLeft) {
          // go left
          // hdg -= div255;
        } else {
          // go right
          // hdg += div255;
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

        xHO -= div255 * amount;

        // check if outside frame
        if (xHO < 0.0) {
          hdg = 0.5 - hdg;
        }
      }
      
      // check if outside frame
      if (xHO > (maxWidthHO - marginOfError) && xLO > (maxWidthLO - marginOfError)) {
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
        yHO -= div255 * abs(amount);

        // check if outside frame
        if (yHO < 0.0) {
          yHO = 0.0;
          yLO = 0.0;
          hdg = 1.0 - hdg;
        } else {
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

    // extract ants data
  } else if (f_renderMode == 2) {
    gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
  } else if (f_renderMode == 3) {
    gl_FragColor = texture2D(pheremonesTexture, vec2(gl_FragCoord.x / WINDOW_WIDTH, gl_FragCoord.y / WINDOW_HEIGHT));
  }
}
