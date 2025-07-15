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

// Paper texture
float paperTexture(vec2 st) {
  return noise(st * 200.0) * 0.1 + noise(st * 100.0) * 0.05;
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

// Brush painting effect with linear strokes
float brushPainting(vec2 st, float time) {
  float brushStroke = 0.0;
  
  // Slower, more reasonable brush strokes
  for (int i = 0; i < 10; i++) {
    float t = time * 1.5 + float(i) * 0.6;
    
    // More controlled strokes with reasonable frequency
    vec2 strokeDir = vec2(
      cos(t * 0.8 + float(i) * 2.0) + sin(t * 0.4) * 0.3,
      sin(t * 0.6 + float(i) * 1.5) + cos(t * 0.5) * 0.3
    );
    vec2 strokeStart = vec2(0.5, 0.5) + vec2(
      sin(t * 0.7) + cos(t * 0.3) * 0.3,
      cos(t * 0.5) + sin(t * 0.6) * 0.3
    ) * 0.4;
    
    // Distance from point to line
    vec2 toPoint = st - strokeStart;
    float alongStroke = dot(toPoint, strokeDir);
    float perpDist = length(toPoint - strokeDir * alongStroke);
    
    // Calmer brush stroke with gentle variation
    float strokeWidth = 0.2 + sin(t * 1.2) * 0.1 + cos(t * 0.8) * 0.08;
    float stroke = 1.0 - smoothstep(0.0, strokeWidth, perpDist);
    stroke *= 1.0 - smoothstep(strokeWidth * 0.4, strokeWidth, perpDist);
    
    // Gentle stroke length variation
    float strokeLength = 0.6 + sin(t * 0.9) * 0.3 + cos(t * 0.7) * 0.2;
    stroke *= 1.0 - smoothstep(0.0, strokeLength, abs(alongStroke));
    
    // Subtle intensity variation
    stroke *= 0.7 + sin(t * 1.1) * 0.2 + cos(t * 0.9) * 0.1;
    
    // Add brush texture for roughness
    float brushRoughness = brushTexture(st, strokeDir);
    stroke *= (0.7 + brushRoughness * 0.3); // Modulate with brush texture
    
    brushStroke += stroke * (1.0 - float(i) * 0.25);
  }
  
  return clamp(brushStroke, 0.0, 1.0);
}

// Paint coverage effect with linear patterns - gentle movement with more diffusion
float paintCoverage(vec2 st, float time) {
  float coverage = 0.0;
  
  // Gentle horizontal wash with wider spread
  float horizontal = abs(st.y - 0.5 - sin(time * 0.6) * 0.15 - cos(time * 0.4) * 0.1);
  coverage += (1.0 - smoothstep(0.02, 0.6, horizontal)) * (0.5 + sin(time * 0.5) * 0.15);
  
  // Gentle vertical wash with wider spread
  float vertical = abs(st.x - (0.4 + sin(time * 0.45) * 0.12) - cos(time * 0.55) * 0.08);
  coverage += (1.0 - smoothstep(0.02, 0.5, vertical)) * (0.4 + cos(time * 0.4) * 0.12);
  
  // Gentle diagonal wash with wider spread
  float diagonal = abs((st.x - st.y) - sin(time * 0.5) * 0.18 - cos(time * 0.35) * 0.15);
  coverage += (1.0 - smoothstep(0.02, 0.55, diagonal)) * (0.4 + sin(time * 0.6) * 0.12);
  
  // Add radial diffusion from center
  float centerDist = length(st - 0.5);
  float radialDiffusion = 1.0 - smoothstep(0.1, 0.45, centerDist);
  coverage += radialDiffusion * (0.3 + sin(time * 0.3) * 0.1);
  
  return clamp(coverage, 0.0, 1.0);
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
  
  // Calculate brush painting
  // float inkAmount = brushPainting(uv, uTime);
  
  // Add paint coverage
  float inkAmount = paintCoverage(uv, uTime);
  
  // Gentle ink intensity variation
  float inkVariation = noise(uv * 6.0 + uTime * 0.8) * 0.2;
  inkVariation += noise(uv * 12.0 + uTime * 1.0) * 0.15;
  inkVariation += noise(uv * 24.0 + uTime * 1.2) * 0.1;
  inkAmount *= (0.8 + inkVariation);
  
  // Add overall brush texture to entire surface
  float globalBrushTexture = brushTexture(uv, vec2(1.0, 0.0));
  inkAmount *= (0.8 + globalBrushTexture * 0.2);
  
  // Mix paper and ink with stronger diffusion
  vec3 col = mix(paperColor, inkColor, inkAmount * 0.9);
  
  // Add soft edge diffusion
  float edgeDiffusion = 1.0 - smoothstep(0.3, 0.5, dist);
  col = mix(col, inkColor, edgeDiffusion * 0.2);
  
  gl_FragColor = vec4(col * circle, circle);
}