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
  
  // 類似色相の生成（より明確な色の違い）
  vec3 color1 = inkColor;
  
  // RGB空間で類似色を作成（より視覚的に分かりやすい変化）
  vec3 color2 = inkColor + vec3(-0.15, 0.05, 0.2);  // 青みを強く
  vec3 color3 = inkColor + vec3(0.2, -0.05, -0.15); // 赤みを強く
  vec3 color4 = inkColor + vec3(-0.05, 0.15, 0.1);  // 緑みを追加
  vec3 color5 = inkColor + vec3(0.1, 0.05, -0.1);   // 黄みを追加
  vec3 color6 = inkColor + vec3(0.05, -0.1, 0.15);  // 紫みを追加
  
  // 色が範囲外にならないようクランプ
  color2 = clamp(color2, 0.0, 1.0);
  color3 = clamp(color3, 0.0, 1.0);
  color4 = clamp(color4, 0.0, 1.0);
  color5 = clamp(color5, 0.0, 1.0);
  color6 = clamp(color6, 0.0, 1.0);
  
  // 水彩の自然な色の重なり（各色が認識できる程度に混ざる）
  
  // ベースとなる色の分布（ソフトな境界）
  float noise1 = noise(uv * 2.5);
  float noise2 = noise(uv * 3.0 + vec2(1.0, 0.0));
  float noise3 = noise(uv * 2.8 + vec2(0.0, 1.0));
  
  // 第一層：基本色を中心に広がる（よりソフトに）
  float layer1Strength = inkAmount * 0.8;
  float layer1Mask = smoothstep(0.2, 0.8, noise1);
  col = mix(col, color1, layer1Strength * layer1Mask);
  
  // 第二層：青みの領域（より広く滲む）
  float layer2Strength = inkAmount * 0.6;
  float layer2Mask = smoothstep(0.3, 0.85, noise2) * smoothstep(0.15, 0.6, noise1);
  col = mix(col, color2, layer2Strength * layer2Mask);
  
  // 第三層：赤みの領域（より広く滲む）
  float layer3Strength = inkAmount * 0.65;
  float layer3Mask = smoothstep(0.35, 0.8, noise3) * (1.0 - layer2Mask * 0.2);
  col = mix(col, color3, layer3Strength * layer3Mask);
  
  // より広い境界部分で色が混ざる効果（にじみを強化）
  float boundary12 = 1.0 - smoothstep(0.0, 0.3, abs(noise1 - noise2));
  float boundary23 = 1.0 - smoothstep(0.0, 0.25, abs(noise2 - noise3));
  float boundary13 = 1.0 - smoothstep(0.0, 0.28, abs(noise1 - noise3));
  
  // 境界での混色（よりグラデーション的に）
  vec3 mixColor12 = mix(color1, color2, 0.5 + sin(uTime * 0.3) * 0.1);
  vec3 mixColor23 = mix(color2, color3, 0.5 + cos(uTime * 0.25) * 0.1);
  vec3 mixColor13 = mix(color1, color3, 0.5 + sin(uTime * 0.35) * 0.1);
  
  // にじみの強度を上げる
  col = mix(col, mixColor12, boundary12 * inkAmount * 0.5);
  col = mix(col, mixColor23, boundary23 * inkAmount * 0.45);
  col = mix(col, mixColor13, boundary13 * inkAmount * 0.4);
  
  // 追加のにじみ効果（色が流れ込む表現）
  float bleed1 = smoothstep(0.5, 0.3, noise1) * smoothstep(0.3, 0.6, noise2);
  float bleed2 = smoothstep(0.55, 0.35, noise2) * smoothstep(0.35, 0.65, noise3);
  float bleed3 = smoothstep(0.5, 0.25, noise3) * smoothstep(0.25, 0.55, noise1);
  
  col = mix(col, color2 * 1.1, bleed1 * inkAmount * 0.3);
  col = mix(col, color3 * 1.05, bleed2 * inkAmount * 0.28);
  col = mix(col, color1 * 1.08, bleed3 * inkAmount * 0.25);
  
  // 緑み・黄み・紫みを局所的に追加
  float accent1 = smoothstep(0.7, 0.9, noise(uv * 5.0 + vec2(2.0, 1.0)));
  float accent2 = smoothstep(0.72, 0.88, noise(uv * 4.5 + vec2(1.0, 2.0)));
  float accent3 = smoothstep(0.75, 0.85, noise(uv * 6.0 + vec2(3.0, 0.0)));
  
  col = mix(col, color4, accent1 * inkAmount * 0.2);
  col = mix(col, color5, accent2 * inkAmount * 0.18);
  col = mix(col, color6, accent3 * inkAmount * 0.15);
  
  gl_FragColor = vec4(col * circle, circle);
}