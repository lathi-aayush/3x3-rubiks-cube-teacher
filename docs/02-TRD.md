# 02 — Technical Requirements Document (TRD)
> Rubik's Cube Learning App · v1.0 · Last updated: 2026-10-02
> Revision 2: incorporates architecture review feedback.

---

## 1. Chosen Stack & Justification

| Layer | Choice | Justification |
|-------|--------|---------------|
| **Framework** | Flutter (Dart) | Single codebase for iOS + Android; strong camera plugin ecosystem; `CustomPainter` gives full control over 3D rendering |
| **Camera / CV** | `camera` plugin + `image` package + custom LAB classifier | `camera` gives raw frame access; pure-Dart LAB classification avoids native binding complexity for MVP. `opencv_dart` noted as a candidate but maintenance status is unverified — do not plan around it. |
| **3D Visualization** | Custom `CustomPainter` renderer (primary); `three_js` (evaluate as alternative) | `flutter_cube` reversed: it is an `.obj` viewer with no puzzle-layer concept, latest version is 0.1.x, one fork is archived, and the README itself points to `three_js`. A `CustomPainter` renderer is the reliable primary plan. |
| **State Management** | `provider` | Lightweight, well-documented, appropriate for solo dev on a 2-week timeline |
| **Local Persistence** | `shared_preferences` | Key-value store; sufficient for saving cube state (54 ints) + stage + step index |
| **Navigation** | `go_router` | Declarative routing; clean structure |
| **Isolate** | Dart `Isolate` / `compute()` | Solver runs off the UI thread to prevent jank during BFS or procedure execution |

---

## 2. Architecture Overview

```
┌─────────────────────────────────────────────────────────┐
│                        Flutter App                       │
│                                                         │
│  ┌──────────┐   ┌──────────────┐   ┌─────────────────┐ │
│  │   UI     │   │    Logic     │   │     Data        │ │
│  │ Screens  │◄──│  Providers   │◄──│  Repositories   │ │
│  │ Widgets  │   │  (Provider)  │   │  LocalStorage   │ │
│  └──────────┘   └──────────────┘   └─────────────────┘ │
│        │               │                                 │
│        │       ┌───────┴──────────────────────────┐     │
│        │       │          Domain / Lib             │     │
│        │       │  ┌──────────┐  ┌──────────────┐  │     │
│        │       │  │FaceletModel  │PieceView    │  │     │
│        │       │  │(54-int[])│  │(read-only    │  │     │
│        │       │  │          │  │ derived from │  │     │
│        │       │  │          │  │ facelet arr) │  │     │
│        │       │  └──────────┘  └──────────────┘  │     │
│        │       │  ┌──────────┐  ┌──────────────┐  │     │
│        │       │  │Validator │  │StagedSolver  │  │     │
│        │       │  │          │  │(runs in      │  │     │
│        │       │  │          │  │ isolate)     │  │     │
│        │       │  └──────────┘  └──────────────┘  │     │
│        │       │  ┌──────────┐                     │     │
│        │       │  │LABColor  │                     │     │
│        │       │  │Classifier│                     │     │
│        │       │  └──────────┘                     │     │
│        │       └──────────────────────────────────┘     │
│        │                                                 │
│  ┌─────▼──────┐                                         │
│  │  Plugins   │                                         │
│  │  camera    │                                         │
│  │  image     │                                         │
│  └────────────┘                                         │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

| Layer | Responsibility |
|-------|---------------|
| **UI (screens, widgets)** | Render only. Reads from providers, fires events. Zero business logic. |
| **Logic (providers)** | App state, orchestration (scan flow, stage transitions, step progression). |
| **Domain / Lib** | Pure Dart. No Flutter imports. Fully unit-testable. See §3–5. |
| **Data (repositories)** | Read/write `shared_preferences`. Serialize/deserialize cube state. |
| **Plugins** | Camera access, image processing — all wrapped behind interfaces. |

---

## 3. Cube Representation

### 3a. Facelet Model — Source of Truth

A fixed-size array of 54 integers, one per sticker, indexed as:

```
Face order:  U(0–8), R(9–17), F(18–26), D(27–35), L(36–44), B(45–53)
Color codes: W=0, Y=1, G=2, B=3, R=4, O=5
Index layout within each face (read left-to-right, top-to-bottom):
  0 1 2
  3 4 5
  6 7 8
Center of each face is always index 4 of that face's block.
```

Each move is a fixed permutation on this array, stored as a lookup table of 54-element index mappings.

### 3b. Piece View — Read-Only, Derived

A small, pure function `PieceView.from(int[] facelets)` extracts:
- **8 corners** — each as `{position, orientation}` (0–7, 0–2)
- **12 edges** — each as `{position, orientation}` (0–11, 0–1)

This is **not a second model to maintain**. It is a read-only derivation used only by:
1. `Validator.isLegal()` — corner twist, edge flip, and parity checks
2. `StageDetector.completedStage()` — stage conditions are cleaner on pieces than on 54 stickers (e.g. "all four white edges placed with matching side colors")

---

## 4. Color Detection Pipeline (Pure Dart, LAB)

```
Camera frame (CameraImage, YUV420)
        │
        ▼
Convert to RGB bitmap (image package)
        │
        ▼
Scan all 6 faces first (collect all 54 patches before classifying)
        │
        ▼
Sample 9 patches per face (center 20% of each cell)
Average RGB per patch → convert to CIELAB
        │
        ▼
Use the 6 center stickers (one per face, known positions) as
reference LAB values for W, Y, G, B, R, O
        │
        ▼
Nearest-neighbour match of each of 54 patches to the 6 reference LABs
        │
        ▼
Manual correction screen (full 54-sticker grid, user taps to override)
        │
        ▼
Validation (9 per color, legal cubie check via PieceView)
```

**Why LAB over HSV:**
- CIELAB is perceptually uniform — distance in LAB correlates to human color difference
- More robust to the orange/red and white/yellow confusions that plague HSV classifiers
- Scanning all 6 faces before classifying lets center stickers serve as per-session calibration references, compensating for lighting conditions

**Measurable G1 target (added from review):**
> ≥ 90% of face scans require zero manual corrections under normal indoor lighting.

**`opencv_dart` note:** Unverified maintenance status — do not plan around it. If pure-Dart LAB classification underperforms, the correction path is improving the LAB reference sampling algorithm, not swapping libraries.

---

## 5. Staged Solver

### 5a. Design Principles

- Uses **beginner layer-by-layer terminology** throughout (no OLL/PLL — those are CFOP terms; CFOP is a non-goal)
- Output is a sequence of steps a human can follow, not an optimal move count
- Each stage's procedure is **explainable**: it locates a piece, moves it to a staging position, and applies a fixed trigger — the user can follow the logic, not just the moves
- Each stage must produce a correct result starting from **any state where earlier stages are complete** (including partial progress within the current stage)

### 5b. The 7 Stages

| # | Name | Approach |
|---|------|----------|
| 1 | **White Cross** | BFS over a reduced state (4 cross edges only, restricted move set). Output is human-legible and can be annotated with intent ("bring this edge up"). |
| 2 | **White Corners** | Procedural: locate each white corner, move it below its target slot, apply the right-hand or left-hand insert trigger (case on orientation). Repeat for each of 4 corners. |
| 3 | **Middle Layer Edges** | Procedural: locate each middle edge on the top layer, align it, apply the U→R or U→L insert algorithm. If edge is in the middle layer but wrongly placed, extract first. |
| 4 | **Yellow Cross** | Case lookup: 4 OLL-edge cases (dot, L-shape, bar, cross). Apply the cross algorithm until cross is formed. |
| 5 | **Orient Yellow Corners** | Procedural: hold unsolved corner in front-right-top position, apply sune trigger until it orients, rotate U, repeat. |
| 6 | **Permute Yellow Corners** | Case lookup: find a correctly positioned corner (or apply setup move), apply A-perm algorithm. |
| 7 | **Permute Yellow Edges** | Case lookup: identify cycle (3-cycle left, 3-cycle right, or adjacent swap), apply U-perm algorithm. |

### 5c. Solver Execution

```dart
// Runs in a Dart isolate via compute()
List<Step> solve(CubeState state, Stage fromStage);

// Step = { description: String, notation: String, moveSequence: List<Move> }
// Move = enum { R, Ri, L, Li, U, Ui, D, Di, F, Fi, B, Bi }
```

Applying a move mutates a copy of the facelet array using its permutation table. The solver never mutates in place — all functions are pure.

---

## 6. 3D Cube Renderer

### Primary Plan: Custom `CustomPainter`

A `CustomPainter`-based renderer is the primary plan. `flutter_cube` is reversed (see §1 justification).

Required capabilities:
- **27 cubies**, each with a 4×4 transform matrix
- **Layer rotation**: rotate a set of 9 cubies around an axis with animation
- **Perspective projection** + painter's-algorithm **depth sorting**
- **Piece highlighting**: colour a target cubie's face differently — pulled forward from v1.1 because it directly supports G5 (beginner clarity)
- **Drag-to-rotate**: orbit the whole cube via gesture

### Alternative to Evaluate: `three_js`
The archived `flutter_cube` fork's own README points to `three_js` as its successor. Evaluate it at project setup. If it handles puzzle-layer transforms well, use it and remove the custom painter work. Decision to be made in implementation Phase 1.

---

## 7. Stage Detection

```dart
Stage detectStage(int[] facelets) {
  // Check completion conditions in order 7 → 1
  // Return the first incomplete stage found
  // Uses PieceView for corner/edge position+orientation checks
}
```

**Test requirement:** For every stage boundary (0 through 7), generate a representative cube state and assert `detectStage()` returns the correct stage. This is part of the test harness (§9).

---

## 8. Non-Functional Requirements

### Performance
- Camera frame processing: < 200 ms per face capture
- Solver (isolate): < 500 ms for any stage; UI stays responsive during solve
- 3D animation: 60 fps target on devices with 2 GB+ RAM

### Security
- No network calls in v1 — zero attack surface
- No PII stored

### Accessibility
- Text contrast ratio ≥ 4.5:1 (WCAG AA)
- All interactive elements have `Semantics` labels
- Font size respects system text scale factor

### Reliability
- Validator gates all solver inputs — no illegal state ever reaches the solver
- All domain functions are pure (no side effects) — safe to retry

---

## 9. Test Harness (Required)

Two categories of tests, written alongside implementation:

| Test type | What it checks |
|-----------|---------------|
| **Stage boundary detection** | For each of the 8 states (unsolved, cross done, …, solved), assert `detectStage()` returns the right stage. |
| **Solver correctness** | Generate N random scrambles; for each, run `solve()` for all remaining stages in sequence; assert the result is fully solved. |

Tests live in `test/` as plain Dart unit tests (no framework needed). Run with `flutter test`.

---

## 10. Third-Party Packages

| Package | Purpose | Licence |
|---------|---------|---------|
| `camera` | Camera feed access | BSD |
| `image` | YUV→RGB + pixel sampling | MIT |
| `provider` | State management | MIT |
| `go_router` | Navigation / routing | BSD |
| `shared_preferences` | Local key-value persistence | BSD |
| `permission_handler` | Camera permission request | MIT |
| `three_js` (TBD) | 3D rendering (evaluate at setup) | MIT |

---

## 11. Environment Strategy

| Environment | Description |
|-------------|-------------|
| **Dev** | `flutter run` on physical device or emulator. Debug mode. Hot reload enabled. |
| **Release (local)** | `flutter run --release` for performance testing before demo. |
| **Prod** | Out of scope for v1. |

No `.env` files, no secrets, no CI/CD required for v1.
