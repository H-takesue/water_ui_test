uniform float uTime;
uniform vec3 uColor;
varying vec2 vUv;

// Noise function for organic patterns
float noise(vec2 st) {
  vec2 i = floor(st);
  vec2 f = fract(st);
  
  float a = fract(sin(dot(i, vec2(12.9898, 78.233))) * 43758.5453123);
  float b = fract(sin(dot(i + vec2(1.0, 0.0), vec2(12.9898, 78.233))) * 43758.5453123);
  float c = fract(sin(dot(i + vec2(0.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453123);
  float d = fract(sin(dot(i + vec2(1.0, 1.0), vec2(12.9898, 78.233))) * 43758.5453123);
  
  vec2 u = f * f * (3.0 - 2.0 * f);
  return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

// 紙のテクスチャ（水彩紙の質感）
float paperTexture(vec2 st) {
  // 粗い紙の質感
  float rough = noise(st * 50.0) * 0.08;
  // 細かい繊維
  float fine = noise(st * 150.0) * 0.04;
  // より細かい粒子
  float grain = noise(st * 300.0) * 0.02;
  
  return rough + fine + grain;
}

// Brush texture for roughness
float brushTexture(vec2 st, vec2 strokeDir) {
  // Rotate coordinates along stroke direction
  vec2 rotated = vec2(
    dot(st, strokeDir),
    dot(st, vec2(-strokeDir.y, strokeDir.x))
  );
  
  // Create brush fiber texture
  float fibers = 0.0;
  fibers += noise(rotated * vec2(50.0, 200.0)) * 0.8;
  fibers += noise(rotated * vec2(100.0, 400.0)) * 0.4;
  fibers += noise(rotated * vec2(200.0, 800.0)) * 0.2;
  
  return fibers;
}

// 水彩のにじみ効果（よりダイナミックに）
float paintCoverage(vec2 st, float time) {
  float coverage = 0.0;
  
  // より多くの不規則なにじみの中心点
  for (int i = 0; i < 8; i++) {
    float fi = float(i);
    // 各にじみの中心位置（固定だが分散）
    vec2 center = vec2(
      0.5 + sin(fi * 3.1) * 0.35,
      0.5 + cos(fi * 2.3) * 0.35
    );
    
    // 中心からの距離
    float dist = length(st - center);
    
    // より強い不規則な形状のためのノイズ変調（時間で変化）
    float noiseOffset = noise(st * 4.0 + vec2(time * 0.4, fi * 7.0)) * 0.25;
    noiseOffset += noise(st * 12.0 + vec2(fi * 5.0, time * 0.6)) * 0.15;
    noiseOffset += noise(st * 25.0 + vec2(time * 0.8, fi * 3.0)) * 0.08;
    dist += noiseOffset;
    
    // にじみの強度（中心が濃く、外側に向かって薄くなる）- より大きくじわっと広がる
    float blobSize = 0.45 + sin(time * 0.4 + fi * 2.5) * 0.15 + cos(time * 0.3 + fi * 1.8) * 0.1;
    float blob = 1.0 - smoothstep(0.0, blobSize, dist);
    // さらに外側に薄く広がる効果
    float outerBlob = 1.0 - smoothstep(blobSize * 0.8, blobSize * 1.8, dist);
    blob = max(blob, outerBlob * 0.4);
    
    // 穏やかな時間による強度変化
    float intensity = 0.7 + sin(time * 0.3 + fi * 2.3) * 0.15 + cos(time * 0.2 + fi * 1.4) * 0.1;
    
    coverage += blob * intensity * (1.0 - fi * 0.1);
  }
  
  // より強いエッジの不規則性
  float edgeNoise = noise(st * 6.0 + time * 0.2) * 0.4 + noise(st * 18.0) * 0.3;
  coverage *= (0.6 + edgeNoise);
  
  // 全体的に広がる効果を追加（控えめに）
  float globalSpread = 0.1 + sin(time * 0.2) * 0.03;
  coverage = clamp(coverage + globalSpread, 0.0, 1.0);
  
  return coverage;
}

void main() {
  vec2 uv = vUv;
  float dist = length(uv - 0.5);
  
  // Create softer circle shape
  float circle = 1.0 - step(0.5, dist);
  
  // Paper base color (slightly off-white)
  vec3 paperColor = vec3(0.96, 0.96, 0.94);
  
  // Add paper texture
  float paperGrain = paperTexture(uv);
  paperColor += paperGrain;
  
  // Watercolor ink color from uniform
  vec3 inkColor = uColor;
  
  // Add paint coverage
  float inkAmount = paintCoverage(uv, uTime);
  
  // 水彩の濃淡変化（紙への染み込み効果）
  float inkVariation = noise(uv * 3.0) * 0.3;  // 大きなスケールの変化
  inkVariation += noise(uv * 8.0) * 0.2;       // 中間スケール
  inkVariation += noise(uv * 20.0) * 0.1;      // 細かいテクスチャ
  
  // 時間による微妙な呼吸のような変化
  float breathing = sin(uTime * 0.5) * 0.05 + cos(uTime * 0.3) * 0.03;
  inkAmount *= (0.7 + inkVariation + breathing);
  
  // Add overall brush texture to entire surface
  float globalBrushTexture = brushTexture(uv, vec2(1.0, 0.0));
  inkAmount *= (0.8 + globalBrushTexture * 0.2);
  
  // 水彩の透明感を表現（複数の色を重ねる）
  vec3 col = paperColor;
  
  // ベースカラーから近い色を生成（より明確な色の違い）
  vec3 color1 = inkColor;
  vec3 color2 = inkColor * vec3(0.7, 0.9, 1.2); // 明確に青みがかった色
  vec3 color3 = inkColor * vec3(1.2, 0.8, 0.7); // 明確に赤みがかった色
  vec3 color4 = inkColor * vec3(0.8, 1.1, 0.8); // 明確に緑みがかった色
  
  // 第一層：広がる薄い染み（複数の色を空間的に分布）
  float layer1 = inkAmount * 0.6;
  float colorZone1 = noise(uv * 2.0) * 0.5 + 0.5; // 時間に依存しない
  vec3 mixedColor1 = mix(color1, color2, colorZone1);
  col = mix(col, mixedColor1, layer1);
  
  // 第二層：中間の濃さ（位置によって色が変わる）
  float layer2Mask = noise(uv * 3.0) * 0.8 + 0.2;
  float layer2 = inkAmount * 0.45 * layer2Mask;
  float colorZone2 = noise(uv * 3.0 + vec2(0.5, 0.5)) * 0.5 + 0.5;
  vec3 mixedColor2 = mix(color3, color4, colorZone2);
  col = mix(col, mixedColor2, layer2);
  
  // 第三層：濃い部分（固定された色の分布）
  float layer3Mask = noise(uv * 5.0) * 0.7 + 0.3;
  float layer3 = inkAmount * 0.35 * layer3Mask;
  float colorZone3 = noise(uv * 2.5) * 0.5 + 0.5;
  vec3 mixedColor3 = mix(color1, color3, colorZone3);
  col = mix(col, mixedColor3, layer3);
  
  // 第四層：じわっと広がる淡い層
  float outerLayer = clamp(inkAmount * 0.3, 0.0, 0.4);
  vec3 outerColor = mix(color2, color4, noise(uv * 1.5));
  col = mix(col, outerColor, outerLayer);
  
  gl_FragColor = vec4(col * circle, circle);
}