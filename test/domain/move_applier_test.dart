import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/cube/move_applier.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';

void main() {
  group('MoveApplier & MoveTables Tests', () {
    test('Solved state constant is valid', () {
      expect(FaceletConstants.solved.length, 54);
      final counts = List<int>.filled(6, 0);
      for (final c in FaceletConstants.solved) {
        counts[c]++;
      }
      for (final cnt in counts) {
        expect(cnt, 9);
      }
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 0), 0); // U (White)
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 1), 4); // R (Red)
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 2), 2); // F (Green)
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 3), 1); // D (Yellow)
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 4), 5); // L (Orange)
      expect(FaceletConstants.centerColor(FaceletConstants.solved, 5), 3); // B (Blue)
    });

    test('All 18 permutation tables are bijections', () {
      for (final move in Move.values) {
        final table = move.permutationTable;
        expect(table.length, 54);
        final seen = <int>{};
        for (final idx in table) {
          expect(idx >= 0 && idx < 54, isTrue);
          seen.add(idx);
        }
        expect(seen.length, 54, reason: 'Move $move table is not a bijection');
      }
    });

    test('Each base move 4 times equals identity', () {
      final baseMoves = [Move.U, Move.D, Move.R, Move.L, Move.F, Move.B];
      final solved = FaceletConstants.createSolved();

      for (final move in baseMoves) {
        var state = solved;
        for (int i = 0; i < 4; i++) {
          state = MoveApplier.apply(state, move);
        }
        expect(state, solved, reason: '4x $move did not return to solved state');
      }
    });

    test('Each move and its inverse cancel out', () {
      final solved = FaceletConstants.createSolved();
      for (final move in Move.values) {
        final afterMove = MoveApplier.apply(solved, move);
        final afterInv = MoveApplier.apply(afterMove, move.inverse);
        expect(afterInv, solved, reason: '$move then ${move.inverse} failed');
      }
    });

    test('2x half-turn equals identity', () {
      final halfTurns = [Move.U2, Move.D2, Move.R2, Move.L2, Move.F2, Move.B2];
      final solved = FaceletConstants.createSolved();
      for (final move in halfTurns) {
        final state = MoveApplier.applyAll(solved, [move, move]);
        expect(state, solved, reason: '2x $move failed');
      }
    });
  });
}
