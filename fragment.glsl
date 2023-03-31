precision mediump float;

#define ANTS 10

varying vec3 color;
varying vec3 test[10];
varying vec4 ants[ANTS];
varying vec2 texture1_coord;

varying float first;

uniform sampler2D texture1;

void main()
{
  gl_FragColor = vec4 ( color, 1.0 );

  // gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
  if (gl_FragCoord.x > 100.0 && gl_FragCoord.y > 100.0) {
    // gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
  }

  for(int i = 0; i < ANTS; i++) {
    if (gl_FragColor.x > ants[i][0] && gl_FragColor.x < (ants[i][0] + 0.1)
      && gl_FragColor.y > ants[i][1] && gl_FragColor.y < (ants[i][1] + 0.1)) {
        gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0);
        
    }
  }

  gl_FragColor = texture2D(texture1, vec2(0.0, gl_FragCoord.y / 600.0));
  // gl_FragColor = vec4 ( color, 1.0 );
}
