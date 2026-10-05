import '../cube/facelets.dart';
import '../cube/move_applier.dart';
import '../cube/piece_view.dart';
import '../models/move.dart';
import '../models/step.dart';

class EdgeSolver {
  /// Solves the 4 middle-layer edges: FR (8), FL (9), BL (10), BR (11).
  /// Preserves the solved U layer (white cross and corners).
  static List<Step> solve(Facelets initial) {
    Facelets current = initial;
    final steps = <Step>[];

    const edgeNames = ['Front-Right', 'Front-Left', 'Back-Left', 'Back-Right'];

    for (int target = 8; target < 12; target++) {
      if (_isEdgeSolved(current, target)) continue;

      final edgeMoves = <Move>[];

      // 1. If edge is stuck in a middle slot (8..11), pop it out to D
      int currentSlot = _findEdgeSlot(current, target);
      if (currentSlot >= 8 && currentSlot <= 11) {
        final popMoves = _insertAlgorithm(currentSlot);
        edgeMoves.addAll(popMoves);
        current = MoveApplier.applyAll(current, popMoves);
      }

      // 2. Try D rotations and test inserting into target slot
      bool solved = false;
      const dRotations = [
        <Move>[],
        [Move.D],
        [Move.D2],
        [Move.Di],
      ];

      for (final dRot in dRotations) {
        final testState = MoveApplier.applyAll(current, dRot);
        // Try direct insert
        final insert = _insertAlgorithm(target);
        final candidate = MoveApplier.applyAll(testState, insert);
        if (_isEdgeSolved(candidate, target)) {
          edgeMoves.addAll(dRot);
          edgeMoves.addAll(insert);
          current = candidate;
          solved = true;
          break;
        }

        // Try mirror insert if applicable
        final mirror = _mirrorInsertAlgorithm(target);
        final candidateMirror = MoveApplier.applyAll(testState, mirror);
        if (_isEdgeSolved(candidateMirror, target)) {
          edgeMoves.addAll(dRot);
          edgeMoves.addAll(mirror);
          current = candidateMirror;
          solved = true;
          break;
        }
      }

      if (!solved) {
        throw StateError('Edge $target could not be placed in slot. Check cube state.');
      }

      if (edgeMoves.isNotEmpty) {
        steps.add(Step(
          description: 'Insert the ${edgeNames[target - 8]} middle edge.',
          moves: edgeMoves,
          notation: edgeMoves.map((m) => m.notation).join(' '),
        ));
      }
    }

    return steps;
  }

  static bool _isEdgeSolved(Facelets f, int slot) {
    final view = PieceView.from(f);
    return view.edges[slot].position == slot && view.edges[slot].orientation == 0;
  }

  static int _findEdgeSlot(Facelets f, int targetPiece) {
    final view = PieceView.from(f);
    for (int i = 0; i < 12; i++) {
      if (view.edges[i].position == targetPiece) return i;
    }
    return -1;
  }

  // Right insert algorithms (insert from D into slot 8, 9, 10, 11)
  static List<Move> _insertAlgorithm(int slot) {
    switch (slot) {
      case 8: // FR
        return const [Move.Di, Move.Ri, Move.D, Move.R, Move.D, Move.F, Move.Di, Move.Fi];
      case 9: // FL
        return const [Move.D, Move.L, Move.Di, Move.Li, Move.Di, Move.Fi, Move.D, Move.F];
      case 10: // BL
        return const [Move.Di, Move.Li, Move.D, Move.L, Move.D, Move.B, Move.Di, Move.Bi];
      case 11: // BR
        return const [Move.D, Move.R, Move.Di, Move.Ri, Move.Di, Move.Bi, Move.D, Move.B];
      default:
        return const [];
    }
  }

  // Left mirror insert algorithms
  static List<Move> _mirrorInsertAlgorithm(int slot) {
    switch (slot) {
      case 8: // FR
        return const [Move.D, Move.F, Move.Di, Move.Fi, Move.Di, Move.Ri, Move.D, Move.R];
      case 9: // FL
        return const [Move.Di, Move.Fi, Move.D, Move.F, Move.D, Move.L, Move.Di, Move.Li];
      case 10: // BL
        return const [Move.D, Move.B, Move.Di, Move.Bi, Move.Di, Move.Li, Move.D, Move.L];
      case 11: // BR
        return const [Move.Di, Move.Bi, Move.D, Move.B, Move.D, Move.R, Move.Di, Move.Ri];
      default:
        return const [];
    }
  }
}
