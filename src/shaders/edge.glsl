#pragma glslify: intensityGradient = require('./intensity_gradient.glsl');

vec3 edge(sampler2D texSampler, vec2 texCoord, vec2 resolution) {
  vec2 result = intensityGradient(texSampler, texCoord, resolution);
  for (int i = 0; i < 2; i++) {
    result[i] = pow(result[i], 0.75);
  }
  if (length(result) >= 0.7) {
    result = vec2(1.0 / pow(2.0, 0.5));
  } else if (length(result) < 0.25) {
    result = vec2(0.2 / pow(2.0, 0.5));
  } else if (length(result) < 0.05) {
    result = vec2(0.0);
  }
  return vec3(length(result));
}

#pragma glslify: export(edge);
