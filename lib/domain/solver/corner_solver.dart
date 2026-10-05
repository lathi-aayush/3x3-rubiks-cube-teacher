import '../cube/facelets.dart';
import '../cube/move_applier.dart';
import '../cube/piece_view.dart';
import '../models/move.dart';
import '../models/step.dart';

class CornerSolver {
  /// Solves the 4 white corners (URF=0, ULF=1, ULB=2, URB=3) using the beginner method.
  static List<Step> solve(Facelets initial) {
    Facelets current = initial;
    final steps = <Step>[];

    final cornerNames = ['Up-Right-Front', 'Up-Left-Front', 'Up-Left-Back', 'Up-Right-Back'];

    for (int target = 0; target < 4; target++) {
      if (_isCornerSolved(current, target)) continue;

      final cornerMoves = <Move>[];

      // 1. If target piece is in a U slot (not target), pop it down to D
      int currentSlot = _findCornerSlot(current, target);
      if (currentSlot >= 0 && currentSlot < 4 && currentSlot != target) {
        final popMoves = _slotTrigger(currentSlot);
        cornerMoves.addAll(popMoves);
        current = MoveApplier.applyAll(current, popMoves);
        currentSlot = _findCornerSlot(current, target);
      }

      // 2. Rotate D to align piece under target slot (target + 4)
      final belowSlot = target + 4;
      currentSlot = _findCornerSlot(current, target);
      if (currentSlot >= 4 && currentSlot <= 7 && currentSlot != belowSlot) {
        final alignMoves = _alignDLayer(currentSlot, belowSlot);
        cornerMoves.addAll(alignMoves);
        current = MoveApplier.applyAll(current, alignMoves);
      }

      // 3. Repeat slot trigger until target corner is placed with orientation 0
      int attempts = 0;
      final trigger = _slotTrigger(target);
      while (!_isCornerSolved(current, target) && attempts < 6) {
        cornerMoves.addAll(trigger);
        current = MoveApplier.applyAll(current, trigger);
        attempts++;
      }

      if (cornerMoves.isNotEmpty) {
        steps.add(Step(
          description: 'Place the ${cornerNames[target]} white corner.',
          moves: cornerMoves,
          notation: cornerMoves.map((m) => m.notation).join(' '),
        ));
      }
    }

    return steps;
  }

  static bool _isCornerSolved(Facelets f, int slot) {
    final view = PieceView.from(f);
    return view.corners[slot].position == slot && view.corners[slot].orientation == 0;
  }

  static int _findCornerSlot(Facelets f, int targetPiece) {
    final view = PieceView.from(f);
    for (int i = 0; i < 8; i++) {
      if (view.corners[i].position == targetPiece) return i;
    }
    return -1;
  }

  static List<Move> _slotTrigger(int slot) {
    switch (slot) {
      case 0: // URF
        return const [Move.Ri, Move.Di, Move.R, Move.D];
      case 1: // ULF
        return const [Move.L, Move.D, Move.Li, Move.Di];
      case 2: // ULB
        return const [Move.Li, Move.Di, Move.L, Move.D];
      case 3: // URB
        return const [Move.R, Move.D, Move.Ri, Move.Di];
      default:
        return const [];
    }
  }

  /// Generates D moves to bring a piece from [fromSlot] (4..7) to [toSlot] (4..7)
  static List<Move> _alignDLayer(int fromSlot, int toSlot) {
    // Under D move: 4 -> 7 -> 6 -> 5 -> 4
    const dCycle = [4, 7, 6, 5];
    final fromIdx = dCycle.indexOf(fromSlot);
    final toIdx = dCycle.indexOf(toSlot);
    if (fromIdx == -1 || toIdx == -1) return const [];

    final diff = (toIdx - fromIdx + 4) % 4;

    switch (diff) {
      case 1:
        return const [Move.D];
      case 2:
        return const [Move.D2];
      case 3:
        return const [Move.Di];
      default:
        return const [];
    }
  }
}
