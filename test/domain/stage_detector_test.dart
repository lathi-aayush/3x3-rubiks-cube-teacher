import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/cube/move_applier.dart';
import 'package:rubiks_cube_teacher/domain/detection/stage_detector.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';
import 'package:rubiks_cube_teacher/domain/models/stage.dart';

void main() {
  group('StageDetector Tests', () {
    test('Solved state has all stages complete', () {
      final solved = FaceletConstants.solved;
      for (final stage in Stage.values) {
        expect(StageDetector.isComplete(solved, stage), isTrue,
            reason: 'Stage $stage should be complete on solved state');
      }
      expect(StageDetector.detect(solved), isNull);
    });

    test('Scrambled cross detects Stage.whiteCross', () {
      final scrambled = MoveApplier.apply(FaceletConstants.solved, Move.R);
      expect(StageDetector.isComplete(scrambled, Stage.whiteCross), isFalse);
      expect(StageDetector.detect(scrambled), Stage.whiteCross);
    });

    test('White cross complete but corners broken detects Stage.whiteCorners', () {
      // Displace only corners using a sequence that preserves cross edges:
      // (R Di Ri D) applied 1 time displaces corner URF without disturbing any cross edge
      final state = MoveApplier.applyAll(
        FaceletConstants.solved,
        [Move.R, Move.Di, Move.Ri, Move.D],
      );

      expect(StageDetector.isComplete(state, Stage.whiteCross), isTrue);
      expect(StageDetector.isComplete(state, Stage.whiteCorners), isFalse);
      expect(StageDetector.detect(state), Stage.whiteCorners);
    });
  });
}
