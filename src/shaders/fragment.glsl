precision highp float;

#pragma glslify: color = require('./color.glsl');
#pragma glslify: edge = require('./edge.glsl');

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;

varying vec2 v_TextureCoord;

void main() {
  vec3 c = color(u_Texture, v_TextureCoord, u_Resolution);
  vec3 e = edge(u_Texture, v_TextureCoord, u_Resolution);
  gl_FragColor = vec4(c - e, 1.0);
}
