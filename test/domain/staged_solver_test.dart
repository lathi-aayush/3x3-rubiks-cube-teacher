import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/cube/move_applier.dart';
import 'package:rubiks_cube_teacher/domain/detection/stage_detector.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';
import 'package:rubiks_cube_teacher/domain/models/stage.dart';
import 'package:rubiks_cube_teacher/domain/solver/cross_solver.dart';
import 'package:rubiks_cube_teacher/domain/solver/staged_solver.dart';

void main() {
  group('StagedSolver Tests', () {
    test('Solved cube returns empty step list for any stage', () {
      final solved = FaceletConstants.solved;
      for (final stage in Stage.values) {
        final steps = StagedSolver.solveSync(solved, stage);
        expect(steps, isEmpty, reason: 'Stage $stage returned non-empty steps on solved cube');
      }
    });

    test('CrossSolver solves cross from known scrambles', () {
      final testScrambles = [
        [Move.R, Move.F, Move.L],
        [Move.U, Move.R2, Move.F2],
        [Move.B, Move.D, Move.R, Move.F],
      ];

      for (int i = 0; i < testScrambles.length; i++) {
        final scrambled = MoveApplier.applyAll(FaceletConstants.solved, testScrambles[i]);
        expect(StageDetector.isComplete(scrambled, Stage.whiteCross), isFalse);

        final steps = CrossSolver.solve(scrambled);
        expect(steps, isNotEmpty);

        var current = scrambled;
        for (final step in steps) {
          current = MoveApplier.applyAll(current, step.moves);
        }

        expect(StageDetector.isComplete(current, Stage.whiteCross), isTrue,
            reason: 'Scramble $i was not solved by CrossSolver');
      }
    });

    test('Full staged solve end-to-end for 5 scrambles', () {
      final scrambles = [
        [Move.R, Move.U, Move.Ri, Move.Ui],
        [Move.F, Move.R, Move.U, Move.Ri, Move.Ui, Move.Fi],
        [Move.R, Move.U, Move.R2, Move.U, Move.R],
        [Move.L, Move.F, Move.L2, Move.B],
        [Move.D, Move.R, Move.D2, Move.F2, Move.L],
      ];

      for (int s = 0; s < scrambles.length; s++) {
        var current = MoveApplier.applyAll(FaceletConstants.solved, scrambles[s]);

        // Progressively solve through stages
        for (final stage in Stage.values) {
          if (!StageDetector.isComplete(current, stage)) {
            final steps = StagedSolver.solveSync(current, stage);
            for (final step in steps) {
              current = MoveApplier.applyAll(current, step.moves);
            }
          }
          expect(StageDetector.isComplete(current, stage), isTrue,
              reason: 'Scramble $s failed to complete stage $stage');
        }

        expect(StageDetector.detect(current), isNull,
            reason: 'Scramble $s was not fully solved');
      }
    });
  });
}
