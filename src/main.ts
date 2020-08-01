import Frame from './Frame';
import Scene from './Scene';
import Shader from './Shader';
import {Vector2Attribute} from './ShaderAttribute';
import {FloatUniform, IntegerUniform, Vector2Uniform} from './ShaderUniform';

const FULL_VIEW_PLANE_VERTICES = [-1, 1, -1, -1, 1, 1, 1, -1];
const FULL_PLANE_VIEW_TEX_COORDS = [1, 0, 1, 1, 0, 0, 0, 1];
const LIGHTNESS_OFFSET = 0.05;

function initScene(canvas: HTMLCanvasElement, video: HTMLVideoElement) {
  const scene = new Scene(canvas);

  const vertexShaderSrc = require('./shaders/vertex.glsl').default as string;
  const fragmentShaderSrc = require(
    './shaders/fragment.glsl').default as string;
  const shader = new Shader(vertexShaderSrc, fragmentShaderSrc, {
    aVertices: new Vector2Attribute(
      'a_Position', {data: FULL_VIEW_PLANE_VERTICES}),
    aTextureCoord: new Vector2Attribute(
      'a_TextureCoord', {data: FULL_PLANE_VIEW_TEX_COORDS}),
  }, {
    uTexture: new IntegerUniform('u_Texture', {data: 0}),
    uResolution: new Vector2Uniform(
      'u_Resolution', {data: [canvas.width, canvas.height]}),
    uLightnessOffset: new FloatUniform(
      'u_LightnessOffset', {data: LIGHTNESS_OFFSET}),
  });
  scene.addFrame('main', new Frame(canvas.width, canvas.height, 4, shader));

  scene.addTexture('video', video);

  scene.render(true, () => {
    scene.bindTexture('video', WebGLRenderingContext.TEXTURE0);
    scene.renderFrameToCanvas('main');
  });
}

document.body.onload = async function main() {
  const canvas = document.getElementById('canvas') as HTMLCanvasElement;
  let stream: MediaStream;
  try {
    stream = await navigator.mediaDevices.getUserMedia({
      video: {
        width: canvas.width,
        height: canvas.height,
        aspectRatio: 1,
      },
    });
  } catch (err) {
    console.error(err);
    window.alert('Failed to get webcam video');
  }
  const video = document.getElementById('video') as HTMLVideoElement;
  video.srcObject = stream;
  video.play();
  video.onplaying = () => initScene(canvas, video);
}