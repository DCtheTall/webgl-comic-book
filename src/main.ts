import Frame from './Frame';
import Scene from './Scene';
import Shader from './Shader';
import {Vector2Attribute} from './ShaderAttribute';
import {IntegerUniform} from './ShaderUniform';

const FULL_VIEW_PLANE_VERTICES = [-1, 1, -1, -1, 1, 1, 1, -1];
const FULL_PLANE_VIEW_TEX_COORDS = [1, 0, 1, 1, 0, 0, 0, 1];

function initScene(video: HTMLVideoElement) {
  const canvas = document.getElementById('canvas') as HTMLCanvasElement;
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
  });
  scene.addFrame('main', new Frame(canvas.width, canvas.height, 4, shader));

  scene.addTexture('video', video);

  scene.render(true, () => {
    scene.bindTexture('video', WebGLRenderingContext.TEXTURE0);
    scene.renderFrameToCanvas('main');
  });
}

document.body.onload = async function main() {
  let stream: MediaStream;
  try {
    stream = await navigator.mediaDevices.getUserMedia({video: true});
  } catch (err) {
    console.error(err);
    window.alert('Failed to get webcam video');
  }
  const video = document.getElementById('video') as HTMLVideoElement;
  video.srcObject = stream;
  video.play();
  video.onplaying = () => initScene(video);
}