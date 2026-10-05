import '../models/move.dart';
import 'facelets.dart';

class MoveApplier {
  /// Pure function: returns a new 54-element array with [move] applied.
  /// Does not mutate the input array.
  static Facelets apply(Facelets facelets, Move move) {
    assert(facelets.length == 54);
    final perm = move.permutationTable;
    final result = List<int>.filled(54, 0);
    for (int i = 0; i < 54; i++) {
      result[i] = facelets[perm[i]];
    }
    return result;
  }

  /// Pure function: applies an ordered sequence of moves.
  static Facelets applyAll(Facelets facelets, Iterable<Move> moves) {
    Facelets current = facelets;
    for (final move in moves) {
      current = apply(current, move);
    }
    return current;
  }
}
