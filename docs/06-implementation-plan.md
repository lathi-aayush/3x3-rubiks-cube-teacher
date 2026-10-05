# 06 — Implementation Plan
> Rubik's Cube Learning App · v1.0 · Last updated: 2026-10-02
> Timeline: 2 weeks, solo developer.

---

## 1. Guiding Principles

- **Domain first, UI second.** The cube model and solver are pure Dart — build and test them before touching Flutter widgets.
- **No phase is started until the previous one's "done" criteria are met.**
- **No feature outside the PRD MVP list** is built without flagging it first.
- **Each phase ends with a working, runnable app** — no half-built states left overnight.

---

## 2. Project Folder Structure

```
rubiks_cube_teacher/
├── lib/
│   ├── main.dart                      # App entry point, router setup
│   │
│   ├── domain/                        # Pure Dart — zero Flutter imports
│   │   ├── models/
│   │   │   ├── cube_color.dart        # CubeColor enum
│   │   │   ├── move.dart              # Move enum + permutation tables
│   │   │   ├── stage.dart             # Stage enum + metadata
│   │   │   ├── step.dart              # Step class
│   │   │   └── session.dart           # Session class + JSON serialization
│   │   ├── cube/
│   │   │   ├── facelets.dart          # Facelets typedef + helpers
│   │   │   ├── piece_view.dart        # PieceView derived from facelets
│   │   │   ├── move_applier.dart      # MoveApplier (pure, permutation tables)
│   │   │   └── cube_validator.dart    # CubeValidator + ValidationError
│   │   ├── detection/
│   │   │   ├── stage_detector.dart    # StageDetector
│   │   │   └── color_classifier.dart  # ColorClassifier (LAB nearest-neighbor)
│   │   └── solver/
│   │       ├── staged_solver.dart     # StagedSolver (isolate entry point)
│   │       ├── cross_solver.dart      # Stage 1: BFS
│   │       ├── corner_solver.dart     # Stage 2: procedural
│   │       ├── edge_solver.dart       # Stage 3: procedural
│   │       └── last_layer_solver.dart # Stages 4–7: case lookup
│   │
│   ├── data/
│   │   └── session_repository.dart    # Load/save Session via shared_preferences
│   │
│   ├── providers/
│   │   ├── session_provider.dart      # Session state (current stage, step)
│   │   ├── scan_provider.dart         # Scan flow state (face index, detected colors)
│   │   └── teaching_provider.dart     # Teaching flow state (steps, animations)
│   │
│   ├── ui/
│   │   ├── app.dart                   # MaterialApp + go_router config
│   │   ├── screens/
│   │   │   ├── home_screen.dart
│   │   │   ├── scan_screen.dart
│   │   │   ├── correction_screen.dart
│   │   │   ├── stage_selector_screen.dart
│   │   │   ├── teaching_screen.dart
│   │   │   ├── stage_complete_screen.dart
│   │   │   └── solved_screen.dart
│   │   ├── widgets/
│   │   │   ├── cube_renderer/
│   │   │   │   ├── cube_renderer.dart       # CustomPainter 3D cube widget
│   │   │   │   ├── cube_geometry.dart       # 27 cubie transforms, projection
│   │   │   │   └── cube_animator.dart       # Layer rotation animation controller
│   │   │   ├── face_grid.dart               # 3×3 tappable sticker grid
│   │   │   ├── color_picker_sheet.dart      # Bottom sheet: 6 colors
│   │   │   ├── scan_overlay.dart            # 3×3 grid over camera preview
│   │   │   ├── stage_progress_dots.dart     # 7-dot stage indicator
│   │   │   ├── step_progress_bar.dart       # Linear step progress
│   │   │   └── stage_list_tile.dart         # Row in stage selector list
│   │   └── theme/
│   │       └── app_theme.dart               # ThemeData, colors, typography
│   │
│   └── utils/
│       ├── image_converter.dart       # YUV420 → RGB (wraps image package)
│       ├── patch_sampler.dart         # Sample 9 patches from an RGB face image
│       └── lab_color.dart             # LabColor class + RGB↔LAB conversion
│
├── test/
│   ├── domain/
│   │   ├── cube_validator_test.dart
│   │   ├── move_applier_test.dart
│   │   ├── piece_view_test.dart
│   │   ├── stage_detector_test.dart
│   │   └── staged_solver_test.dart    # Scramble → solve correctness
│   └── utils/
│       └── color_classifier_test.dart
│
├── project_details/
│   └── Rubiks_Cube_Learning_App.docx  # Original design reference (keep)
│
├── docs/                              # All 6 planning documents
│   ├── 01-PRD.md
│   ├── 02-TRD.md
│   ├── 03-UI-UX-schema.md
│   ├── 04-app-flow.md
│   ├── 05-backend-schema.md
│   └── 06-implementation-plan.md
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 3. Phased Build Plan

---

### Phase 1 — Domain Core (Days 1–3)
> **Goal:** All cube logic works and is tested. No Flutter, no UI.

**Build order:**

1. `pubspec.yaml` — scaffold Flutter project, add all dependencies
2. `domain/models/` — `CubeColor`, `Move` (with permutation tables), `Stage`, `Step`, `Session`
3. `domain/cube/facelets.dart` — helpers (solved state constant, copy utility)
4. `domain/cube/move_applier.dart` — apply single move and sequence; pure
5. `domain/cube/piece_view.dart` — derive corners + edges from facelet array
6. `domain/cube/cube_validator.dart` — all 4 validation checks
7. `domain/detection/stage_detector.dart` — 7 stage completion conditions
8. `domain/solver/` — all 4 solver files (cross BFS, corner procedural, edge procedural, last-layer lookup)
9. `test/domain/` — write tests alongside each file above

**Done criteria:**
- [ ] `flutter test` passes with zero failures
- [ ] Solver test: 20 random scrambles, each solved correctly through all 7 stages
- [ ] Stage detector test: all 8 boundary states (0 stages done → all done) detected correctly
- [ ] Validator test: known-illegal states (twisted corner, flipped edge, parity) all rejected

---

### Phase 2 — Color Detection Pipeline (Days 3–4)
> **Goal:** Can classify sticker colors from a camera image in a test harness.

**Build order:**

1. `utils/lab_color.dart` — `LabColor` class, RGB→LAB conversion
2. `utils/image_converter.dart` — YUV420 → RGB bitmap (wraps `image` package)
3. `utils/patch_sampler.dart` — sample 9 center patches from a face-sized bitmap
4. `domain/detection/color_classifier.dart` — `ColorClassifier.fromCenters()` + `classify()`
5. `test/utils/color_classifier_test.dart` — unit test with synthetic LAB values for each color

**Done criteria:**
- [ ] Classifier correctly identifies all 6 colors from synthetic LAB inputs
- [ ] `flutter test` still passing

---

### Phase 3 — Data Layer & State (Day 4)
> **Goal:** Session can be saved, loaded, and managed in providers.

**Build order:**

1. `data/session_repository.dart` — `save()`, `load()`, `delete()` via `shared_preferences`
2. `providers/session_provider.dart` — holds `Session?`, exposes `load`, `save`, `discard`
3. `providers/scan_provider.dart` — holds per-face scan state, assembled facelets, detected stage
4. `providers/teaching_provider.dart` — holds current steps list, step index, animates moves

**Done criteria:**
- [ ] Session round-trips correctly through JSON serialization
- [ ] Providers compile and expose the right state shapes
- [ ] `MultiProvider` wired in `main.dart`

---

### Phase 4 — Navigation & Shell (Day 5)
> **Goal:** All 7 screens exist as stubs; navigation between them works.

**Build order:**

1. `ui/theme/app_theme.dart` — `ThemeData` with all design tokens from `03-UI-UX-schema.md`
2. `ui/app.dart` — `MaterialApp.router` with `go_router` routes for all 7 screens
3. All 7 screen files — stub `Scaffold` with route name as title text
4. `main.dart` — `runApp`, `MultiProvider`, `app.dart`

**Done criteria:**
- [ ] `flutter run` launches without error
- [ ] All 7 routes navigable by tapping placeholder buttons
- [ ] Theme colors, fonts, and border radii are visible on all screens

---

### Phase 5 — Scan & Correction UI (Days 5–7)
> **Goal:** User can scan all 6 faces and correct colors. Result is a committed 54-int array.

**Build order:**

1. `widgets/scan_overlay.dart` — 3×3 grid overlay drawn over camera preview
2. `screens/scan_screen.dart` — camera feed + overlay + face progress + Capture button
3. `widgets/face_grid.dart` — 3×3 tappable grid (displays detected colors)
4. `widgets/color_picker_sheet.dart` — bottom sheet with 6 color options
5. `screens/correction_screen.dart` — face grid + color picker integration + "Looks Good" / "Re-scan"
6. Wire `scan_provider` to both screens
7. After face 6 confirmed: run `CubeValidator`, show error or proceed to Stage Selector

**Done criteria:**
- [ ] Full 6-face scan loop completes without crash
- [ ] Colors can be corrected on every face
- [ ] Committed facelets are validated; invalid states show error with corrective message
- [ ] Center cells are non-tappable

---

### Phase 6 — 3D Cube Renderer (Days 6–8)
> **Goal:** `CubeRenderer` widget renders the correct cube state and animates a single move.
> This phase runs in parallel with Phase 5 where possible.

**Evaluate first (Day 6, 2-hour timebox):**
- Try `three_js` package: does it support per-layer rotation and per-face coloring?
- If yes: use it and skip custom painter work.
- If no (or unclear docs/maintenance): proceed with `CustomPainter`.

**Build order (CustomPainter path):**

1. `widgets/cube_renderer/cube_geometry.dart`
   - 27 cubie positions in 3D space
   - 4×4 transform matrices per cubie
   - Perspective projection function
   - Painter's-algorithm depth sorting
2. `widgets/cube_renderer/cube_animator.dart`
   - `AnimationController`-driven layer rotation (9 cubies around an axis)
   - Smooth 300ms ease-in-out
3. `widgets/cube_renderer/cube_renderer.dart`
   - `CustomPainter` that uses geometry + animator
   - Drag gesture for orbit rotation
   - Piece highlighting: target cubies rendered with a bright border

**Done criteria:**
- [ ] Solved cube renders correctly (all 6 faces correct colors)
- [ ] Applying R move animates the right layer rotating clockwise
- [ ] Orbit drag rotates the whole cube
- [ ] A highlighted cubie is visually distinct
- [ ] 60 fps on a mid-range test device

---

### Phase 7 — Stage Selector & Teaching UI (Days 8–10)
> **Goal:** Full teaching flow works end-to-end with real solver output.

**Build order:**

1. `widgets/stage_progress_dots.dart` — 7-dot indicator
2. `widgets/stage_list_tile.dart` — stage row with status icon
3. `screens/stage_selector_screen.dart` — auto-detected stage highlighted, all stages listable, warning banner, "Start Teaching" CTA
4. `widgets/step_progress_bar.dart` — linear bar, N of M steps
5. `screens/teaching_screen.dart`
   - Consumes `teaching_provider` steps
   - Renders `CubeRenderer` with current state
   - Shows instruction text + notation
   - Next/Back buttons (Next locked during animation)
   - Re-scan button
6. `screens/stage_complete_screen.dart` — confetti/emoji, Continue CTA
7. `screens/solved_screen.dart` — trophy, solved 3D cube, New Solve CTA
8. Wire `StagedSolver.solve()` via `compute()` in `teaching_provider`

**Done criteria:**
- [ ] Full flow: scan → detect → select stage → step through → stage complete → next stage → solved
- [ ] Next button locked during animation, unlocked after
- [ ] Back at step 1 goes to Stage Selector
- [ ] Re-scan mid-session works (state preserved and restored)
- [ ] Progress persisted to `shared_preferences` after every step

---

### Phase 8 — Home Screen & Session Resume (Day 10)
> **Goal:** App has a proper home screen; returning users can resume.

**Build order:**

1. `screens/home_screen.dart` — static 3D cube, Start / Continue buttons, stage label
2. Session load on app start via `session_provider`
3. Discard confirmation dialog
4. "Continue" navigates to Teaching Screen with restored state

**Done criteria:**
- [ ] "Continue" appears only when a session exists
- [ ] Restored session shows correct stage, step, and cube state
- [ ] Discard wipes session and starts fresh scan

---

### Phase 9 — Polish & Hardening (Days 11–13)

| Task | Detail |
|------|--------|
| Camera permission | Add `permission_handler`; handle denied case with Settings link |
| Accessibility | Add `Semantics` labels to all interactive widgets; verify contrast |
| Error surfaces | All `ValidationError` kinds show user-friendly messages |
| Edge cases | Back-navigation guards, solver empty-list guard, session migration stub |
| Performance | Profile 3D renderer on target device; verify solver isolate doesn't block UI |
| Regression | Run full `flutter test` suite; fix any failures |

**Done criteria:**
- [ ] All error cases from `04-app-flow.md §8` are handled
- [ ] `flutter analyze` reports zero errors, zero warnings
- [ ] `flutter test` passes
- [ ] Manual end-to-end test: complete beginner can solve a scrambled cube using the app alone

---

### Phase 10 — Demo Prep (Day 14)

| Task |
|------|
| `flutter run --release` performance check |
| README.md — setup instructions, feature list, screenshots |
| Final `flutter analyze` + `flutter test` |
| Device install and dry-run of demo scenario |

---

## 4. Milestones

| Milestone | Day | "Done" means |
|-----------|-----|-------------|
| **M1: Domain green** | 3 | All unit tests pass; solver solves any scramble |
| **M2: Color pipeline** | 4 | Classifier identifies 6 colors from synthetic inputs |
| **M3: Data layer** | 4 | Session round-trips; providers compile |
| **M4: Shell runs** | 5 | App launches, all routes navigable |
| **M5: Scan loop** | 7 | 6-face scan + correction + validation works |
| **M6: 3D renderer** | 8 | Cube renders + animates + orbits |
| **M7: Full teaching** | 10 | End-to-end solve flow with real solver |
| **M8: Session resume** | 10 | Continue from previous session works |
| **M9: Polished** | 13 | All errors handled, accessibility done, tests passing |
| **M10: Demo ready** | 14 | Release build, README, device install |

---

## 5. Testing Strategy

| Type | What | Where | When |
|------|------|-------|------|
| **Unit tests** | `CubeValidator`, `MoveApplier`, `PieceView`, `StageDetector`, `StagedSolver`, `ColorClassifier` | `test/domain/`, `test/utils/` | Written alongside each domain file (Phase 1–2) |
| **Solver correctness** | 20+ random scrambles → solve all 7 stages → assert solved | `test/domain/staged_solver_test.dart` | Phase 1 |
| **Stage boundary** | 8 boundary states → assert `StageDetector.detect()` correct | `test/domain/stage_detector_test.dart` | Phase 1 |
| **Integration (manual)** | Full scan → correct → solve flow on device | Manual | End of Phase 7 and Phase 9 |

No widget tests or integration tests for v1 (timeline constraint). The domain tests are the critical regression guard.

---

## 6. Dependencies (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  camera: ^0.10.0
  image: ^4.0.0
  provider: ^6.1.0
  go_router: ^13.0.0
  shared_preferences: ^2.2.0
  permission_handler: ^11.0.0
  # three_js: TBD — evaluate in Phase 6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
```

---

## 7. Open Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `three_js` doesn't support layer rotation cleanly | Medium | Medium | 2-hour evaluate timebox in Phase 6; fallback is `CustomPainter` (already designed) |
| LAB classifier struggles with orange/red confusion | Medium | High | Add manual correction step (already in design); tune LAB reference sampling in Phase 9 |
| Cross BFS too slow on-device | Low | Medium | BFS is depth-8 max over 4 pieces; profiled in isolate — should be <100ms |
| 3D renderer hits 30fps on low-end device | Low | Medium | Reduce cubie face count; simplify projection; or reduce animation complexity |
| 2-week timeline slips on `CustomPainter` 3D work | Medium | High | Phase 6 is given 3 days; if behind by Day 8, simplify to isometric 2D projection (still animatable) |
