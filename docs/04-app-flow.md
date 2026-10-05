# 04 — App Flow
> Rubik's Cube Learning App · v1.0 · Last updated: 2026-10-02

---

## 1. Top-Level Flow

```mermaid
flowchart TD
    A([App Launch]) --> B{Saved session\nexists?}
    B -- No --> C[Home Screen\nnew session only]
    B -- Yes --> D[Home Screen\nnew + continue]

    C --> E[Start New Session]
    D --> E
    D --> F[Continue]

    E --> G{Previous progress\nexists?}
    G -- Yes --> H[Confirm: Discard\nprevious session?]
    G -- No --> I[Scan Flow]
    H -- Discard --> I
    H -- Cancel --> D

    F --> T[Teaching Screen\nrestored state]

    I --> J[Stage Selector]
    J --> T
    T --> U{Stage complete?}
    U -- No --> T
    U -- Yes --> V[Stage Complete Screen]
    V --> W{Last stage\ndone?}
    W -- No --> J
    W -- Yes --> X[Solved Screen]
    X --> E
```

---

## 2. Scan Flow (Detail)

The user scans 6 faces in order: **Top → Right → Front → Bottom → Left → Back**.

```mermaid
flowchart TD
    S([Enter Scan Flow]) --> F1[Face Scan Screen\nFace 1 of 6: Top]

    F1 --> C1{Capture}
    C1 --> R1[Correction Screen\nFace 1]
    R1 --> OK1{Looks Good?}
    OK1 -- Re-scan --> F1
    OK1 -- Confirm --> F2[Face Scan Screen\nFace 2 of 6: Right]

    F2 --> C2{Capture}
    C2 --> R2[Correction Screen\nFace 2]
    R2 --> OK2{Looks Good?}
    OK2 -- Re-scan --> F2
    OK2 -- Confirm --> F3[... Faces 3–5 same pattern ...]

    F3 --> F6[Face Scan Screen\nFace 6 of 6: Back]
    F6 --> C6{Capture}
    C6 --> R6[Correction Screen\nFace 6]
    R6 --> OK6{Looks Good?}
    OK6 -- Re-scan --> F6
    OK6 -- Confirm --> V[Validate full cube state]

    V --> VR{Valid?}
    VR -- Invalid --> E[Error Screen\nshow which color\ncount is wrong]
    E --> FIX{User action}
    FIX -- Fix a face --> R1
    FIX -- Rescan all --> F1

    VR -- Valid --> D[Stage Auto-Detection]
    D --> SS[Stage Selector Screen]
```

### Scan order rationale
Top face is scanned first so the U-center (white) is available as the first reference LAB value. The remaining 5 centers are captured in R, F, D, L, B order — all 6 centers are known before any edge/corner is classified.

---

## 3. Color Correction Flow (per face)

```mermaid
flowchart TD
    A([Correction Screen shown]) --> B[Display 3×3 sticker grid\nwith detected colors]
    B --> C{User taps\na sticker?}
    C -- Yes --> D[Open color picker\nbottom sheet]
    D --> E[User selects color]
    E --> F[Update sticker cell]
    F --> C
    C -- No / Done --> G{Taps\nLooks Good}
    G --> H{Last face?}
    H -- No --> I[Next Face Scan Screen]
    H -- Yes --> J[Full cube validation]
```

**Center sticker behavior:** The center cell of the 3×3 grid is visually distinct (slightly dimmed border) and **not tappable** — centers define face identity and must not be changed.

---

## 4. Stage Detection & Selection Flow

```mermaid
flowchart TD
    A([54-sticker array committed]) --> B[Run StageDetector]
    B --> C[Check stage 1 complete?]
    C -- No --> D[Detected: Stage 1]
    C -- Yes --> E[Check stage 2 complete?]
    E -- No --> F[Detected: Stage 2]
    E -- Yes --> G[... repeat to stage 7 ...]
    G --> H[Detected: Stage N]

    D & F & H --> I[Stage Selector Screen\nshow detected stage highlighted]

    I --> J{User action}
    J -- Accept detected stage --> K[Run Solver for that stage]
    J -- Pick different stage --> L{Cube state\nvalid for\nchosen stage?}
    L -- Yes --> K
    L -- No --> M[Show inline warning banner]
    M --> N{User action}
    N -- Proceed anyway --> K
    N -- Pick another stage --> I

    K --> O[Teaching Screen]
```

---

## 5. Teaching Flow (Core Loop)

```mermaid
flowchart TD
    A([Teaching Screen\nstage N, step 1]) --> B[Display step:\n• instruction text\n• algorithm notation\n• 3D cube animated move]

    B --> C{User action}

    C -- Next --> D{More steps\nin stage?}
    D -- Yes --> E[Advance to step N+1\nApply move to cube state\nAnimate on 3D cube]
    E --> B

    D -- No --> F[Stage Complete Screen]

    C -- Back --> G{First step\nof stage?}
    G -- No --> H[Go to step N-1\nReverse move on cube state]
    H --> B
    G -- Yes --> I[Go to Stage Selector\nstage unchanged]

    C -- Re-scan --> J[Pause session\nSave current state]
    J --> K[Scan Flow\nall 6 faces]
    K --> L[Validate new scan]
    L --> M{Matches expected\nstate for current step?}
    M -- Yes --> B
    M -- No --> N[Show mismatch warning:\n'Your cube looks different\nthan expected at step N']
    N --> O{User choice}
    O -- Continue with scan --> P[Override: use scanned state\nRe-run solver from here]
    O -- Ignore scan --> B
    P --> B
```

### Step state machine

```
IDLE ──► ANIMATING ──► WAITING_FOR_USER
              ▲                │
              └────────────────┘  (loop on Next/Back)
```

The 3D cube animation plays automatically when a step is displayed. The "Next" button is enabled only after the animation completes (or after a 1-second minimum, whichever is longer) — prevents accidental skipping.

---

## 6. Re-scan Mid-Session Flow

```mermaid
flowchart TD
    A([User taps Re-scan\non Teaching Screen]) --> B[Save session state:\ncube state, stage, step]
    B --> C[Scan Flow — all 6 faces]
    C --> D[Validate scanned state]
    D --> E{Valid?}
    E -- No --> F[Error: invalid cube\nOffer: fix colors / rescan]
    F --> C
    E -- Yes --> G{Does scanned state match\nexpected state at current step?}
    G -- Match --> H[Resume Teaching Screen\nsame step]
    G -- Mismatch --> I[Show diff warning\nwith two options]
    I --> J[Continue with\nscanned state]
    I --> K[Ignore scan,\nkeep previous state]
    J --> L[Re-run solver\nfrom scanned state]
    L --> H
    K --> H
```

---

## 7. Session Persistence Flow

```mermaid
flowchart TD
    A([Any state change]) --> B[Serialize to JSON:\n{facelets54, stage, stepIndex}]
    B --> C[Write to shared_preferences\nkey: 'session']

    D([App launch]) --> E{shared_preferences\nhas 'session' key?}
    E -- No --> F[Home: new session only]
    E -- Yes --> G[Deserialize session]
    G --> H[Home: show Continue button\nwith stage/step label]

    I([User taps Discard]) --> J[Delete 'session' key]
    J --> K[Start fresh scan flow]
```

**Persistence trigger:** Session is written to disk after every step advance, every face correction commit, and every stage transition. No explicit "save" button needed.

---

## 8. Error & Edge Case Handling

| Scenario | Detection point | Handling |
|----------|----------------|----------|
| Wrong sticker count (e.g. 10 reds) | Post-correction validation | Error screen: "Red appears 10 times, should be 9. Go back and fix it." Shows which color(s) are off. |
| Illegal cube state (twisted corner, flipped edge, parity) | Post-validation legality check via `PieceView` | Error screen: "This cube state isn't physically possible. Check for misread stickers." Links back to correction. |
| Camera permission denied | On scan screen open | System permission dialog first; if denied, show in-app prompt with link to Settings. |
| Stage mismatch on manual jump | Stage Selector | Inline warning banner (non-blocking). User may proceed. |
| Solver returns no solution | Solver output check | Should not happen if input is valid. If it does: "Something went wrong — please re-scan your cube." |
| Re-scan state mismatch | Mid-session re-scan | Mismatch dialog with two options (see Flow 6). |
| App killed mid-session | App relaunch | Session restored from `shared_preferences` (persisted after every step). |
| User goes back past step 1 | Teaching Screen back action | Navigate to Stage Selector (stage unchanged, not reset). |
