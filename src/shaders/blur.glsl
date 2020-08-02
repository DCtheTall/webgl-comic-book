#pragma glslify: convolute = require('./convolute.glsl');

const mat3 BLUR_KERNEL = mat3(0.0625, 0.125, 0.0625,
                              0.125,  0.25,  0.125,
                              0.0625, 0.125, 0.0625);

vec3 blur(sampler2D texSampler, vec2 texCoord, vec2 resolution) {
  vec2 ds = vec2(1.0) / resolution;
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
    result[i] = convolute(M, BLUR_KERNEL);
  }
  return result;
}

#pragma glslify: export(blur);