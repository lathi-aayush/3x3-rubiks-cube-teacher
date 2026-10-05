# 00 — Master Build Plan: Rubik's Cube Logic (Hand-Written)
> Scope: cube representation, moves, validation, stage detection, and all 7 solver stages.
> Camera / OpenCV / Flutter UI are explicitly out of scope for this document.
> Nothing here is to be implemented by a library. Every function is written by hand.
> Last updated: 2026-10-02

---

## How to Read This Document

This plan is ordered **from foundation to application**. Each section tells you:
- **What** to build (the concept)
- **Why** it is shaped the way it is
- **How** to think through writing it yourself (the algorithm, in words)
- **What to verify** once you have written it

Do not skip sections. Later stages depend on everything before them.

---

## Part 1 — The Cube Representation

### 1.1 The Facelet Array

**Concept:**
A Rubik's cube has 54 colored stickers (facelets). You will represent the entire cube state as a flat list of 54 integers — one integer per sticker. Nothing else. This is the single source of truth for everything that follows.

**Face ordering:**
Assign each face a block of 9 consecutive slots in the array, in this order:

```
U (top/up)   → indices  0 –  8
R (right)    → indices  9 – 17
F (front)    → indices 18 – 26
D (down)     → indices 27 – 35
L (left)     → indices 36 – 44
B (back)     → indices 45 – 53
```

**Cell layout within each face block:**
Read each face left-to-right, top-to-bottom when looking directly at it:

```
position 0 | position 1 | position 2
position 3 | position 4 | position 5   ← position 4 is always the center
position 6 | position 7 | position 8
```

So sticker at index `(face * 9) + cell` where face ∈ {0..5} and cell ∈ {0..8}.

**Color encoding:**
Assign each color an integer 0–5. Fix this mapping and never change it:

```
0 = White   (U face)
1 = Yellow  (D face)
2 = Green   (F face)
3 = Blue    (B face)
4 = Red     (R face)
5 = Orange  (L face)
```

This mapping is chosen so that opposite faces have values that differ: White↔Yellow (0↔1), Green↔Blue (2↔3), Red↔Orange (4↔5). That property is useful in validation.

**The solved state:**
Write the solved state as a hardcoded constant array of 54 integers. In a solved cube every sticker on face X has color X (because center sticker of face X is always color X). So:

```
indices  0– 8 → all 0   (white)
indices  9–17 → all 4   (red)
indices 18–26 → all 2   (green)
indices 27–35 → all 1   (yellow)
indices 36–44 → all 5   (orange)
indices 45–53 → all 3   (blue)
```

Write this out in full. It is your ground truth for tests.

**What to verify:**
- The array has exactly 54 elements.
- Each color appears exactly 9 times.
- `facelets[face * 9 + 4]` gives the correct center color for every face.

---

### 1.2 The Move Enum

**Concept:**
There are 18 distinct quarter-turn and half-turn moves on a 3×3 cube:

```
U   Ui  U2
D   Di  D2
R   Ri  R2
L   Li  L2
F   Fi  F2
B   Bi  B2
```

`U` = clockwise quarter turn of the Up face when looking at it from above.
`Ui` = counter-clockwise quarter turn (inverse of U).
`U2` = 180° turn (U applied twice).

Define these as an enum (or integer constants). You will use them as keys into a move permutation table.

---

## Part 2 — Move Permutation Tables

### 2.1 What a Permutation Table Is

**Concept:**
Applying a move to the cube is a deterministic rearrangement of the 54 sticker slots. Every move can be completely described by a list of 54 integers: `perm[i]` = "the sticker at position i, after the move, came from position perm[i]."

In code:

```
newFacelets[i] = oldFacelets[perm[i]]    for all i in 0..53
```

That is all `applyMove` ever does. It is a pure function. It never mutates; it returns a new array.

### 2.2 How to Derive a Permutation Table by Hand

For each move, trace where every sticker goes. You do this once per move, carefully, and store the result as a compile-time constant.

**Method — use cycles:**
A move only affects a subset of stickers. The unaffected stickers map to themselves (`perm[i] = i`). The affected stickers move in cycles. A quarter turn always produces 4-element cycles. A half turn produces 2-element cycles.

**Worked example — U move (Up face, clockwise):**

When you turn the Up face clockwise:

1. The 8 non-center stickers on the U face rotate clockwise:
   ```
   Cycle: 0→2→8→6→0   (corners of U face)
   Cycle: 1→5→7→3→1   (edges of U face)
   ```
   In permutation terms: perm[2]=0, perm[8]=2, perm[6]=8, perm[0]=6
   and: perm[5]=1, perm[7]=5, perm[3]=7, perm[1]=3

2. The top row of the adjacent 4 side faces cycles:
   ```
   U-adjacent cycle (clockwise): R-top-row → F-top-row → L-top-row → B-top-row → R-top-row
   ```
   Concretely:
   - R top row: indices 9, 10, 11
   - F top row: indices 18, 19, 20
   - L top row: indices 36, 37, 38
   - B top row: indices 45, 46, 47

   After U clockwise:
   - F top row ← R top row: perm[18]=9, perm[19]=10, perm[20]=11
   - L top row ← F top row: perm[36]=18, perm[37]=19, perm[38]=20
   - B top row ← L top row: perm[45]=36, perm[46]=37, perm[47]=38
   - R top row ← B top row: perm[9]=45, perm[10]=46, perm[11]=47

3. All other indices: perm[i] = i.

**Do this for all 6 face moves (U, D, R, L, F, B).** Ui is U applied 3 times (or equivalently, reverse the cycles). U2 is U applied twice (2-element swaps). You can derive Ui and U2 by composing the U table with itself — but it is cleaner and less error-prone to trace them directly.

**What to verify per permutation table:**
- It is a bijection: every index 0–53 appears exactly once as a value.
- Applying it 4 times (quarter turn) or 2 times (half turn) gives back the identity.
- Visual sanity check: apply U to the solved state constant. The U face should rotate clockwise; the top row of R, F, L, B should shift as expected.

### 2.3 Composing Moves

Once you have the 6 base tables (U, D, R, L, F, B), derive Ui, Di, etc. by composition:

```
Ui = compose(U, U, U)       // 3× U
U2 = compose(U, U)          // 2× U
```

Where `compose(a, b)[i] = a[b[i]]`.

This means you only need to hand-trace 6 tables. The other 12 are derived mechanically.

---

## Part 3 — The Piece View

### 3.1 Why You Need It

The facelet array is great for applying moves. It is awkward for reasoning about where pieces are and how they are oriented — which is exactly what stage detection and the procedural solver steps need.

The piece view is a **read-only, derived data structure** computed from the facelet array on demand. It is never stored. You compute it, use it, discard it.

### 3.2 Corners

**Concept:**
There are 8 corners. Each corner touches 3 faces. In a solved cube each corner is in a fixed home position.

**Number the 8 home positions:**
```
0 = URF   (Up-Right-Front corner)
1 = ULF   (Up-Left-Front corner)
2 = ULB   (Up-Left-Back corner)
3 = URB   (Up-Right-Back corner)
4 = DRF   (Down-Right-Front corner)
5 = DLF   (Down-Left-Front corner)
6 = DLB   (Down-Left-Back corner)
7 = DRB   (Down-Right-Back corner)
```

**For each home position, record the 3 facelet indices** (in a fixed order: U/D face first, then R/L face, then F/B face):

```
URF: facelets[2],  facelets[9],  facelets[20]
ULF: facelets[0],  facelets[36+2], facelets[18]  ← trace carefully from your face diagram
... (derive all 8 from your face layout)
```

Write these 8×3 index triples as a hardcoded table. You will look up this table when extracting corners.

**Extracting a corner's position and orientation:**

For each of the 8 home positions, read the 3 sticker colors. The 3 colors uniquely identify which corner piece is sitting there (since each corner piece has a unique combination of 3 colors). That tells you the **position** (which of the 8 pieces is here).

The **orientation** (0, 1, or 2) tells you how the piece is twisted:
- Orientation 0: the U/D-face sticker of the piece is facing Up or Down (correct).
- Orientation 1: the piece is twisted clockwise once.
- Orientation 2: the piece is twisted counter-clockwise once (clockwise twice).

To determine orientation: look at which of the 3 sticker slots holds a U or D color (white or yellow). If it is the first slot (U/D face slot) → orientation 0. If the second slot → orientation 1. If the third slot → orientation 2.

**What to verify:**
- On the solved state, all 8 corners have position = their home index and orientation = 0.
- If you apply U to the solved state, the 4 U-layer corners move to new positions; their orientations stay 0 (U turns do not twist corners).
- If you apply R to the solved state, corners URF, URB, DRF, DRB move and their orientations change.

### 3.3 Edges

**Concept:**
There are 12 edges. Each edge touches 2 faces. Same idea as corners.

**Number the 12 home positions:**
```
0=UR  1=UF  2=UL  3=UB
4=DR  5=DF  6=DL  7=DB
8=FR  9=FL  10=BL  11=BR
```

For each home position, record the 2 facelet indices (U/D/F/B face first, then R/L face).

**Extracting position:** the 2 colors uniquely identify which edge piece.

**Orientation:** 0 = the U/D/F/B-face sticker is facing the U/D/F/B side (correct). 1 = it is flipped.

**What to verify:**
- Solved state: all edges position = home index, orientation = 0.
- U and D moves never change edge orientation.
- F, B, R, L moves flip some edges.

---

## Part 4 — Validation

### 4.1 Color Count Check

**What:** Count occurrences of each color integer 0–5 in the 54-element array. Each must equal exactly 9.

**How:** One pass, a 6-element counter array. O(54). Trivial.

**Why first:** If this fails, nothing else is meaningful.

### 4.2 Corner Orientation Sum

**What:** Sum the orientations of all 8 corners modulo 3. The result must be 0.

**Why:** Every legal move changes corner orientations in a way that preserves this sum mod 3. A single twisted corner (which can happen if someone physically pops and reinserts a corner) violates this invariant.

**How:** Compute the piece view, sum `corner.orientation` for all 8 corners, check `sum % 3 == 0`.

### 4.3 Edge Orientation Sum

**What:** Sum the orientations of all 12 edges modulo 2. Must be 0.

**Why:** Same logic — every legal move preserves this parity. A single flipped edge (physically re-inserted) breaks it.

**How:** Sum `edge.orientation` for all 12 edges, check `sum % 2 == 0`.

### 4.4 Permutation Parity

**What:** The permutation parity of the corner positions must equal the permutation parity of the edge positions. (Both even, or both odd.)

**Why:** Every legal move is an even permutation on the combined 20-piece set. A swapped pair of edges with no corresponding corner swap (which only happens from disassembly) violates this.

**How to compute permutation parity:**
A permutation's parity is even if it can be decomposed into an even number of transpositions (swaps), odd otherwise. Efficient method: count the number of cycles in the permutation. Parity = (total_elements - number_of_cycles) mod 2. Even = 0, Odd = 1.

To find cycles: start from position 0, follow where it maps to, keep going until you return to 0. That is one cycle. Mark all visited positions. Repeat from the next unmarked position.

Compute this for the 8-element corner position permutation and the 12-element edge position permutation separately. The two parity values must be equal.

**What to verify:**
- Solved state passes all 4 checks.
- Manually twist one corner sticker in your test array → corner orientation sum fails.
- Manually swap two edges → parity check fails.

---

## Part 5 — Stage Detection

### 5.1 How Stage Detection Works

Call `isStageComplete(facelets, stage)` for each stage in order 1→7. The first stage that returns false is the current stage.

If all 7 return true, the cube is solved.

All checks use the piece view derived from the facelet array.

### 5.2 Stage Completion Conditions (Hand-Write Each One)

---

**Stage 1: White Cross**

The 4 edges adjacent to the U face (UR=0, UF=1, UL=2, UB=3) must all be:
- In their home position (position == their index)
- Correctly oriented (orientation == 0)

This means the white cross is formed AND the edge side-colors match the adjacent center colors.

*Note:* Do not just check that the U-face shows a cross of white stickers. That misses the case where a white edge is in the right place but flipped. Check position AND orientation.

---

**Stage 2: White Corners**

The 4 corners on the U layer (URF=0, ULF=1, ULB=2, URB=3) must all be:
- In their home position
- Orientation == 0

And stage 1 must be complete.

---

**Stage 3: Middle Layer Edges**

The 4 edges on the middle (equatorial) layer (FR=8, FL=9, BL=10, BR=11) must all be:
- In their home position
- Orientation == 0

And stages 1–2 must be complete.

---

**Stage 4: Yellow Cross**

The 4 U-layer edges (UR=0, UF=1, UL=2, UB=3) must all have:
- The U-face sticker showing yellow (color 1)

Check directly on the facelet array — look at the U-face slot of each of these 4 edge positions. You do not need the piece view for this check. You do not care about position or orientation here, only whether yellow is facing up.

---

**Stage 5: Orient Yellow Corners**

All 8 stickers on the U face must be yellow. That is:
- `facelets[0]` through `facelets[8]` (the U face block) — all must equal 1 (yellow).

This is also a direct facelet check, no piece view needed.

---

**Stage 6: Permute Yellow Corners**

All 4 U-layer corners must be in their correct home positions (position == home index). Orientation does not matter here.

Use the piece view: extract corners, filter to the 4 U-layer corners (indices 0–3), check their positions.

---

**Stage 7: Permute Yellow Edges (= Fully Solved)**

The cube is fully solved: all 54 stickers match the solved state constant.

Or equivalently: all 12 edges in correct position and orientation, and all 8 corners in correct position and orientation. Checking the facelet array against the solved constant is the simplest implementation.

---

## Part 6 — The Staged Solver

### 6.0 General Principles

- Each stage solver takes the current facelet array and returns a list of Steps.
- A Step is: (description text, move sequence, notation string).
- Applying all moves in all steps in order produces a facelet array that passes the stage's completion check.
- Solvers are pure functions. They never mutate the input array.
- Every solver must handle the case where the stage is already complete (return empty list).

### 6.1 Stage 1 Solver — White Cross (BFS)

**Goal:** Place 4 white edge pieces (UR, UF, UL, UB) in their home positions with correct orientation.

**Why BFS:**
The cross is the first stage and the cube can be in any state. The number of possible cross states is small enough (at most ~4096 states if you only track the 4 cross edges) that BFS is fast and produces a valid solution.

**Reduced state for BFS:**
You do not need to track the full 54-sticker cube. Track only the 4 white edge pieces:
- Where is each of the 4 white edges? (position: 0–11)
- What is its orientation? (0 or 1)

This gives at most 12×2 choices for each of 4 edges ≈ small enough to BFS to depth 7 or 8.

**BFS algorithm:**

```
1. Extract the reduced state (positions + orientations of the 4 white edges).
2. If reduced state == solved cross state → return empty.
3. Initialize a queue with (initial state, empty move list).
4. Initialize a visited set.
5. Loop:
   a. Dequeue (state, moves).
   b. For each of the 18 moves:
      - Apply the move to the reduced state.
      - If new state == solved cross state → return the move list + this move.
      - If new state not visited → enqueue (new state, moves + this move) and mark visited.
6. This will always find a solution within ~7 moves for the cross.
```

**Applying a move to the reduced state:**
You need to know how each of the 18 moves permutes the 12 edge positions and flips orientations. Derive this from the full permutation tables you already have — extract only the edge-relevant parts.

**Decomposing into human steps:**
The BFS gives you a raw move sequence. Wrap the entire sequence as a single Step with description "Solve the white cross." For the MVP this is sufficient — the 3D animation will show the moves one by one.

**What to verify:**
- From solved state: returns empty list.
- From a state with cross already broken: returns a sequence that, when applied, satisfies stage 1 completion check.
- Test at least 10 scrambled states.

---

### 6.2 Stage 2 Solver — White Corners (Procedural)

**Goal:** Place and orient all 4 white corner pieces.

**Why procedural (not BFS):**
The beginner method for corners is a human-followable procedure. It is also what you want to *teach*. BFS output for corners looks arbitrary. The procedure has 4 logical steps a learner can follow.

**The procedure (repeat for each of the 4 white corners):**

For each white corner (URF, ULF, ULB, URB in order):

**Step A — Find the corner.**
Scan all 8 corner positions to find where the target corner piece currently is.

- Case 1: It is already in its correct home position with orientation 0 → skip it.
- Case 2: It is in a U-layer position (positions 0–3) but wrong slot or wrong orientation → move it down first (see Step B), then proceed.
- Case 3: It is in a D-layer position (positions 4–7) → proceed to Step C.

**Step B — Move a misplaced U-layer corner down.**
If the target corner is in some U-layer slot (not its home), bring it to the D layer by:
1. Rotate U so the corner is above a D slot that matches its home column (e.g., corner belonging to URF → position it above the DRF slot).
2. Apply the right-hand insert algorithm in reverse to push it down: `R Di Ri` (positions the corner into the D layer without disturbing the already-solved cross).

Or more simply: do `D` moves to align, then apply the right-hand insert once. The exact choice depends on which D slot is free — since earlier corners may already be placed.

**Step C — Place and orient from the D layer.**
The corner is now in some D-layer position. You need to:
1. Do U and D moves (no R, L, F, B yet) to align the corner's home slot above it.
2. Identify the corner's orientation (which face the white sticker is facing).
3. Apply the appropriate trigger:

   - **Right-hand insert (white faces Right):**
     `R Di Ri` — then check. Repeat until white faces Up.
     Full algorithm: `R Di Ri Di R Di Di Ri` (in the worst case).
     Simpler: apply `R Di Ri` once; if not solved, do `Di` and repeat (up to 5 times total).

   - **Left-hand insert (white faces Left):**
     `Li D L` — analogous.

   - **White faces Down:**
     Apply the right-hand insert once, which moves the corner to a new orientation, then re-apply the case.

**In code:**
For each target corner:
1. Find it (piece view lookup by color combination).
2. If in U layer → generate moves to push it down.
3. Generate U/D rotation moves to align it above home slot.
4. Detect orientation → select algorithm → emit those moves.
5. Apply all emitted moves to the facelet array before processing the next corner.

Each corner becomes one Step (or a small sequence of sub-steps).

**What to verify:**
- From a state where stage 1 is complete and corners are scrambled: all 4 corners end up solved.
- Stage 1 completion condition still holds after the solver runs (the cross must not be disturbed).

---

### 6.3 Stage 3 Solver — Middle Layer Edges (Procedural)

**Goal:** Place the 4 middle-layer edges (FR=8, FL=9, BL=10, BR=11).

**The beginner procedure:**

Repeat for each middle edge (FR, FL, BL, BR in any order):

**Step A — Find the edge.**
Scan all 12 edge positions for the target piece.

- Case: Edge is already in its home position with orientation 0 → skip.
- Case: Edge is in the middle layer but wrong position or flipped → extract it to the top layer first, then place it.
- Case: Edge is in the U layer → proceed to Step B.

**Step B — Extract a wrongly-placed middle edge to U layer.**
Apply either the right or left insert algorithm (see below) on any correctly empty U-layer slot above the wrong position. This pops the middle edge out to the top. Now treat it as the Case above.

**Step C — Insert from U layer.**
The edge piece is on the U layer (one of positions 0–3: UR, UF, UL, UB).

1. Do U moves to bring the edge piece to the UF position (index 1). The sticker facing upward tells you which color matches which adjacent center.
2. Determine whether the piece goes to the right or left of F:
   - **Goes to FR (right):** Apply `U R Ui Ri Ui Fi U F`
   - **Goes to FL (left):** Apply `Ui Li U L U F Ui Fi`
3. Before applying, do additional U rotations if needed to align the piece's non-yellow sticker with the matching side center.

**The key insight for the student:**
The two algorithms above are mirror images of each other. Learn one, derive the other by reflection (R↔L, clockwise↔counter-clockwise).

**What to verify:**
- Stages 1 and 2 completion conditions hold after the solver runs.
- All 4 middle edges end up in home position, orientation 0.

---

### 6.4 Stage 4 Solver — Yellow Cross (Case Lookup)

**Goal:** Form a yellow cross on the U face. We care only that the 4 edge facelets on U are yellow. Position and orientation of those edges do not matter yet.

**The 4 cases:**

Look at the U face. Identify which of the 4 edge cells (top, right, bottom, left of center) are yellow. There are exactly 4 distinct patterns (up to rotation):

```
Case 1 — Dot:      No yellow edges facing up.
Case 2 — L-shape:  2 adjacent yellow edges (e.g., top and right).
Case 3 — Bar:      2 opposite yellow edges (e.g., top and bottom).
Case 4 — Cross:    All 4 yellow edges facing up. Done.
```

**The single algorithm (F R U Ri Ui Fi):**

This algorithm, applied to the right case with the right orientation, always moves toward the cross. Here is the rule:

- **Dot:** Apply algorithm once → you get L-shape or Bar.
- **L-shape:** Orient the cube so the L opens toward the top-left (yellow edges at top and left). Apply algorithm once → you get a cross.
- **Bar:** Orient the cube so the bar is horizontal (yellow edges at left and right). Apply algorithm once → you get a cross.
- **Cross:** Done.

So the maximum number of algorithm applications is 3.

**In code:**
1. Detect which case by reading `facelets[1]`, `facelets[5]`, `facelets[7]`, `facelets[3]` (top, right, bottom, left edge cells of U face).
2. Emit U rotation moves to achieve the correct orientation for the algorithm.
3. Emit the algorithm `F R U Ri Ui Fi`.
4. Apply all emitted moves to the facelet array.
5. Repeat until cross is detected.

**What to verify:**
- All 4 cases are handled correctly.
- After at most 3 iterations, the U-face cross check passes.
- Stages 1–3 completion conditions still hold (this algorithm does not disturb the bottom two layers if the U orientations are done correctly, but verify this).

---

### 6.5 Stage 5 Solver — Orient Yellow Corners (Procedural)

**Goal:** All 8 stickers on the U face become yellow. The yellow cross from stage 4 is maintained. (Corner positions may shuffle — that is OK here.)

**The algorithm — Sune trigger:**
`R U Ri U R U U Ri`

**The procedure:**

1. Count how many U-layer corners already have yellow facing up.
   - All 4 → done.
2. Otherwise: find a corner that does NOT have yellow facing up.
3. Rotate U (with a U or Ui or U2 move) to bring that corner to the Front-Right-Up (URF) position.
4. Apply Sune: `R U Ri U R U U Ri`
5. Check again. Repeat until all 4 corners are oriented.

**Important:** After applying Sune, the U-face may look worse before it looks better. This is expected. The invariant is that stages 1–3 (bottom two layers) are never disturbed by Sune, because Sune only moves U-layer pieces. Verify this in testing.

**In code:**
Loop:
- Check if all 4 U-face corners are yellow → break.
- Find a URF-position corner with non-yellow U-face sticker.
- Emit U rotation moves to bring it to URF.
- Emit Sune algorithm.
- Apply all emitted moves.

**Termination:** For any valid cross state, this loop terminates in at most 5 Sune applications. Add a loop counter guard (max 10 iterations) to prevent infinite loops during testing.

**What to verify:**
- Stage 4 (yellow cross) completion condition holds after this solver (edge orientations preserved).
- All 4 U-face corner cells are yellow.
- The bottom two layers are undisturbed.

---

### 6.6 Stage 6 Solver — Permute Yellow Corners (Case Lookup)

**Goal:** Move all 4 U-layer corners to their correct home positions. Orientations may still be wrong (that was fixed in stage 5 — wait, no: stage 5 orients them, stage 6 positions them). 

*Correction on ordering (standard beginner method):*
Stage 5 orients all corners (yellow up). Stage 6 positions all corners (into correct slots). At this point corner orientations may have been scrambled by stage 5 — but since all U-face stickers are yellow and bottom layers are correct, the position check is still meaningful.

**The key check:**
Look at the 4 U-layer corners using the piece view. Find any corner that is already in its correct home position. If none is in place, apply the algorithm once (from any orientation) — this will place at least one corner correctly.

**The A-perm algorithm:**
`R U Ri Ui Ri F R R Ui Ri Ui R U Ri Fi`

This algorithm cycles 3 of the 4 U-layer corners (URF→URB→ULB, keeping ULF fixed). The stationary corner is at ULF position.

**Procedure:**

1. Using the piece view, check each of the 4 U-layer corner positions.
2. Find a corner that is in its correct home position.
3. Rotate U to put that corner at ULF (the stationary position for A-perm).
4. Apply A-perm.
5. Check again. If not all correct, repeat.

**Case: no corner is in its correct position:**
Apply A-perm once from any orientation. After one application, at least one corner will be correctly placed. Then proceed as above.

**Termination:** At most 3 applications of A-perm (plus U rotations) solve all 4 corners.

**What to verify:**
- All 4 U-layer corners end up in their correct home positions.
- Bottom two layers undisturbed.

---

### 6.7 Stage 7 Solver — Permute Yellow Edges (Case Lookup)

**Goal:** Move the 4 U-layer edges to their correct home positions. This is the final stage — if this is solved, the whole cube is solved.

**The cases:**

Using the piece view, look at the positions of edges UR(0), UF(1), UL(2), UB(3):

- **All 4 in correct position:** Done.
- **3-cycle clockwise:** UF→UL→UB (UR is correct). Edges cycle counter-clockwise when viewed from above.
- **3-cycle counter-clockwise:** UF→UB→UL (UR is correct).
- **Adjacent swap:** Two adjacent edges swapped (e.g., UF↔UL).
- **Opposite swap:** Two opposite edges swapped (e.g., UF↔UB).

*Note:* Due to parity, you will never have exactly 2 edges swapped without the others also being wrong, in a way that cannot be corrected. All reachable cases are covered by the above.

**The U-perm algorithms:**

- **U-perm A (3-cycle: UF→UL→UB, counter-clockwise from above):**
  `R Ui R U R U R Ui Ri Ui R R`

- **U-perm B (3-cycle: UF→UB→UL, clockwise from above):**
  `R R U R U Ri Ui Ri Ui Ri U Ri`

- **Adjacent swap (e.g., UF↔UL):**
  Apply U-perm A once → converts to a 3-cycle → apply U-perm A or B again.

- **Opposite swap (e.g., UF↔UB):**
  Apply U-perm A once → converts to an adjacent swap → handle as above.

**Procedure:**

1. Detect the case using the piece view.
2. Rotate U to put the correct edge (if one exists) at UR — the stationary position for U-perms.
3. Detect whether the cycle is A or B by looking at where UF goes.
4. Apply the appropriate algorithm.
5. Check again. Repeat if needed.

**Termination:** At most 2 algorithm applications solves all edge cases.

**What to verify:**
- All 4 U-layer edges in correct position and orientation.
- Full cube matches solved state constant.
- This is your final integration test — a fully scrambled cube should be fully solved after running stages 1–7 in sequence.

---

## Part 7 — Integration & Test Plan

### 7.1 Unit Tests to Write (in order)

| Test | What to assert |
|------|---------------|
| Solved state constant | 54 elements, 9 of each color, correct centers |
| Move permutation — U | Apply to solved state; correct face rotates, correct rows shift |
| Move permutation — all 18 | Apply move then inverse → back to input |
| Move permutation — bijection | Each permutation table contains each index 0–53 exactly once |
| Move composition | `compose(U, U, U, U)` == identity for all 6 faces |
| PieceView — solved state | All corners: position == index, orientation == 0. All edges: same. |
| PieceView — after R | Corners URF, DRF, DRB, URB have moved; their orientations have changed (R twists corners). |
| CubeValidator — valid states | Solved state passes; each of 10 random scrambles passes |
| CubeValidator — twisted corner | Single corner twist fails with `twistedCorner` |
| CubeValidator — flipped edge | Single edge flip fails with `flippedEdge` |
| CubeValidator — swapped pair | Two edges swapped fails with `parityError` |
| StageDetector — boundaries | 8 hand-constructed states (0 through 7 stages complete) each detected correctly |
| Stage 1 solver | 20 random scrambles: solver output leads to cross completion |
| Stage 2 solver | 20 states with cross done: solver output leads to corner completion, cross undisturbed |
| Stage 3 solver | 20 states with F2L done: solver output solves middle edges, F2L undisturbed |
| Stages 4–7 | Same pattern — each stage correct, all prior stages undisturbed |
| Full solve | 20 fully scrambled cubes: run stages 1–7 in sequence, assert fully solved |

### 7.2 Hand-Constructed Test States

Build these by applying known move sequences to the solved state:

| State | How to construct |
|-------|-----------------|
| White cross done | Apply `U R F L B D` × n scramble, then run stage 1 solver, verify |
| F2L done | Continue from white cross state through stages 2–3 |
| Each stage boundary | Run the solver stage-by-stage; capture the intermediate state |

Do not construct test states by hand-editing the facelet array (too error-prone). Construct them by applying valid move sequences.

---

## Part 8 — Build Order Summary

```
Week 1
──────
Day 1:  Part 1  — Facelet array, color enum, solved constant, move enum
Day 1:  Part 2  — Permutation tables for U, D, R, L, F, B (hand-traced)
Day 1:  Part 2  — Derive Ui, U2, etc. by composition; applyMove function
Day 2:  Part 2  — Verify all 18 tables pass bijection and round-trip tests
Day 2:  Part 3  — PieceView: corner extraction (positions + orientations)
Day 3:  Part 3  — PieceView: edge extraction; verify on solved + R/F/U states
Day 3:  Part 4  — Validator: all 4 checks; unit tests for each
Day 4:  Part 5  — StageDetector: all 7 completion conditions; boundary tests
Day 4:  Part 6  — Stage 1: White Cross BFS; test 20 scrambles
Day 5:  Part 6  — Stage 2: White Corners procedural; test
Day 5:  Part 6  — Stage 3: Middle Edges procedural; test

Week 2
──────
Day 6:  Part 6  — Stage 4: Yellow Cross case lookup; test
Day 6:  Part 6  — Stage 5: Orient Corners sune loop; test
Day 7:  Part 6  — Stage 6: Permute Corners A-perm; test
Day 7:  Part 6  — Stage 7: Permute Edges U-perm; test
Day 7:  Part 7  — Full integration test: 20 scrambles solved end-to-end
Day 8+: Flutter UI (separate from this plan)
```

---

## Appendix A — Algorithm Reference Card

All algorithms used in the solver, in standard notation. These are the exact move sequences your solver will emit as Steps.

| Stage | Name | Algorithm |
|-------|------|-----------|
| 4 | Yellow cross | `F R U Ri Ui Fi` |
| 5 | Sune | `R U Ri U R U U Ri` |
| 6 | A-perm | `R U Ri Ui Ri F R R Ui Ri Ui R U Ri Fi` |
| 7 | U-perm A (CCW cycle) | `R Ui R U R U R Ui Ri Ui R R` |
| 7 | U-perm B (CW cycle) | `R R U R U Ri Ui Ri Ui Ri U Ri` |
| 2 | Right-hand insert | `R Di Ri` (or full: `R Di Ri Di R Di Di Ri`) |
| 2 | Left-hand insert | `Li D L` |
| 3 | Right-edge insert | `U R Ui Ri Ui Fi U F` |
| 3 | Left-edge insert | `Ui Li U L U F Ui Fi` |

> Verify each algorithm yourself on a physical cube before hardcoding it. Notation errors in algorithm tables cause silent solver bugs that are painful to debug.

---

## Appendix B — Notation Reference

| Symbol | Meaning |
|--------|---------|
| `U` | Up face clockwise (looking from above) |
| `Ui` | Up face counter-clockwise |
| `U2` | Up face 180° |
| `D` | Down face clockwise (looking from below) |
| `R` | Right face clockwise (looking at the right face) |
| `L` | Left face clockwise (looking at the left face) |
| `F` | Front face clockwise (looking at the front) |
| `B` | Back face clockwise (looking at the back) |
| `i` suffix | Inverse (counter-clockwise) |
| `2` suffix | 180° turn |
