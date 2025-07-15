import { useState } from 'react'
import { Canvas } from '@react-three/fiber'
import { OrbitControls } from '@react-three/drei'
import { Leva, useControls } from 'leva'
import AnimatedCircle from './components/AnimatedCircle'
import './App.css'

function App() {
  const { color, speed } = useControls({
    color: { value: '#679ac0', label: 'Watercolor Color' },
    speed: { value: 1.4, min: 0.1, max: 10.0, step: 0.1, label: 'Animation Speed' }
  })

  return (
    <>
      <Leva />
      <div style={{ 
        width: '100vw', 
        height: '100vh', 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center' 
      }}>
        <Canvas 
          style={{ 
            width: '132px', 
            height: '132px',
            borderRadius: '50%',
            boxShadow: '0 8px 32px rgba(0, 0, 0, 0.3)',
            border: 'none',
            outline: 'none',
            pointerEvents: 'none'
          }}
          camera={{ position: [0, 0, 5] }}
        >
          <ambientLight intensity={0.5} />
          <AnimatedCircle color={color} speed={speed} />
          <OrbitControls enableZoom={false} />
        </Canvas>
      </div>
    </>
  )
}

export default App
