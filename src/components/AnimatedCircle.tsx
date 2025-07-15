import { useRef, useEffect } from 'react'
import { useFrame } from '@react-three/fiber'
import { Mesh, ShaderMaterial, Vector3 } from 'three'
import vertexShader from './shaders/vertex.glsl?raw'
import fragmentShader from './shaders/fragment.glsl?raw'

interface AnimatedCircleProps {
  color: string
  speed: number
}

const AnimatedCircle = ({ color, speed }: AnimatedCircleProps) => {
  const meshRef = useRef<Mesh>(null)
  const materialRef = useRef<ShaderMaterial>(null)
  const currentColorRef = useRef([103, 194, 192])
  const targetColorRef = useRef([103, 154, 192])
  
  // Stable uniforms reference - the key to preventing animation stops
  const uniformsRef = useRef({
    uTime: { value: 0 },
    uColor: { value: new Vector3(0.6, 0.8, 0.95) }
  })

  // Convert hex color to RGB
  const hexToRgb = (hex: string) => {
    const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex)
    return result ? [
      parseInt(result[1], 16),
      parseInt(result[2], 16),
      parseInt(result[3], 16)
    ] : [103, 154, 192]
  }

  // Update target color when props change
  useEffect(() => {
    targetColorRef.current = hexToRgb(color)
  }, [color])

  // useFrame with stable uniforms reference
  useFrame((state) => {
    const uniforms = uniformsRef.current
    
    // Update time
    if (uniforms.uTime) {
      uniforms.uTime.value = state.clock.getElapsedTime() * speed
    }
    
    // Update color with smooth transition
    if (uniforms.uColor?.value) {
      const lerpSpeed = 0.01
      const current = currentColorRef.current
      const target = targetColorRef.current
      
      const newR = current[0] + (target[0] - current[0]) * lerpSpeed
      const newG = current[1] + (target[1] - current[1]) * lerpSpeed
      const newB = current[2] + (target[2] - current[2]) * lerpSpeed
      
      currentColorRef.current = [newR, newG, newB]
      
      uniforms.uColor.value.x = newR / 255
      uniforms.uColor.value.y = newG / 255
      uniforms.uColor.value.z = newB / 255
    }
  })

  const radius = 3.7

  return (
    <mesh ref={meshRef}>
      <circleGeometry args={[radius, 64]} />
      <shaderMaterial
        ref={materialRef}
        vertexShader={vertexShader}
        fragmentShader={fragmentShader}
        uniforms={uniformsRef.current}
        transparent
        key="watercolor-shader" // Prevent recreation
      />
    </mesh>
  )
}

export default AnimatedCircle