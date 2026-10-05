import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/cube_validator.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/cube/move_applier.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';

void main() {
  group('CubeValidator Tests', () {
    test('Solved state passes validation', () {
      final error = CubeValidator.validate(FaceletConstants.solved);
      expect(error, isNull);
    });

    test('Single moves pass validation', () {
      for (final move in Move.values) {
        final state = MoveApplier.apply(FaceletConstants.solved, move);
        final error = CubeValidator.validate(state);
        expect(error, isNull, reason: 'Single move $move failed validation: $error');
      }
    });

    test('Random legal scrambles all pass validation', () {
      final random = Random(42);
      for (int i = 0; i < 15; i++) {
        var state = FaceletConstants.createSolved();
        for (int m = 0; m < 25; m++) {
          final move = Move.values[random.nextInt(Move.values.length)];
          state = MoveApplier.apply(state, move);
        }
        final error = CubeValidator.validate(state);
        expect(error, isNull, reason: 'Scramble $i was flagged as invalid: $error');
      }
    });

    test('Incorrect color count fails with wrongColorCount', () {
      final bad = FaceletConstants.createSolved();
      bad[0] = bad[9]; // replace a white with red
      final error = CubeValidator.validate(bad);
      expect(error, isNotNull);
      expect(error!.kind, ValidationKind.wrongColorCount);
    });

    test('Single twisted corner fails with twistedCorner', () {
      final bad = FaceletConstants.createSolved();
      // Corner 0 is URF: indices [2, 9, 20]. Twist it:
      final c0 = bad[2];
      final c1 = bad[9];
      final c2 = bad[20];
      bad[2] = c1;
      bad[9] = c2;
      bad[20] = c0;

      final error = CubeValidator.validate(bad);
      expect(error, isNotNull);
      expect(error!.kind, ValidationKind.twistedCorner);
    });

    test('Single flipped edge fails with flippedEdge', () {
      final bad = FaceletConstants.createSolved();
      // Edge 0 is UR: indices [5, 10]. Flip it:
      final e0 = bad[5];
      final e1 = bad[10];
      bad[5] = e1;
      bad[10] = e0;

      final error = CubeValidator.validate(bad);
      expect(error, isNotNull);
      expect(error!.kind, ValidationKind.flippedEdge);
    });

    test('Two swapped edges fail with parityError', () {
      final bad = FaceletConstants.createSolved();
      // Swap edge 0 (UR: [5, 10]) and edge 1 (UF: [1, 19])
      final e0_0 = bad[5];
      final e0_1 = bad[10];
      bad[5] = bad[1];
      bad[10] = bad[19];
      bad[1] = e0_0;
      bad[19] = e0_1;

      final error = CubeValidator.validate(bad);
      expect(error, isNotNull);
      expect(error!.kind, ValidationKind.parityError);
    });
  });
}
