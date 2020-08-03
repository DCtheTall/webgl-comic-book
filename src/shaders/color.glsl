#pragma glslify: blur = require('./blur.glsl');
#pragma glslify: hsv2rgb = require('./hsv2rgb.glsl');
#pragma glslify: rgb2hsv = require('./rgb2hsv.glsl');

vec3 color(sampler2D texSampler, vec2 texCoord, vec2 resolution) {
  // Convert from RGB to HSV, this makes manipulating color easier.
  vec3 hsv = rgb2hsv(blur(texSampler, texCoord, resolution));
  
  // Reduce the number of colors to 24.
  float nColors = 12.0;
  hsv.x = floor(2.0 * nColors * hsv.x + 0.5) / 2.0 / nColors;
  
  // Draw secondary colors as comic book dots and two primary colors.
  if (floor(nColors * hsv.x + 0.5) / nColors != hsv.x) {
    hsv.x = floor(nColors * hsv.x + 0.5) / nColors;
    if (length(texCoord - (floor(100.0 * texCoord + 0.5) / 100.0)) <= 0.002) {
      hsv.x -= 1.0 / nColors;
    }
  }
  
  // Adjust the saturation.
  hsv.y = clamp(pow(hsv.y, 0.75) - 0.05, 0.0, 1.0);
  
  // Add cel shading.
  float originalV = hsv.z;
  float nCels = 12.0;
  hsv.z = floor(nCels * hsv.z + 0.5) / nCels;
  // Add a slight offset.
  hsv.z = clamp(hsv.z + 0.05, 0.0, 1.0);
  
  // Add black dots in dark areas and black out the darkest areas.
  if (originalV < 0.3
      && length(texCoord - (floor(100.0 * texCoord + 0.5) / 100.0)) <= 0.002) {
    hsv.z = 0.0;
  } else if (originalV < 0.15) {
    hsv.z = 0.0;
  }
  return hsv2rgb(hsv);
}

#pragma glslify: export(color);
