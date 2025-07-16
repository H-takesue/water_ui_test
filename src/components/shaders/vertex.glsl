varying vec2 vUv;

void main() {
  vUv = uv;
  // 頂点の最終位置を計算
  gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
}