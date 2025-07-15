import { useEffect } from 'react'
import { useControls } from 'leva'

interface ControlsProps {
  onColorChange: (color: string) => void
  onSpeedChange: (speed: number) => void
}

const Controls = ({ onColorChange, onSpeedChange }: ControlsProps) => {
  const { color, speed } = useControls({
    color: { value: '#679ac0', label: 'Watercolor Color' },
    speed: { value: 1.4, min: 0.1, max: 10.0, step: 0.1, label: 'Animation Speed' }
  })

  // Call parent callbacks when values change
  useEffect(() => {
    onColorChange(color)
  }, [color, onColorChange])

  useEffect(() => {
    onSpeedChange(speed)
  }, [speed, onSpeedChange])

  return null
}

export default Controls