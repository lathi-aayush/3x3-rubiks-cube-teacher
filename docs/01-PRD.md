# 01 — Product Requirements Document (PRD)
> Rubik's Cube Learning App · v1.0 · Last updated: 2026-10-02

---

## 1. Problem Statement

Most Rubik's cube solvers online just spit out a move sequence — they don't *teach*. Learners get stuck partway through (most commonly on the last layer) and have no way to resume learning from their current cube state. Existing apps force users to start from scratch or watch generic YouTube tutorials that don't respond to *their specific cube*.

**Core pain:** "I've solved the first two layers. I always get stuck on the last layer. No app helps me pick up exactly where I am."

---

## 2. Goals

| Goal | Description |
|------|-------------|
| **G1** | Detect a real cube's state accurately via the phone camera |
| **G2** | Identify which of the 7 beginner stages the user is currently at |
| **G3** | Guide the user through the remaining stage(s) with 3D-animated, step-by-step instructions |
| **G4** | Allow the user to jump directly into any stage — no forced "start from scratch" |
| **G5** | Be usable by a complete beginner with zero prior cubing knowledge |

---

## 3. Non-Goals (v1)

- No CFOP / Roux / ZZ speedcubing methods
- No user accounts or cloud sync
- No Kociemba "fewest-moves" optimal solver button
- No App Store / Play Store deployment
- No multiplayer, leaderboards, timers, or gamification
- No web platform (mobile only for v1)
- No piece-highlighting on the 3D cube (deferred to v1.1)

---

## 4. Target Users / Personas

### Persona A — "Stuck on the Last Layer" (Primary)
- Has watched a tutorial, solved F2L, but always fails OLL/PLL
- Frustrated that solvers don't *explain*; just wants to be walked through their specific cube state
- Age: 14–25, smartphone-native

### Persona B — "Complete Beginner"
- Has never solved a cube, just bought one
- Needs the app to start from stage 1 and explain *why* each step is done
- Needs very clear, visual, non-intimidating UI (Duolingo-like)

### Persona C — "Selective Learner"
- Already knows some stages well
- Wants to practice only specific stages (e.g., just the yellow cross)
- Needs the stage-selector to be accessible without completing earlier stages

---

## 5. Feature List — Prioritized

### MVP / v1.0 (must ship in 2 weeks)

| # | Feature | Description |
|---|---------|-------------|
| F1 | **Camera Scan** | Face-by-face scanning (6 faces), one at a time. On-screen grid overlay guides alignment. |
| F2 | **Manual Correction** | After scanning, show a 2D sticker grid the user can tap to fix misread colors. |
| F3 | **Cube State Validation** | Check that all 54 stickers are legal (9 per color, valid piece combinations). Show error if not. |
| F4 | **Stage Auto-Detection** | Identify which of the 7 stages the cube is already at and suggest the next one. |
| F5 | **Stage Selector** | Allow user to manually pick any of the 7 stages to jump to, bypassing auto-detection. |
| F6 | **Teaching Mode** | Step-by-step instructions per stage, with algorithm notation displayed. |
| F7 | **3D Cube Visualization** | Animated 3D cube showing the current cube state and animating each move. |
| F8 | **Stage Progress Indicator** | Visual checklist showing all 7 stages and current position. |
| F9 | **Re-scan at Any Point** | User can re-scan mid-session to let the app verify the physical cube state. |
| F10 | **Local Progress Persistence** | Remember stage and step reached (via local storage / shared_preferences). |

### v1.1 (post-deadline sprint)

| # | Feature |
|---|---------|
| F11 | Piece-highlighting on 3D cube (show which cubies are relevant to the current step) |
| F12 | Kociemba "just solve it for me" fallback button |
| F13 | CFOP method support |

### v2 / Future

| # | Feature |
|---|---------|
| F14 | User accounts + cloud progress sync |
| F15 | App Store / Play Store deployment |
| F16 | Solve timer + personal best tracking |

---

## 6. User Stories & Acceptance Criteria

### US-01: Camera Scan
> **As a user**, I want to scan each face of my cube with my camera so the app knows my cube's current state.

**Acceptance Criteria:**
- App displays a 3x3 grid overlay on the camera feed for alignment
- User taps "Capture" to freeze and confirm a face
- App extracts 9 sticker colors and displays them for review
- Flow repeats for all 6 faces (progress shown: "Face 3 of 6")
- Detected colors go through a correction step before being committed

---

### US-02: Manual Color Correction
> **As a user**, I want to fix any stickers the camera misread so the app has an accurate cube state.

**Acceptance Criteria:**
- After each face scan, a 3x3 tappable grid shows detected colors
- Tapping a sticker cell opens a color picker (6 colors)
- Corrected state is validated before the user can proceed

---

### US-03: Stage Auto-Detection
> **As a user**, I want the app to automatically figure out which stage I'm on so I don't have to tell it.

**Acceptance Criteria:**
- App evaluates the scanned cube state against each of the 7 stage completion conditions in order
- App identifies the earliest incomplete stage
- Result shown to user with an option to override (jump to a different stage)

---

### US-04: Stage Jump (Selective Learning)
> **As a user who already knows the first two layers**, I want to jump directly to the last-layer stages.

**Acceptance Criteria:**
- Stage selector screen lists all 7 stages
- User can tap any stage to begin teaching from that point
- App warns if the cube isn't ready for the chosen stage (but still allows proceeding)

---

### US-05: Teaching Mode
> **As a user**, I want step-by-step, animated instructions so I can learn the moves for my specific cube state.

**Acceptance Criteria:**
- Each step shows: (a) description of what to do, (b) move in standard notation, (c) 3D cube animation
- User taps "Next" to advance to the next move
- User can tap "Back" to revisit the previous move
- Stage completion screen appears when the stage is done, with "Continue to next stage" CTA

---

### US-06: 3D Cube Animation
> **As a user**, I want to see the move animated on a 3D cube so I can understand which face to turn.

**Acceptance Criteria:**
- 3D cube reflects the actual current cube state (correct sticker colors)
- Each move is animated smoothly (face rotation)
- User can rotate the 3D cube view with a drag gesture

---

### US-07: Progress Persistence
> **As a user**, I want the app to remember where I left off so I can continue later.

**Acceptance Criteria:**
- On relaunch, if a previous session exists, user is offered "Continue where you left off"
- Saved state includes: cube state (54 stickers), current stage, current step within stage
- User can choose to discard and start a new session

---

## 7. Success Metrics

| Metric | Target |
|--------|--------|
| Scan accuracy | >= 90% of scans require <= 1 manual correction |
| Stage detection accuracy | 100% correct for legal cube states |
| Teaching completion | User reaches "Stage Complete" screen at least once per session |
| App stability | Zero crashes during a normal solve session |
| Beginner clarity | A complete beginner can follow instructions without external help |
