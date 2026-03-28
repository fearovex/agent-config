---
name: gsap-react-motion
description: >
  GSAP and Motion (Framer Motion) animation patterns for React: timelines, scroll-linked, gestures, springs, layout animations, and performance optimization.
format: reference
---

# gsap-react-motion

> Expert patterns for creating and optimizing animations with GSAP (GreenSock) and Motion (formerly Framer Motion) in React applications.

**Triggers**: gsap, greensock, framer-motion, motion, react animation, scroll animation, timeline, spring animation, gesture animation, layout animation, animate, transition, whileHover, whileTap, ScrollTrigger, useScroll, useAnimate, useGSAP

---

## Patterns

### Pattern 1: GSAP with React — useGSAP Hook

The `@gsap/react` package provides `useGSAP()` for automatic cleanup and scoping.

```tsx
import { useRef } from "react"
import gsap from "gsap"
import { useGSAP } from "@gsap/react"

gsap.registerPlugin(useGSAP)

function AnimatedCard() {
  const container = useRef<HTMLDivElement>(null)

  useGSAP(() => {
    // All selectors are scoped to the container ref
    gsap.to(".card-title", { opacity: 1, y: 0, duration: 0.8 })
    gsap.to(".card-body", { opacity: 1, y: 0, duration: 0.8, delay: 0.2 })
  }, { scope: container }) // auto-cleanup on unmount

  return (
    <div ref={container}>
      <h2 className="card-title" style={{ opacity: 0, transform: "translateY(20px)" }}>Title</h2>
      <p className="card-body" style={{ opacity: 0, transform: "translateY(20px)" }}>Body</p>
    </div>
  )
}
```

### Pattern 2: GSAP Timeline — Sequenced Animations

```tsx
import { useRef } from "react"
import gsap from "gsap"
import { useGSAP } from "@gsap/react"

function HeroSection() {
  const container = useRef<HTMLDivElement>(null)

  useGSAP(() => {
    const tl = gsap.timeline({ defaults: { ease: "power3.out" } })

    tl.from(".hero-bg", { scale: 1.2, duration: 1.5 })
      .from(".hero-title", { opacity: 0, y: 60, duration: 0.8 }, "-=0.8")  // overlap
      .from(".hero-subtitle", { opacity: 0, y: 40, duration: 0.6 }, "-=0.4")
      .from(".hero-cta", { opacity: 0, scale: 0.8, duration: 0.5 }, "-=0.2")
  }, { scope: container })

  return (
    <div ref={container}>
      <div className="hero-bg" />
      <h1 className="hero-title">Welcome</h1>
      <p className="hero-subtitle">Subtitle here</p>
      <button className="hero-cta">Get Started</button>
    </div>
  )
}
```

### Pattern 3: GSAP ScrollTrigger

```tsx
import { useRef } from "react"
import gsap from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { useGSAP } from "@gsap/react"

gsap.registerPlugin(ScrollTrigger)

function ScrollRevealSection() {
  const container = useRef<HTMLDivElement>(null)

  useGSAP(() => {
    gsap.from(".reveal-item", {
      scrollTrigger: {
        trigger: ".reveal-item",
        start: "top 80%",
        end: "top 20%",
        toggleActions: "play none none reverse",
        // scrub: true,  // tie animation to scroll position
      },
      opacity: 0,
      y: 80,
      stagger: 0.15,
      duration: 0.8,
    })
  }, { scope: container })

  return (
    <section ref={container}>
      {items.map((item, i) => (
        <div key={i} className="reveal-item">{item.text}</div>
      ))}
    </section>
  )
}
```

**ScrollTrigger toggleActions**: `"onEnter onLeave onEnterBack onLeaveBack"` — values: `play`, `pause`, `resume`, `reset`, `restart`, `complete`, `reverse`, `none`.

### Pattern 4: GSAP Stagger Patterns

```tsx
useGSAP(() => {
  // Basic stagger
  gsap.from(".grid-item", {
    opacity: 0, scale: 0.8,
    stagger: 0.1,
    duration: 0.5,
  })

  // Grid stagger (2D wave effect)
  gsap.from(".grid-item", {
    opacity: 0, scale: 0,
    stagger: {
      each: 0.08,
      grid: [4, 6],        // rows x cols
      from: "center",      // "start" | "end" | "center" | "edges" | "random" | index
      axis: "x",           // "x" | "y" | null (both)
    },
    duration: 0.4,
    ease: "back.out(1.7)",
  })
}, { scope: container })
```

### Pattern 5: GSAP Reactive Animations (State-Driven)

```tsx
function Toggle({ isOpen }: { isOpen: boolean }) {
  const container = useRef<HTMLDivElement>(null)

  useGSAP(() => {
    gsap.to(".menu", {
      height: isOpen ? "auto" : 0,
      opacity: isOpen ? 1 : 0,
      duration: 0.4,
      ease: "power2.inOut",
    })
  }, { dependencies: [isOpen], scope: container })

  return (
    <div ref={container}>
      <div className="menu" style={{ overflow: "hidden" }}>
        <nav>Menu content</nav>
      </div>
    </div>
  )
}
```

### Pattern 6: GSAP Context for Manual Control

```tsx
function PlayerAnimation() {
  const container = useRef<HTMLDivElement>(null)
  const tl = useRef<gsap.core.Timeline>(null)

  useGSAP(() => {
    tl.current = gsap.timeline({ paused: true })
      .to(".player", { x: 200, duration: 1 })
      .to(".player", { rotation: 360, duration: 0.5 })
      .to(".player", { scale: 1.5, duration: 0.3 })
  }, { scope: container })

  return (
    <div ref={container}>
      <div className="player" />
      <button onClick={() => tl.current?.play()}>Play</button>
      <button onClick={() => tl.current?.reverse()}>Reverse</button>
      <button onClick={() => tl.current?.restart()}>Restart</button>
      <button onClick={() => tl.current?.pause()}>Pause</button>
    </div>
  )
}
```

### Pattern 7: GSAP MatchMedia (Responsive Animations)

```tsx
useGSAP(() => {
  const mm = gsap.matchMedia()

  mm.add("(min-width: 768px)", () => {
    gsap.from(".sidebar", { x: -300, duration: 0.8 })
  })

  mm.add("(max-width: 767px)", () => {
    gsap.from(".sidebar", { y: 100, duration: 0.5 })
  })

  mm.add("(prefers-reduced-motion: reduce)", () => {
    gsap.set(".animated", { clearProps: "all" })
  })
}, { scope: container })
```

### Pattern 8: Motion — Basic Animations

```tsx
import { motion } from "motion/react"

// Enter animation
<motion.div
  initial={{ opacity: 0, y: 20 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.5, ease: "easeOut" }}
/>

// Spring physics (default for transform values)
<motion.div
  animate={{ x: 100 }}
  transition={{ type: "spring", visualDuration: 0.5, bounce: 0.25 }}
/>

// Keyframes
<motion.div
  animate={{ x: [0, 100, 50], rotate: [0, 45, 0] }}
  transition={{ duration: 2, times: [0, 0.5, 1] }}
/>
```

### Pattern 9: Motion — Variants for Orchestration

```tsx
const containerVariants = {
  hidden: { opacity: 0 },
  visible: {
    opacity: 1,
    transition: {
      when: "beforeChildren",
      staggerChildren: 0.1,
    },
  },
}

const itemVariants = {
  hidden: { opacity: 0, y: 20 },
  visible: { opacity: 1, y: 0 },
}

function StaggerList({ items }: { items: string[] }) {
  return (
    <motion.ul initial="hidden" animate="visible" variants={containerVariants}>
      {items.map((item) => (
        <motion.li key={item} variants={itemVariants}>
          {item}
        </motion.li>
      ))}
    </motion.ul>
  )
}
```

### Pattern 10: Motion — AnimatePresence (Mount/Unmount)

```tsx
import { motion, AnimatePresence } from "motion/react"

function Modal({ isOpen, onClose }: { isOpen: boolean; onClose: () => void }) {
  return (
    <AnimatePresence>
      {isOpen && (
        <motion.div
          key="backdrop"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          onClick={onClose}
          className="backdrop"
        >
          <motion.div
            key="modal"
            initial={{ opacity: 0, scale: 0.9, y: 20 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 20 }}
            transition={{ type: "spring", visualDuration: 0.4, bounce: 0.15 }}
            onClick={(e) => e.stopPropagation()}
          >
            Modal content
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Page transitions with mode="wait"
<AnimatePresence mode="wait">
  <motion.div
    key={pathname}
    initial={{ opacity: 0, x: 20 }}
    animate={{ opacity: 1, x: 0 }}
    exit={{ opacity: 0, x: -20 }}
  />
</AnimatePresence>
```

### Pattern 11: Motion — Gesture Animations

```tsx
// Interactive button
<motion.button
  whileHover={{ scale: 1.05 }}
  whileTap={{ scale: 0.95 }}
  transition={{ type: "spring", stiffness: 400, damping: 17 }}
>
  Click me
</motion.button>

// Drag with constraints
const constraintsRef = useRef(null)

<div ref={constraintsRef} style={{ overflow: "hidden" }}>
  <motion.div
    drag
    dragConstraints={constraintsRef}
    dragElastic={0.2}
    whileDrag={{ scale: 1.1, cursor: "grabbing" }}
  />
</div>

// Scroll-triggered reveal
<motion.section
  initial={{ opacity: 0, y: 50 }}
  whileInView={{ opacity: 1, y: 0 }}
  viewport={{ once: true, amount: 0.3 }}
  transition={{ duration: 0.6 }}
/>
```

### Pattern 12: Motion — Scroll-Linked Animations

```tsx
import { motion, useScroll, useTransform, useSpring } from "motion/react"

// Progress bar
function ScrollProgress() {
  const { scrollYProgress } = useScroll()
  const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30 })

  return (
    <motion.div
      style={{ scaleX, transformOrigin: "left", position: "fixed", top: 0, left: 0, right: 0, height: 4 }}
    />
  )
}

// Parallax
function Parallax() {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({
    target: ref,
    offset: ["start end", "end start"],
  })
  const y = useTransform(scrollYProgress, [0, 1], ["-20%", "20%"])

  return (
    <div ref={ref} style={{ overflow: "hidden" }}>
      <motion.img src="/bg.jpg" style={{ y }} />
    </div>
  )
}

// Value mapping: scroll → opacity + blur
function FadeOnScroll() {
  const ref = useRef(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ["start end", "center center"] })
  const opacity = useTransform(scrollYProgress, [0, 1], [0, 1])
  const filter = useTransform(scrollYProgress, [0, 1], ["blur(10px)", "blur(0px)"])

  return <motion.div ref={ref} style={{ opacity, filter }}>Content</motion.div>
}
```

### Pattern 13: Motion — Layout Animations

```tsx
import { motion, LayoutGroup } from "motion/react"

// Shared layout: tab underline
function Tabs({ tabs, activeTab, onSelect }) {
  return (
    <nav style={{ display: "flex", gap: 16 }}>
      {tabs.map((tab) => (
        <button key={tab.id} onClick={() => onSelect(tab.id)} style={{ position: "relative" }}>
          {tab.label}
          {activeTab === tab.id && (
            <motion.div
              layoutId="tab-underline"
              style={{ position: "absolute", bottom: -2, left: 0, right: 0, height: 2, background: "blue" }}
              transition={{ type: "spring", visualDuration: 0.3, bounce: 0.15 }}
            />
          )}
        </button>
      ))}
    </nav>
  )
}

// Reorderable list with layout
function ReorderableList({ items }) {
  return (
    <AnimatePresence>
      {items.map((item) => (
        <motion.div
          key={item.id}
          layout                          // animate position changes
          initial={{ opacity: 0, scale: 0.8 }}
          animate={{ opacity: 1, scale: 1 }}
          exit={{ opacity: 0, scale: 0.8 }}
          transition={{ layout: { type: "spring", visualDuration: 0.3, bounce: 0.1 } }}
        >
          {item.content}
        </motion.div>
      ))}
    </AnimatePresence>
  )
}
```

### Pattern 14: Motion — useAnimate (Imperative Control)

```tsx
import { useAnimate, stagger } from "motion/react"

function Notification() {
  const [scope, animate] = useAnimate()

  const handleEnter = async () => {
    await animate(scope.current, { x: 0, opacity: 1 }, { duration: 0.3 })
    await animate(".icon", { rotate: [0, 15, -15, 0] }, { duration: 0.4 })
    await animate(".text", { opacity: 1 }, { duration: 0.2 })
  }

  const handleExit = async () => {
    await animate(".text", { opacity: 0 }, { duration: 0.1 })
    await animate(scope.current, { x: 300, opacity: 0 }, { duration: 0.3 })
  }

  return (
    <div ref={scope} style={{ transform: "translateX(300px)", opacity: 0 }}>
      <span className="icon">🔔</span>
      <span className="text" style={{ opacity: 0 }}>New message</span>
    </div>
  )
}
```

### Pattern 15: GSAP + Motion Coexistence

When both libraries coexist in a project, keep clear boundaries:

```tsx
// Motion: declarative UI state transitions (modals, lists, gestures)
<motion.div layout whileHover={{ scale: 1.02 }}>
  <AnimatePresence>
    {isOpen && <motion.div key="panel" exit={{ opacity: 0 }} />}
  </AnimatePresence>
</motion.div>

// GSAP: complex timelines, ScrollTrigger sequences, fine-grained control
function ComplexScrollSequence() {
  const container = useRef(null)

  useGSAP(() => {
    const tl = gsap.timeline({
      scrollTrigger: {
        trigger: container.current,
        start: "top top",
        end: "+=3000",
        scrub: 1,
        pin: true,
      },
    })
    tl.to(".panel-1", { xPercent: -100 })
      .from(".panel-2-content", { opacity: 0, y: 50 })
      .to(".panel-2", { xPercent: -100 })
      .from(".panel-3-content", { scale: 0.8, opacity: 0 })
  }, { scope: container })

  return <div ref={container}>{/* panels */}</div>
}
```

---

## Performance Optimization

### GPU-Accelerated Properties

| Prefer (GPU) | Avoid (triggers layout) |
|---|---|
| `transform` (x, y, scale, rotate) | `width`, `height`, `top`, `left` |
| `opacity` | `margin`, `padding` |
| `filter` | `border-width`, `font-size` |
| `clip-path` | `box-shadow` (use `filter: drop-shadow`) |

### GSAP Performance Tips

```tsx
// Use will-change for promoted layers (remove after animation)
useGSAP(() => {
  gsap.set(".animated", { willChange: "transform, opacity" })
  gsap.to(".animated", {
    x: 100,
    opacity: 0.5,
    onComplete: () => gsap.set(".animated", { willChange: "auto" }),
  })
}, { scope: container })

// Force3D for GPU acceleration (default: "auto")
gsap.to(".element", { x: 100, force3D: true })

// Batch ScrollTrigger refresh
ScrollTrigger.config({ limitCallbacks: true })

// Kill animations on unmount (useGSAP handles this automatically)
```

### Motion Performance Tips

```tsx
// Use motion values to avoid re-renders
import { useMotionValue, useTransform } from "motion/react"

const x = useMotionValue(0)
const opacity = useTransform(x, [-200, 0, 200], [0, 1, 0])
// x updates do NOT trigger React re-renders
<motion.div style={{ x, opacity }} />

// Mini bundle for lighter builds (~5kb vs ~32kb)
import { motion } from "motion/react-mini"

// Disable layout animation on non-essential elements
<motion.div layout="position" />  // only position, skip size

// Use layoutId sparingly — each one requires DOM measurement
```

### Reduced Motion Support

```tsx
// GSAP
useGSAP(() => {
  const mm = gsap.matchMedia()
  mm.add("(prefers-reduced-motion: reduce)", () => {
    gsap.set(".animated", { clearProps: "all" })
  })
  mm.add("(prefers-reduced-motion: no-preference)", () => {
    gsap.from(".animated", { opacity: 0, y: 40, stagger: 0.1 })
  })
}, { scope: container })

// Motion
import { MotionConfig } from "motion/react"

<MotionConfig reducedMotion="user">
  <App />
</MotionConfig>
```

---

## Quick Reference

| Task | GSAP | Motion |
|------|------|--------|
| Basic animation | `gsap.to(el, { x: 100 })` | `<motion.div animate={{ x: 100 }} />` |
| Sequenced | `gsap.timeline()` | `await animate(...)` chain |
| Scroll-linked | `ScrollTrigger` plugin | `useScroll()` + `useTransform()` |
| Spring physics | N/A (use eases) | `type: "spring", bounce: 0.25` |
| Mount/unmount | Manual (not built-in) | `<AnimatePresence>` |
| Hover/tap | N/A (use JS events) | `whileHover`, `whileTap` |
| Drag | `Draggable` plugin | `drag` prop |
| Layout anim | `Flip` plugin | `layout` prop / `layoutId` |
| Stagger | `stagger: 0.1` | `staggerChildren: 0.1` in variants |
| Responsive | `gsap.matchMedia()` | CSS + variants |
| React cleanup | `useGSAP()` auto-cleanup | Built-in on unmount |
| SSR | Defer to client | `"motion/react-client"` for RSC |

### When to use which

- **GSAP**: Complex timelines, scroll-scrubbed sequences, SVG morphing, precise easing, SplitText, canvas/WebGL integration
- **Motion**: Declarative UI transitions, layout animations, gestures, mount/unmount, quick prototyping, React-idiomatic patterns
- **Both**: Large apps where different sections have different needs — keep boundaries clear per component

---

## Examples

### Complete Example: Animated Landing Page (GSAP)

```tsx
import { useRef } from "react"
import gsap from "gsap"
import { ScrollTrigger } from "gsap/ScrollTrigger"
import { useGSAP } from "@gsap/react"

gsap.registerPlugin(ScrollTrigger)

export function LandingPage() {
  const main = useRef<HTMLElement>(null)

  useGSAP(() => {
    // Hero entrance
    const heroTl = gsap.timeline()
    heroTl
      .from(".hero-title span", { opacity: 0, y: 80, stagger: 0.08, duration: 0.6, ease: "back.out(1.4)" })
      .from(".hero-description", { opacity: 0, y: 30, duration: 0.5 }, "-=0.3")
      .from(".hero-cta", { opacity: 0, scale: 0.9, duration: 0.4 }, "-=0.2")

    // Features scroll reveal
    gsap.utils.toArray<HTMLElement>(".feature-card").forEach((card, i) => {
      gsap.from(card, {
        scrollTrigger: { trigger: card, start: "top 85%", toggleActions: "play none none reverse" },
        opacity: 0,
        y: 60,
        rotation: i % 2 === 0 ? -3 : 3,
        duration: 0.7,
        ease: "power2.out",
      })
    })

    // Pinned horizontal scroll section
    const panels = gsap.utils.toArray<HTMLElement>(".horizontal-panel")
    gsap.to(panels, {
      xPercent: -100 * (panels.length - 1),
      ease: "none",
      scrollTrigger: {
        trigger: ".horizontal-section",
        pin: true,
        scrub: 1,
        end: () => "+=" + document.querySelector(".horizontal-section")!.scrollWidth,
      },
    })
  }, { scope: main })

  return (
    <main ref={main}>
      <section className="hero">
        <h1 className="hero-title">
          {"Welcome Home".split("").map((ch, i) => <span key={i}>{ch === " " ? "\u00A0" : ch}</span>)}
        </h1>
        <p className="hero-description">Build amazing experiences</p>
        <button className="hero-cta">Get Started</button>
      </section>

      <section className="features">
        {features.map((f) => (
          <div key={f.id} className="feature-card">{f.title}</div>
        ))}
      </section>

      <section className="horizontal-section" style={{ display: "flex" }}>
        {panels.map((p) => (
          <div key={p.id} className="horizontal-panel" style={{ minWidth: "100vw" }}>
            {p.content}
          </div>
        ))}
      </section>
    </main>
  )
}
```

### Complete Example: Interactive Dashboard Card (Motion)

```tsx
import { motion, AnimatePresence, useMotionValue, useTransform } from "motion/react"
import { useState } from "react"

const cardVariants = {
  collapsed: { height: 80 },
  expanded: { height: "auto" },
}

const contentVariants = {
  collapsed: { opacity: 0, y: -10 },
  expanded: { opacity: 1, y: 0, transition: { delay: 0.15 } },
}

export function DashboardCard({ title, children, stats }) {
  const [isExpanded, setIsExpanded] = useState(false)
  const x = useMotionValue(0)
  const rotateY = useTransform(x, [-150, 150], [-8, 8])
  const brightness = useTransform(x, [-150, 0, 150], [0.9, 1, 1.1])

  return (
    <motion.div
      layout
      variants={cardVariants}
      animate={isExpanded ? "expanded" : "collapsed"}
      onClick={() => setIsExpanded(!isExpanded)}
      whileHover={{ scale: 1.02, boxShadow: "0 8px 30px rgba(0,0,0,0.12)" }}
      whileTap={{ scale: 0.98 }}
      style={{ x, rotateY, filter: useTransform(brightness, (v) => `brightness(${v})`) }}
      drag="x"
      dragConstraints={{ left: 0, right: 0 }}
      dragElastic={0.1}
      transition={{ layout: { type: "spring", visualDuration: 0.4, bounce: 0.1 } }}
    >
      <motion.h3 layout="position">{title}</motion.h3>

      <motion.div style={{ display: "flex", gap: 12 }}>
        {stats.map((stat, i) => (
          <motion.span
            key={stat.label}
            initial={{ opacity: 0, scale: 0.5 }}
            animate={{ opacity: 1, scale: 1 }}
            transition={{ delay: i * 0.05, type: "spring", stiffness: 300 }}
          >
            {stat.value}
          </motion.span>
        ))}
      </motion.div>

      <AnimatePresence>
        {isExpanded && (
          <motion.div
            key="content"
            variants={contentVariants}
            initial="collapsed"
            animate="expanded"
            exit="collapsed"
          >
            {children}
          </motion.div>
        )}
      </AnimatePresence>
    </motion.div>
  )
}
```

### Complete Example: react-motion (Legacy Spring)

```tsx
import { Motion, StaggeredMotion, spring, presets } from "react-motion"

// Simple spring toggle
function SpringToggle({ isOpen }: { isOpen: boolean }) {
  return (
    <Motion
      defaultStyle={{ height: 0, opacity: 0 }}
      style={{
        height: spring(isOpen ? 200 : 0, presets.gentle),
        opacity: spring(isOpen ? 1 : 0),
      }}
    >
      {({ height, opacity }) => (
        <div style={{ height, opacity, overflow: "hidden" }}>
          Collapsible content
        </div>
      )}
    </Motion>
  )
}

// Chain-follow effect
function ChainDots({ mouseX, mouseY }: { mouseX: number; mouseY: number }) {
  return (
    <StaggeredMotion
      defaultStyles={Array(6).fill({ x: 0, y: 0 })}
      styles={(prev) =>
        prev.map((_, i) =>
          i === 0
            ? { x: spring(mouseX, presets.stiff), y: spring(mouseY, presets.stiff) }
            : { x: spring(prev[i - 1].x, presets.wobbly), y: spring(prev[i - 1].y, presets.wobbly) }
        )
      }
    >
      {(styles) => (
        <>
          {styles.map((style, i) => (
            <div
              key={i}
              style={{
                position: "absolute",
                width: 30 - i * 4,
                height: 30 - i * 4,
                borderRadius: "50%",
                background: `hsl(${i * 50}, 80%, 60%)`,
                transform: `translate(${style.x}px, ${style.y}px)`,
              }}
            />
          ))}
        </>
      )}
    </StaggeredMotion>
  )
}
```

---

## Rules

- Always use `useGSAP()` from `@gsap/react` instead of `useEffect` + manual cleanup for GSAP animations in React
- Always register GSAP plugins at the module level: `gsap.registerPlugin(ScrollTrigger)` — never inside components
- Never animate React state with GSAP — animate DOM refs; use `gsap.to(".selector", ...)` scoped to a container ref
- For Motion, always provide a `key` prop on direct children of `AnimatePresence`
- Never call `motion.create()` inside a render function — define wrapped components at module level
- Prefer GPU-accelerated properties (`transform`, `opacity`, `filter`) over layout-triggering ones (`width`, `height`, `top`, `left`)
- Use `will-change` sparingly and remove it after animation completes — permanent `will-change` wastes GPU memory
- For SSR/RSC with Motion, import from `"motion/react-client"` to avoid "use client" boundary issues
- Use `motion/react-mini` (~5kb) when only basic animations are needed — full bundle is ~32kb
- Always support `prefers-reduced-motion`: use `gsap.matchMedia()` or `<MotionConfig reducedMotion="user">`
- react-motion is legacy (last updated 2017) — use only for maintenance of existing code; prefer Motion for new projects
- When both GSAP and Motion coexist, keep clear per-component boundaries: GSAP for timelines/scroll, Motion for declarative UI
- Scope all GSAP selectors to a container ref — never use global document selectors in React components
