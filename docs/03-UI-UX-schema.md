# 03 — UI/UX Schema
> Rubik's Cube Learning App · v1.0 · Last updated: 2026-10-02

---

## 1. Design Principles

| Principle | Application |
|-----------|-------------|
| **Beginner-first** | Every screen assumes zero cubing knowledge. Labels use plain English, not notation, wherever possible. |
| **One action per screen** | Each screen has a single primary CTA. No cognitive overload. |
| **Duolingo-like warmth** | Bright, high-contrast colors. Rounded corners. Friendly typography. Celebratory stage-complete moments. |
| **Progressive disclosure** | Technical details (algorithm notation) are secondary to the visual 3D instruction. |

---

## 2. Design Tokens

### Colors

| Token | Hex | Usage |
|-------|-----|-------|
| `--color-primary` | `#4F46E5` | Primary CTA buttons, active stage indicator |
| `--color-primary-light` | `#818CF8` | Hover states, highlights |
| `--color-bg` | `#F9FAFB` | App background |
| `--color-surface` | `#FFFFFF` | Cards, bottom sheets |
| `--color-text-primary` | `#111827` | Headings, body |
| `--color-text-secondary` | `#6B7280` | Subtitles, helper text |
| `--color-success` | `#10B981` | Stage complete, correct detection |
| `--color-warning` | `#F59E0B` | Validation warning (cube not ready for stage) |
| `--color-error` | `#EF4444` | Invalid cube state |

### Cube Face Colors (exact, not remappable)

| Face | Hex |
|------|-----|
| White | `#FFFFFF` |
| Yellow | `#FDE047` |
| Green | `#22C55E` |
| Blue | `#3B82F6` |
| Red | `#EF4444` |
| Orange | `#F97316` |

### Typography

| Token | Value | Usage |
|-------|-------|-------|
| `font-family` | `Inter` (Google Fonts) | All text |
| `text-h1` | 28sp, Bold | Screen titles |
| `text-h2` | 20sp, SemiBold | Section headings |
| `text-body` | 16sp, Regular | Instruction text |
| `text-caption` | 13sp, Regular | Helper text, labels |
| `text-mono` | `Roboto Mono`, 14sp | Algorithm notation (R U Ri U ...) |

### Spacing & Shape

| Token | Value |
|-------|-------|
| Base unit | 8dp |
| Card radius | 16dp |
| Button radius | 12dp |
| Primary button height | 52dp |

---

## 3. Information Architecture / Sitemap

```
App Launch
    │
    ├── Home Screen
    │       │
    │       ├── [New Session] ──────► Scan Flow
    │       │                              │
    │       │                         Face Scan (×6)
    │       │                              │
    │       │                         Correction Screen
    │       │                              │
    │       │                         Validation + Stage Detection
    │       │                              │
    │       │                         Stage Selector ◄─────────────┐
    │       │                              │                        │
    │       │                         Teaching Screen              │
    │       │                              │                        │
    │       │                         Stage Complete ──────────────┘
    │       │                              │
    │       │                         [All Done] ──► Solved Screen
    │       │
    │       └── [Continue] ────────► Teaching Screen (restored state)
    │
    └── (no other top-level routes in v1)
```

---

## 4. Screen Inventory & Wireframe Descriptions

---

### Screen 1: Home Screen

**Purpose:** Entry point. Minimal. Two paths: new session or continue.

```
┌────────────────────────────────┐
│  ≡  (no nav needed in v1)      │
│                                │
│        🟦🟥🟩                  │  ← Small decorative 3D cube (static/spinning)
│   Rubik's Cube Teacher         │  ← h1
│   Learn to solve, step by step │  ← subtitle, text-secondary
│                                │
│  ┌──────────────────────────┐  │
│  │    Start New Session     │  │  ← primary button
│  └──────────────────────────┘  │
│                                │
│  ┌──────────────────────────┐  │  ← only shown if saved session exists
│  │  Continue Where I Left Off│ │  ← secondary/outlined button
│  └──────────────────────────┘  │
│                                │
│  Stage 3 of 7 · Middle Edges   │  ← caption, shown below continue button
└────────────────────────────────┘
```

**Interactions:**
- "Start New Session" → if saved session exists, show confirmation dialog ("Discard previous progress?") → Face Scan (Face 1)
- "Continue" → Teaching Screen (restored state)

---

### Screen 2: Face Scan Screen

**Purpose:** Capture one face at a time. Repeated 6 times.

```
┌────────────────────────────────┐
│  ←   Scan Your Cube            │  ← back arrow + h1
│      Face 2 of 6: Right Face   │  ← caption (face name, not U/R/F)
│  ████████████████████████████  │  ← progress bar (2/6 filled)
│                                │
│  ┌──────────────────────────┐  │
│  │                          │  │
│  │     [CAMERA PREVIEW]     │  │  ← live camera feed
│  │                          │  │
│  │   ┌──┬──┬──┐             │  │
│  │   │  │  │  │             │  │  ← 3×3 grid overlay (semi-transparent)
│  │   ├──┼──┼──┤             │  │
│  │   │  │  │  │             │  │
│  │   ├──┼──┼──┤             │  │
│  │   │  │  │  │             │  │
│  │   └──┴──┴──┘             │  │
│  │                          │  │
│  └──────────────────────────┘  │
│                                │
│  Hold the RIGHT face toward    │  ← helper instruction (plain English)
│  the camera and align it to    │
│  the grid.                     │
│                                │
│  ┌──────────────────────────┐  │
│  │        Capture           │  │  ← primary button
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

**Scan order (internal, shown as plain names to user):**
Top → Right → Front → Bottom → Left → Back

**Interactions:**
- "Capture" → freezes frame, extracts colors, navigates to Correction Screen for this face
- Back arrow → returns to previous face (or Home if face 1)

---

### Screen 3: Correction Screen

**Purpose:** Let the user verify and fix detected sticker colors before committing a face.

```
┌────────────────────────────────┐
│  ←   Check the Colors          │
│      Face 2 of 6: Right Face   │
│                                │
│   Tap any sticker to change    │  ← helper text
│   its color.                   │
│                                │
│        ┌───┬───┬───┐           │
│        │ 🟥│ 🟥│ 🟥│           │  ← 3×3 tappable grid
│        ├───┼───┼───┤           │
│        │ 🟧│ 🟥│ 🟥│           │  ← center cell visually distinct (it's fixed)
│        ├───┼───┼───┤           │
│        │ 🟥│ 🟥│ 🟥│           │
│        └───┴───┴───┘           │
│                                │
│  ┌──────────────────────────┐  │
│  │     Looks Good →         │  │  ← primary button
│  └──────────────────────────┘  │
│                                │
│       Re-scan this face        │  ← text link
└────────────────────────────────┘
```

**Color picker (bottom sheet, appears on cell tap):**
```
┌──────────────────────────────┐
│  Choose a color              │
│                              │
│   ⬜ White   🟨 Yellow       │
│   🟩 Green   🟦 Blue         │
│   🟥 Red     🟧 Orange       │
└──────────────────────────────┘
```

**Interactions:**
- Tap sticker → color picker bottom sheet
- Tap color → updates cell, sheet closes
- "Looks Good" → if last face, go to Validation; else go to Scan Screen (next face)
- "Re-scan this face" → back to Face Scan for same face number

---

### Screen 4: Stage Selector Screen

**Purpose:** Show detected stage, let user confirm or override.

```
┌────────────────────────────────┐
│  ←   Where Are You?            │
│                                │
│  We think you're on:           │  ← text-secondary
│  ┌──────────────────────────┐  │
│  │  Stage 3: Middle Edges   │  │  ← detected stage, card style, success color
│  │  Your first two layers   │  │
│  │  look complete!          │  │
│  └──────────────────────────┘  │
│                                │
│  Or choose a different stage:  │  ← text-secondary
│                                │
│  ✅  Stage 1: White Cross      │  ← checkmark = complete
│  ✅  Stage 2: White Corners    │
│  ▶   Stage 3: Middle Edges     │  ← arrow = current/selected
│      Stage 4: Yellow Cross     │
│      Stage 5: Orient Corners   │
│      Stage 6: Permute Corners  │
│      Stage 7: Permute Edges    │
│                                │
│  ┌──────────────────────────┐  │
│  │   Start Teaching →       │  │  ← primary button
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

**Warning state (if selected stage doesn't match cube state):**
```
⚠️ Your cube doesn't look ready for Stage 5 yet.
   You can still proceed, but the instructions
   may not match your cube.        [Proceed anyway]
```

---

### Screen 5: Teaching Screen

**Purpose:** Core screen. Step-by-step animated instructions.

```
┌────────────────────────────────┐
│  ←   Stage 3: Middle Edges     │  ← stage name
│  ████████████░░░░░░░░░░░░░░░░  │  ← step progress within stage
│                                │
│  ┌──────────────────────────┐  │
│  │                          │  │
│  │    [3D CUBE RENDER]      │  │  ← animated 3D cube (drag to rotate)
│  │                          │  │
│  │         ← drag to rotate │  │
│  └──────────────────────────┘  │
│                                │
│  Step 2 of 8                   │  ← caption
│  ┌──────────────────────────┐  │
│  │ Find the green-red edge  │  │
│  │ piece on the top layer.  │  │
│  │ It should be here ↑      │  │  ← instruction text (body)
│  └──────────────────────────┘  │
│                                │
│  Move:  U  R  Ui  Ri           │  ← algorithm notation (monospace)
│         Ui  Fi  U  F           │
│                                │
│  ┌───────┐    ┌─────────────┐  │
│  │  ← Back│   │  Next Step →│  │
│  └───────┘    └─────────────┘  │
│                                │
│  ┌──────────────────────────┐  │
│  │  Re-scan cube            │  │  ← secondary action (text button)
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

**7-stage progress indicator (persistent, collapsible):**
- Shown as a horizontal row of 7 numbered dots at the top of the screen
- Completed stages: filled circle (success color)
- Current stage: pulsing filled circle (primary color)
- Future stages: empty circle (border only)

---

### Screen 6: Stage Complete Screen

**Purpose:** Celebrate finishing a stage. Clear CTA to continue.

```
┌────────────────────────────────┐
│                                │
│          🎉                    │  ← large emoji / confetti animation
│                                │
│    Stage 3 Complete!           │  ← h1
│    Middle Edges Solved         │  ← h2, text-secondary
│                                │
│  ┌──────────────────────────┐  │
│  │  Continue to Stage 4 →   │  │  ← primary button
│  └──────────────────────────┘  │
│                                │
│    Re-scan to verify           │  ← optional secondary action
│    before continuing           │
└────────────────────────────────┘
```

---

### Screen 7: Solved Screen

**Purpose:** Full cube solved. Session end.

```
┌────────────────────────────────┐
│                                │
│       🏆                       │
│   Cube Solved!                 │  ← h1
│   You did it. All 7 stages.    │  ← body
│                                │
│   [Animated solved 3D cube]    │
│                                │
│  ┌──────────────────────────┐  │
│  │    Start a New Solve     │  │  ← primary button → Home
│  └──────────────────────────┘  │
└────────────────────────────────┘
```

---

## 5. Component Inventory

| Component | Type | Description |
|-----------|------|-------------|
| `PrimaryButton` | Button | Full-width, 52dp, `--color-primary`, rounded 12dp |
| `SecondaryButton` | Button | Outlined, full-width, same size |
| `TextButton` | Button | No background, used for de-emphasized actions |
| `FaceGrid` | Widget | 3×3 tappable sticker grid (correction screen) |
| `ColorPickerSheet` | Bottom Sheet | 6-color picker, appears on sticker tap |
| `StageListTile` | List Item | Stage name + status icon (check / arrow / empty) |
| `StageProgressDots` | Indicator | 7 horizontal dots, current/complete/future states |
| `StepProgressBar` | Indicator | Thin linear bar showing step N of M within a stage |
| `CubeRenderer` | Custom Widget | 3D cube via `CustomPainter`; accepts facelet state + animated move |
| `ScanOverlay` | Widget | 3×3 grid overlay drawn over camera preview |
| `ConfirmDialog` | Dialog | "Discard progress?" confirmation, two actions |
| `StageWarningBanner` | Banner | Inline warning when stage mismatch detected |

---

## 6. Responsive & Accessibility Notes

- **Layout:** Single-column, vertically scrollable. Minimum target device: 360dp wide screen.
- **3D cube area:** Fixed aspect ratio (1:1), sized to 60% of screen width max, centered.
- **Semantics:** All `FaceGrid` cells have semantic labels like `"Top-left sticker: Red"`. `CubeRenderer` has a semantic label describing current cube state.
- **Contrast:** All text meets WCAG AA (4.5:1 minimum) on both light backgrounds and cube face colors.
- **No horizontal scrolling** anywhere in the app.
- **Bottom safe area** respected on iPhone (notch/home bar padding via `SafeArea`).
