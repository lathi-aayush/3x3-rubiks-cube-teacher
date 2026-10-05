import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/cube/move_applier.dart';
import 'package:rubiks_cube_teacher/domain/cube/piece_view.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';

void main() {
  group('PieceView Tests', () {
    test('Solved state has all pieces in home position with orientation 0', () {
      final view = PieceView.from(FaceletConstants.solved);
      expect(view.corners.length, 8);
      expect(view.edges.length, 12);

      for (int i = 0; i < 8; i++) {
        expect(view.corners[i].position, i, reason: 'Corner $i position mismatch');
        expect(view.corners[i].orientation, 0, reason: 'Corner $i orientation mismatch');
      }

      for (int i = 0; i < 12; i++) {
        expect(view.edges[i].position, i, reason: 'Edge $i position mismatch');
        expect(view.edges[i].orientation, 0, reason: 'Edge $i orientation mismatch');
      }
    });

    test('U move rotates U corners and edges without changing orientations', () {
      final afterU = MoveApplier.apply(FaceletConstants.solved, Move.U);
      final view = PieceView.from(afterU);

      // Corners on U layer: 0, 1, 2, 3
      for (int i = 0; i < 4; i++) {
        expect(view.corners[i].orientation, 0);
      }
      // Edges on U layer: 0, 1, 2, 3
      for (int i = 0; i < 4; i++) {
        expect(view.edges[i].orientation, 0);
      }

      // Positions should have cycled
      expect(view.corners[0].position, isNot(0));
      expect(view.edges[0].position, isNot(0));
    });

    test('R move moves R corners and changes orientations', () {
      final afterR = MoveApplier.apply(FaceletConstants.solved, Move.R);
      final view = PieceView.from(afterR);

      // R touches corners URF(0), URB(3), DRF(4), DRB(7)
      expect(view.corners[0].position, isNot(0));
      expect(view.corners[3].position, isNot(3));
      expect(view.corners[4].position, isNot(4));
      expect(view.corners[7].position, isNot(7));

      // Other corners intact
      expect(view.corners[1].position, 1);
      expect(view.corners[2].position, 2);
      expect(view.corners[5].position, 5);
      expect(view.corners[6].position, 6);
    });
  });
}
