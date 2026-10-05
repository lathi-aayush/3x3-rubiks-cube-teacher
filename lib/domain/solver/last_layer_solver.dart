import '../cube/facelets.dart';
import '../cube/move_applier.dart';
import '../detection/stage_detector.dart';
import '../models/move.dart';
import '../models/stage.dart';
import '../models/step.dart';

class LastLayerSolver {
  /// Solves Stage 4: Yellow Cross
  static List<Step> solveYellowCross(Facelets initial) {
    if (StageDetector.isComplete(initial, Stage.yellowCross)) return const [];

    final isWhiteOnU = initial[4] == 0;
    final alg = isWhiteOnU ? _crossAlgD : _crossAlgU;
    final rots = isWhiteOnU ? _dRotations : _uRotations;

    final moves = _search(initial, Stage.yellowCross, [alg], rots, maxDepth: 4);
    if (moves == null || moves.isEmpty) return const [];

    return [
      Step(
        description: 'Form the yellow cross on the last layer.',
        moves: moves,
        notation: moves.map((m) => m.notation).join(' '),
      ),
    ];
  }

  /// Solves Stage 5: Orient Yellow Corners
  static List<Step> solveOrientCorners(Facelets initial) {
    if (StageDetector.isComplete(initial, Stage.orientCorners)) return const [];

    final isWhiteOnU = initial[4] == 0;
    final sune = isWhiteOnU ? _suneAlgD : _suneAlgU;
    final rots = isWhiteOnU ? _dRotations : _uRotations;

    final moves = _search(initial, Stage.orientCorners, [sune], rots, maxDepth: 4);
    if (moves == null || moves.isEmpty) return const [];

    return [
      Step(
        description: 'Orient all yellow corners to complete the yellow face.',
        moves: moves,
        notation: moves.map((m) => m.notation).join(' '),
      ),
    ];
  }

  /// Solves Stage 6: Permute Yellow Corners
  static List<Step> solvePermuteCorners(Facelets initial) {
    if (StageDetector.isComplete(initial, Stage.permuteCorners)) return const [];

    final isWhiteOnU = initial[4] == 0;
    final aperm = isWhiteOnU ? _apermAlgD : _apermAlgU;
    final rots = isWhiteOnU ? _dRotations : _uRotations;

    final moves = _search(initial, Stage.permuteCorners, [aperm], rots, maxDepth: 3);
    if (moves == null || moves.isEmpty) return const [];

    return [
      Step(
        description: 'Move yellow corners to their correct positions.',
        moves: moves,
        notation: moves.map((m) => m.notation).join(' '),
      ),
    ];
  }

  /// Solves Stage 7: Permute Yellow Edges
  static List<Step> solvePermuteEdges(Facelets initial) {
    if (StageDetector.isComplete(initial, Stage.permuteEdges)) return const [];

    final isWhiteOnU = initial[4] == 0;
    final upermA = isWhiteOnU ? _upermAAlgD : _upermAAlgU;
    final upermB = isWhiteOnU ? _upermBAlgD : _upermBAlgU;
    final rots = isWhiteOnU ? _dRotations : _uRotations;

    // Check simple AUF first
    for (final rot in rots) {
      if (StageDetector.isComplete(MoveApplier.applyAll(initial, rot), Stage.permuteEdges)) {
        return rot.isEmpty
            ? const []
            : [
                Step(
                  description: 'Rotate the last layer to fully solve the cube.',
                  moves: rot,
                  notation: rot.map((m) => m.notation).join(' '),
                ),
              ];
      }
    }

    final moves = _search(initial, Stage.permuteEdges, [upermA, upermB], rots, maxDepth: 3);
    if (moves == null || moves.isEmpty) return const [];

    return [
      Step(
        description: 'Permute remaining edges to fully solve the cube.',
        moves: moves,
        notation: moves.map((m) => m.notation).join(' '),
      ),
    ];
  }

  static List<Move>? _search(
    Facelets start,
    Stage stage,
    List<List<Move>> algs,
    List<List<Move>> rots, {
    required int maxDepth,
  }) {
    if (StageDetector.isComplete(start, stage)) return [];
    final queue = <(Facelets, List<Move>, int)>[(start, [], 0)];
    final visited = <int>{_hash(start)};

    while (queue.isNotEmpty) {
      final (curr, moves, depth) = queue.removeAt(0);
      if (depth >= maxDepth) continue;

      for (final alg in algs) {
        for (final rot in rots) {
          final cand = [...rot, ...alg];
          final next = MoveApplier.applyAll(curr, cand);
          final nextMoves = [...moves, ...cand];

          for (final postRot in rots) {
            final aligned = MoveApplier.applyAll(next, postRot);
            final fullMoves = [...nextMoves, ...postRot];
            if (StageDetector.isComplete(aligned, stage)) {
              return fullMoves;
            }
          }

          final h = _hash(next);
          if (visited.add(h)) {
            queue.add((next, nextMoves, depth + 1));
          }
        }
      }
    }
    return null;
  }

  static int _hash(Facelets f) {
    int h = 0;
    for (int i = 0; i < 54; i++) {
      h = 31 * h + f[i];
    }
    return h;
  }

  // --- Algorithms ---

  // Cross: F L D Li Di Fi (D layer) and F R U Ri Ui Fi (U layer)
  static const _crossAlgD = [Move.F, Move.L, Move.D, Move.Li, Move.Di, Move.Fi];
  static const _crossAlgU = [Move.F, Move.R, Move.U, Move.Ri, Move.Ui, Move.Fi];

  // Sune: L D Li D L D2 Li (D layer) and R U Ri U R U2 Ri (U layer)
  static const _suneAlgD = [Move.L, Move.D, Move.Li, Move.D, Move.L, Move.D2, Move.Li];
  static const _suneAlgU = [Move.R, Move.U, Move.Ri, Move.U, Move.R, Move.U2, Move.Ri];

  // A-perm: L D Li Di Li F L2 Di Li Di L D Li Fi (D layer)
  // Standard A-perm on U: R U Ri Ui Ri F R2 Ui Ri Ui R U Ri Fi
  static const _apermAlgD = [
    Move.L, Move.D, Move.Li, Move.Di, Move.Li, Move.F, Move.L2,
    Move.Di, Move.Li, Move.Di, Move.L, Move.D, Move.Li, Move.Fi
  ];
  static const _apermAlgU = [
    Move.R, Move.U, Move.Ri, Move.Ui, Move.Ri, Move.F, Move.R2,
    Move.Ui, Move.Ri, Move.Ui, Move.R, Move.U, Move.Ri, Move.Fi
  ];

  // U-perm A: L Di L D L D L Di Li Di L2 (D layer)
  static const _upermAAlgD = [
    Move.L, Move.Di, Move.L, Move.D, Move.L, Move.D, Move.L, Move.Di, Move.Li, Move.Di, Move.L2
  ];
  static const _upermAAlgU = [
    Move.R, Move.Ui, Move.R, Move.U, Move.R, Move.U, Move.R, Move.Ui, Move.Ri, Move.Ui, Move.R2
  ];

  // U-perm B: L2 D L D Li Di Li Di Li D Li (D layer)
  static const _upermBAlgD = [
    Move.L2, Move.D, Move.L, Move.D, Move.Li, Move.Di, Move.Li, Move.Di, Move.Li, Move.D, Move.Li
  ];
  static const _upermBAlgU = [
    Move.R2, Move.U, Move.R, Move.U, Move.Ri, Move.Ui, Move.Ri, Move.Ui, Move.Ri, Move.U, Move.Ri
  ];

  static const _dRotations = [
    <Move>[],
    [Move.D],
    [Move.D2],
    [Move.Di],
  ];

  static const _uRotations = [
    <Move>[],
    [Move.U],
    [Move.U2],
    [Move.Ui],
  ];
}
