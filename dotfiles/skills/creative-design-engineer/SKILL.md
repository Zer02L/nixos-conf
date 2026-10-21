---
name: creative-design-engineer
description: "Expert Design Engineer & Creative Motion Director. Transforms standard UI into award-winning, interactive, physics-based motion interfaces (Awwwards/Linear/Apple/Stripe grade) using Framer Motion, GSAP, Tailwind CSS, and Canvas/Shaders."
---

# Creative Design & Motion Engineering

A precision skill for designing and building bespoke, tactile, and expressive digital interfaces. Eliminates generic "AI template" aesthetics in favor of studio-grade craft, dynamic micro-interactions, and physics-driven motion design.

---

## 1. Anti-AI-Slop & Aesthetics Foundation

Standard AI output suffers from predictable cliches. Follow these strict creative constraints:

### Visual Anti-Patterns (BANNED)
- **NO generic purple-to-blue gradients** (`from-purple-500 to-indigo-500`).
- **NO identical 3-column feature cards** with centered Lucide icons in colored rounded squares.
- **NO pure `#000000` or `#ffffff` backgrounds** without atmosphere, depth, or tinting.
- **NO arbitrary border radii**: Do not slap `rounded-2xl` on everything without spatial hierarchy.
- **NO lifeless CSS easing**: Never use `transition: all 0.3s ease` or linear timing for interactive elements.

### The Studio Standard
1. **Atmosphere & Depth**:
   - Deep tinted darks: `#08090c`, `#0a0d14`, `#070709` instead of flat black.
   - Fine-grained borders: `border border-white/[0.08]` or dynamic gradient borders.
   - Ambient light: Multi-layered radial gradients with large blurs (`blur-[120px]`) and low opacities (`opacity-15` to `opacity-30`).
   - Tactile texture: Subtle SVG noise overlay with mix-blend mode (`opacity-20 mix-blend-overlay`).
2. **Editorial Typography**:
   - High contrast between headline scales and metadata.
   - Tight tracking on large display headers (`tracking-tight` or `tracking-tighter`).
   - Pairing modern geometric sans (Geist, Inter, Cabinet Grotesk) with crisp monospace metadata tags (`font-mono text-xs uppercase tracking-widest text-muted-foreground`).
3. **Dynamic Layout Composition**:
   - Asymmetric Bento grids with varying aspect ratios (`col-span-1 md:col-span-2`, row spans).
   - Layered visual cues (overlapping badges, interactive preview viewports, edge fades with CSS masks).

---

## 2. Motion Design & Physics System

Motion must feel organic, responsive, and physical—not mechanical.

### Spring Configurations (Framer Motion / Motion)
Never rely on duration + ease curves for user gestures. Use springs:

```typescript
export const springs = {
  // Instant tactile feedback (buttons, toggles, micro-clicks)
  snappy: { type: "spring", stiffness: 450, damping: 30, mass: 0.8 },
  
  // Smooth UI transitions (sheet openings, tabs, accordion expand)
  smooth: { type: "spring", stiffness: 260, damping: 26 },
  
  // Cinematic / spatial entry (hero elements, modal backdrop, cards)
  cinematic: { type: "spring", stiffness: 120, damping: 19, mass: 1.1 },
  
  // Bouncy / playful (badges, status pings, confetti)
  bouncy: { type: "spring", stiffness: 350, damping: 15 }
};
```

### Choreography & Orchestration
1. **Staggered Reveals**:
   - Animate parents with `variants` setting `staggerChildren: 0.04` to `0.07`.
   - Initial states should feel grounded: subtle vertical offset (`y: 12` to `y: 20`), blur fade (`filter: blur(4px) -> blur(0px)`), and `opacity: 0 -> 1`.
2. **Shared Layout Morphing (`layoutId`)**:
   - Use `layoutId` for sliding tab indicators, morphing search bars, and expanding cards.
   - Always wrap conditionally mounted components in `<AnimatePresence mode="popLayout">` or `mode="wait"`.
3. **Gestures & Micro-interactions**:
   - **Tactile Click**: `whileTap={{ scale: 0.97 }}`
   - **Hover Lift**: `whileHover={{ y: -2, transition: springs.snappy }}`
   - **Tilt & Sheen**: Calculate cursor coordinates relative to element center to adjust 3D rotation and gradient spotlight position.

---

## 3. High-Impact Component Recipes

### A. Dynamic Spotlight Card (Mouse-tracking glow)

```tsx
"use client";
import React, { useRef } from "react";
import { motion, useMotionTemplate, useMotionValue } from "framer-motion";

export function SpotlightCard({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  const mouseX = useMotionValue(-1000);
  const mouseY = useMotionValue(-1000);

  function handleMouseMove({ currentTarget, clientX, clientY }: React.MouseEvent) {
    const { left, top } = currentTarget.getBoundingClientRect();
    mouseX.set(clientX - left);
    mouseY.set(clientY - top);
  }

  function handleMouseLeave() {
    mouseX.set(-1000);
    mouseY.set(-1000);
  }

  return (
    <div
      onMouseMove={handleMouseMove}
      onMouseLeave={handleMouseLeave}
      className={`group relative overflow-hidden rounded-2xl border border-white/[0.08] bg-zinc-950/60 p-8 backdrop-blur-xl ${className}`}
    >
      {/* Dynamic Cursor Spotlight */}
      <motion.div
        className="pointer-events-none absolute -inset-px rounded-2xl opacity-0 transition-opacity duration-300 group-hover:opacity-100"
        style={{
          background: useMotionTemplate`
            radial-gradient(
              450px circle at ${mouseX}px ${mouseY}px,
              rgba(255, 255, 255, 0.08),
              transparent 80%
            )
          `,
        }}
      />
      <div className="relative z-10">{children}</div>
    </div>
  );
}
```

### B. Morphing Floating Tabs (Shared LayoutId)

```tsx
"use client";
import { useState } from "react";
import { motion } from "framer-motion";

const tabs = ["Overview", "Performance", "Security", "Activity"];

export function MorphingTabs() {
  const [active, setActive] = useState(tabs[0]);

  return (
    <div className="flex items-center gap-1 rounded-full border border-white/[0.08] bg-zinc-900/70 p-1.5 backdrop-blur-md">
      {tabs.map((tab) => {
        const isActive = active === tab;
        return (
          <button
            key={tab}
            onClick={() => setActive(tab)}
            className="relative px-4 py-1.5 text-xs font-medium tracking-wide transition-colors"
            style={{ color: isActive ? "#ffffff" : "rgba(255, 255, 255, 0.5)" }}
          >
            {isActive && (
              <motion.div
                layoutId="active-pill"
                className="absolute inset-0 rounded-full bg-white/[0.12] shadow-[0_0_12px_rgba(255,255,255,0.06)]"
                transition={{ type: "spring", stiffness: 380, damping: 30 }}
              />
            )}
            <span className="relative z-10">{tab}</span>
          </button>
        );
      })}
    </div>
  );
}
```

---

## 4. Performance & Engineering Constraints

1. **GPU-Accelerated Properties**: Only animate `transform` (`x`, `y`, `scale`, `rotate`) and `opacity`. Never animate `width`, `height`, `margin`, or `padding` directly without layout projection.
2. **Reduced Motion**: Respect accessibility by providing fallback states:
   ```typescript
   import { useReducedMotion } from "framer-motion";
   const shouldReduceMotion = useReducedMotion();
   const initial = shouldReduceMotion ? { opacity: 0 } : { opacity: 0, y: 16 };
   ```
3. **Canvas & 3D Layering**: When embedding Three.js / R3F canvases or shader backgrounds, keep them non-blocking with `pointer-events-none` and limit DPR (`dpr={[1, 1.5]}`) to preserve mobile battery and frame rate.
