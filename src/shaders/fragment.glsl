precision highp float;

varying vec2 v_TextureCoord;

uniform sampler2D u_Texture;
uniform vec2 u_Resolution;
uniform float u_LightnessOffset;

const mat3 BLUR_KERNEL = mat3(0.0625, 0.125, 0.0625,
                              0.125,  0.25,  0.125,
                              0.0625, 0.125, 0.0625);
// Use the Sobel operator for taking the gradient.
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

// Compute the images intensity gradient using convolutions.
// 1. First apply a 3x3 gaussian blur kernel to the texture.
// 2. Compute the intensity of the 3x3 grid of pixels around the current coordinate.
// 3. Apply 3x3 Sobel operator to detect edges in x and y direction.
// Return vector
vec2 intensityGradient(sampler2D texSampler, vec2 texCoord) {
  vec2 ds = vec2(1.0) / u_Resolution;
  mat3 M = mat3(0.0);
  for (int i = 0; i < 3; i++) {
    for (int j = 0; j < 3; j++) {
      vec2 coord = texCoord + vec2(-ds.x + (float(i) * ds.x),
                                   -ds.y + (float(j) * ds.y));
      M[i][j] = intensity(blur(texSampler, coord));
    }
  }
  return vec2(convoluteMatrices(M, X_GRAD_KERNEL),
              convoluteMatrices(M, Y_GRAD_KERNEL));
}

// From https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// From https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 edge(sampler2D texSampler, vec2 texCoord) {
  vec2 result = intensityGradient(u_Texture, v_TextureCoord);
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

vec3 color(sampler2D texSampler, vec2 texCoord) {
  // Convert from RGB to HSV, this makes manipulating color easier.
  vec3 hsv = rgb2hsv(texture2D(texSampler, texCoord).xyz);
  // Reduce the number of colors to 8.
  float nColors = 12.0;
  hsv[0] = floor(2.0 * nColors * hsv[0] + 0.5) / 2.0 / nColors;
  // Add comic book dots for colors.
  if (floor(nColors * hsv[0] + 0.5) / nColors != hsv[0]) {
    hsv[0] = floor(nColors * hsv[0] + 0.5) / nColors;
    if (length(texCoord - (floor(100.0 * texCoord + 0.5) / 100.0)) <= 0.002) {
      hsv[0] -= 1.0 / nColors;
    }
  }
  // Add cel shading.
  float originalV = hsv[2];
  float nCels = 12.0;
  hsv[2] = floor(nCels * hsv[2] + 0.5) / nCels;
  hsv[2] = clamp(hsv[2] + u_LightnessOffset, 0.0, 1.0);
  // Add black dots for the darkest areas.
  if (originalV < 0.2
      && length(texCoord - (floor(100.0 * texCoord + 0.5) / 100.0)) <= 0.002) {
    hsv[2] = 0.0;
  }
  return hsv2rgb(hsv);
}

void main() {
  vec3 c = color(u_Texture, v_TextureCoord);
  vec3 e = edge(u_Texture, v_TextureCoord);
  gl_FragColor = vec4(c - e, 1.0);
}
