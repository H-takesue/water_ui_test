# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a React + TypeScript project built with Vite that uses Three.js, React Three Fiber, and Drei for 3D graphics and WebGL rendering. The project features an animated gradient circle as the main visual element.

## Development Commands

```bash
# Install dependencies
npm install

# Run development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview

# Run linter
npm run lint
```

## Architecture Notes

### Tech Stack
- **React 18** with TypeScript
- **Vite** as the build tool
- **Three.js** for 3D graphics
- **@react-three/fiber** for React integration with Three.js
- **@react-three/drei** for useful Three.js helpers and components

### Project Structure
- `/src/components/` - React components including 3D elements
  - `AnimatedCircle.tsx` - Main animated gradient circle component using custom shaders
- `/src/App.tsx` - Main app component with Canvas setup
- WebGL shaders are written inline in the AnimatedCircle component for the gradient animation