import '../cube/facelets.dart';
import '../cube/move_applier.dart';
import '../cube/piece_view.dart';
import '../models/move.dart';
import '../models/step.dart';

class CrossSolver {
  /// Solves the white cross (edges 0, 1, 2, 3 in home position, orientation 0).
  /// Uses BFS over the 4-edge reduced state, with single-edge fallback if needed.
  static List<Step> solve(Facelets facelets) {
    if (_isCrossSolved(facelets)) {
      return const [];
    }

    final moves = _solveCrossMoves(facelets);
    if (moves.isEmpty) return const [];

    final notation = moves.map((m) => m.notation).join(' ');
    return [
      Step(
        description: 'Solve the white cross matching adjacent center colors.',
        moves: moves,
        notation: notation,
      ),
    ];
  }

  static bool _isCrossSolved(Facelets f) {
    final view = PieceView.from(f);
    for (int i = 0; i < 4; i++) {
      if (view.edges[i].position != i || view.edges[i].orientation != 0) {
        return false;
      }
    }
    return true;
  }

  static List<Move> _solveCrossMoves(Facelets initial) {
    if (_isCrossSolved(initial)) return [];

    // Attempt direct BFS up to depth 6
    final direct = _bfsCross(initial, maxDepth: 6);
    if (direct != null) return direct;

    // Fallback: solve cross edge by edge (ponytail: robust fallback for deep scrambles)
    Facelets current = initial;
    final allMoves = <Move>[];

    for (int targetEdge = 0; targetEdge < 4; targetEdge++) {
      final stepMoves = _solveSingleEdge(current, targetEdge);
      allMoves.addAll(stepMoves);
      current = MoveApplier.applyAll(current, stepMoves);
    }

    return allMoves;
  }

  static List<Move>? _bfsCross(Facelets start, {required int maxDepth}) {
    final startKey = _crossKey(start);
    if (startKey == _solvedKey) return [];

    final queue = <_BfsNode>[];
    queue.add(_BfsNode(start, [], -1));

    final visited = <int>{startKey};

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      if (node.moves.length >= maxDepth) continue;

      for (final move in Move.values) {
        // Prune same-face consecutive moves
        if (_sameFace(move, node.lastMove)) continue;

        final nextFacelets = MoveApplier.apply(node.facelets, move);
        final nextKey = _crossKey(nextFacelets);

        final nextMoves = [...node.moves, move];
        if (nextKey == _solvedKey) {
          return nextMoves;
        }

        if (visited.add(nextKey)) {
          queue.add(_BfsNode(nextFacelets, nextMoves, move.index ~/ 3));
        }
      }
    }

    return null;
  }

  static List<Move> _solveSingleEdge(Facelets state, int targetEdge) {
    final startKey = _edgeKey(state, targetEdge);
    final targetKey = targetEdge << 1; // position = targetEdge, orientation = 0

    if (startKey == targetKey) return [];

    final queue = <_BfsNode>[];
    queue.add(_BfsNode(state, [], -1));
    final visited = <int>{startKey};

    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      if (node.moves.length >= 6) continue;

      for (final move in Move.values) {
        if (_sameFace(move, node.lastMove)) continue;

        final nextFacelets = MoveApplier.apply(node.facelets, move);

        // Ensure earlier solved edges are not disturbed
        bool earlierIntact = true;
        final view = PieceView.from(nextFacelets);
        for (int e = 0; e < targetEdge; e++) {
          if (view.edges[e].position != e || view.edges[e].orientation != 0) {
            earlierIntact = false;
            break;
          }
        }
        if (!earlierIntact) continue;

        final nextMoves = [...node.moves, move];
        final currentKey = _edgeKey(nextFacelets, targetEdge);
        if (currentKey == targetKey) {
          return nextMoves;
        }

        if (visited.add(currentKey)) {
          queue.add(_BfsNode(nextFacelets, nextMoves, move.index ~/ 3));
        }
      }
    }

    return [];
  }

  static bool _sameFace(Move a, int lastFace) {
    if (lastFace < 0) return false;
    return (a.index ~/ 3) == lastFace;
  }

  static int _crossKey(Facelets f) {
    final view = PieceView.from(f);
    int key = 0;
    for (int i = 0; i < 4; i++) {
      int pos = 0;
      int ori = 0;
      for (int slot = 0; slot < 12; slot++) {
        if (view.edges[slot].position == i) {
          pos = slot;
          ori = view.edges[slot].orientation;
          break;
        }
      }
      key = (key << 5) | (pos << 1) | ori;
    }
    return key;
  }

  static int _edgeKey(Facelets f, int targetEdge) {
    final view = PieceView.from(f);
    for (int slot = 0; slot < 12; slot++) {
      if (view.edges[slot].position == targetEdge) {
        return (slot << 1) | view.edges[slot].orientation;
      }
    }
    return -1;
  }

  static final int _solvedKey = _calcSolvedKey();

  static int _calcSolvedKey() {
    int key = 0;
    for (int i = 0; i < 4; i++) {
      key = (key << 5) | (i << 1) | 0;
    }
    return key;
  }
}

class _BfsNode {
  final Facelets facelets;
  final List<Move> moves;
  final int lastMove;

  _BfsNode(this.facelets, this.moves, this.lastMove);
}
