precision highp float;

varying vec2 v_TextureCoord;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;

const mat3 BLUR_KERNEL = mat3(0.0625, 0.125, 0.0625,
                              0.125,  0.25,  0.125,
                              0.0625, 0.125, 0.0625);
// Use the Prewitt operator for taking the gradient.
const mat3 X_GRAD_KERNEL = mat3(1.0, 0.0, -1.0,
                                1.0, 0.0, -1.0,
                                1.0, 0.0, -1.0);
const mat3 Y_GRAD_KERNEL = mat3( 1.0,  1.0,  1.0,
                                 0.0,  0.0,  0.0,
                                -1.0, -1.0, -1.0);

float convoluteMatrices(mat3 A, mat3 B) {
  return dot(A[0], B[0]) + dot(A[1], B[1]) + dot(A[2], B[2]);
}

vec3 blur(sampler2D texSampler, vec2 texCoord) {
  vec2 ds = vec2(1.0) / u_Resolution;
  vec3 result = vec3(0.0);
  for (int i = 0; i < 3; i++) {
    mat3 M = mat3(0.0);
    for (int j = 0; j < 3; j++) {
      for (int k = 0; k < 3; k++) {
        vec2 coord = texCoord + vec2(-ds.x + (float(j) * ds.x),
                                     -ds.y + (float(k) * ds.y));
        M[j][k] = texture2D(texSampler, coord)[i];
      }
    }
    result[i] = convoluteMatrices(M, BLUR_KERNEL);
  }
  return result;
}

float intensity(vec3 color) {
  return pow(length(clamp(color, vec3(0.0), vec3(1.0))), 2.0) / 3.0;
}

vec2 intensityGradient(sampler2D texSampler, vec2 texCoord) {
  vec2 ds = vec2(1.0) / u_Resolution;
  mat3 M = mat3(0.0);
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      vec2 coord = texCoord + vec2(-ds.x + (float(i) * ds.x),
                                   -ds.y + (float(j) * ds.y));
      M[i][j] = length(blur(texSampler, coord));
    }
  }
  return vec2(convoluteMatrices(M, X_GRAD_KERNEL),
              convoluteMatrices(M, Y_GRAD_KERNEL));
}

void main() {
  vec2 grad = intensityGradient(u_Texture, v_TextureCoord);
  float g = pow(length(grad), 2.0);
  gl_FragColor = vec4(1.0 - vec3(g), 1.0);
}
