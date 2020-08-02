#pragma glslify: blur = require('./blur.glsl');
#pragma glslify: convolute = require('./convolute.glsl');

// Use the Prewitt operator for taking the gradient.
const mat3 X_GRAD_KERNEL = mat3(1.0, 0.0, -1.0,
                                1.0, 0.0, -1.0,
                                1.0, 0.0, -1.0);
const mat3 Y_GRAD_KERNEL = mat3( 1.0,  1.0,  1.0,
                                 0.0,  0.0,  0.0,
                                -1.0, -1.0, -1.0);

float intensity(vec3 color) {
  return pow(length(clamp(color, vec3(0.0), vec3(1.0))), 2.0) / 3.0;
}

// Compute the images intensity gradient using convolutions.
// 1. First apply a 3x3 gaussian blur kernel to the texture.
// 2. Compute the intensity of the 3x3 grid of pixels around the current coordinate.
// 3. Apply 3x3 Prewitt operator to detect edges in x and y direction.
// Return vector
vec2 intensityGradient(sampler2D texSampler, vec2 texCoord, vec2 resolution) {
  vec2 ds = vec2(1.0) / resolution;
  mat3 M = mat3(0.0);
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      vec2 coord = texCoord + vec2(-ds.x + (float(i) * ds.x),
                                   -ds.y + (float(j) * ds.y));
      M[i][j] = intensity(blur(texSampler, coord, resolution));
    }
  }
  return vec2(convolute(M, X_GRAD_KERNEL),
              convolute(M, Y_GRAD_KERNEL));
}

#pragma glslify: export(intensityGradient);