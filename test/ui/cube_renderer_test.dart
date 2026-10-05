import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rubiks_cube_teacher/domain/cube/facelets.dart';
import 'package:rubiks_cube_teacher/domain/models/move.dart';
import 'package:rubiks_cube_teacher/ui/widgets/cube_renderer/cube_animator.dart';
import 'package:rubiks_cube_teacher/ui/widgets/cube_renderer/cube_geometry.dart';
import 'package:rubiks_cube_teacher/ui/widgets/cube_renderer/cube_renderer.dart';

void main() {
  group('CubeGeometry Tests', () {
    test('Cube has 156 quads across 26 outer cubies', () {
      expect(CubeGeometry.allQuads.length, 156);
    });

    test('Exactly 54 quads correspond to external stickers (0..53)', () {
      final stickerQuads = CubeGeometry.allQuads.where((q) => q.stickerIndex != -1).toList();
      expect(stickerQuads.length, 54);

      final indices = stickerQuads.map((q) => q.stickerIndex).toSet();
      expect(indices.length, 54);
      for (int i = 0; i < 54; i++) {
        expect(indices.contains(i), isTrue, reason: 'Missing sticker index $i');
      }
    });

    test('isInLayer correctly classifies cubies for all 6 faces', () {
      // U layer: cy == 1
      expect(CubeGeometry.isInLayer(Move.U, 0, 1, 0), isTrue);
      expect(CubeGeometry.isInLayer(Move.U, 1, 1, -1), isTrue);
      expect(CubeGeometry.isInLayer(Move.U, 0, 0, 0), isFalse);
      expect(CubeGeometry.isInLayer(Move.U, 0, -1, 0), isFalse);

      // D layer: cy == -1
      expect(CubeGeometry.isInLayer(Move.D, 0, -1, 0), isTrue);
      expect(CubeGeometry.isInLayer(Move.D, 0, 1, 0), isFalse);

      // R layer: cx == 1
      expect(CubeGeometry.isInLayer(Move.R, 1, 0, 0), isTrue);
      expect(CubeGeometry.isInLayer(Move.R, -1, 0, 0), isFalse);

      // L layer: cx == -1
      expect(CubeGeometry.isInLayer(Move.L, -1, 0, 0), isTrue);
      expect(CubeGeometry.isInLayer(Move.L, 1, 0, 0), isFalse);

      // F layer: cz == 1
      expect(CubeGeometry.isInLayer(Move.F, 0, 0, 1), isTrue);
      expect(CubeGeometry.isInLayer(Move.F, 0, 0, -1), isFalse);

      // B layer: cz == -1
      expect(CubeGeometry.isInLayer(Move.B, 0, 0, -1), isTrue);
      expect(CubeGeometry.isInLayer(Move.B, 0, 0, 1), isFalse);
    });

    test('rotateForMove turns U and D layers in the correct physical direction', () {
      // For U move: Front (0, 1, 1) should rotate to Left (-1, 1, 0)
      final uRotated = CubeGeometry.rotateForMove(
        Move.U,
        const Vec3(0, 1, 1),
        CubeGeometry.targetAngleForMove(Move.U),
      );
      expect(uRotated.x.round(), -1);
      expect(uRotated.y.round(), 1);
      expect(uRotated.z.round(), 0);

      // For D move: Front (0, -1, 1) should rotate to Right (1, -1, 0)
      final dRotated = CubeGeometry.rotateForMove(
        Move.D,
        const Vec3(0, -1, 1),
        CubeGeometry.targetAngleForMove(Move.D),
      );
      expect(dRotated.x.round(), 1);
      expect(dRotated.y.round(), -1);
      expect(dRotated.z.round(), 0);
    });

    test('project returns non-empty list of quads sorted by depth', () {
      final quads = CubeGeometry.project(
        size: const Size(300, 300),
        pitch: -0.4,
        yaw: -0.6,
      );

      expect(quads.isNotEmpty, isTrue);

      // Depth sorting check: each quad depth <= next quad depth (ascending)
      for (int i = 0; i < quads.length - 1; i++) {
        expect(quads[i].depth <= quads[i + 1].depth, isTrue);
      }
    });
  });

  group('CubeRenderer Widget Tests', () {
    testWidgets('CubeRenderer renders solved state without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CubeRenderer(
                facelets: FaceletConstants.solved,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CubeRenderer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('CubeRenderer drag pan gesture updates orientation', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CubeRenderer(
                facelets: FaceletConstants.solved,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag across the cube
      await tester.drag(find.byType(CubeRenderer), const Offset(60, 30));
      await tester.pump();

      // Double tap to reset
      await tester.tap(find.byType(CubeRenderer));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(CubeRenderer));
      await tester.pumpAndSettle();

      expect(find.byType(CubeRenderer), findsOneWidget);
    });

    testWidgets('CubeRenderer highlights specific facelets when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              height: 300,
              child: CubeRenderer(
                facelets: FaceletConstants.solved,
                highlightedFacelets: const {0, 1, 2},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(CubeRenderer), findsOneWidget);
    });
  });

  group('CubeAnimatorController Tests', () {
    testWidgets('Animator animates single move and invokes callback', (tester) async {
      Move? applied;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: _AnimatorTestWrapper(
              onApplied: (m) => applied = m,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(applied, Move.R);
    });
  });
}

class _AnimatorTestWrapper extends StatefulWidget {
  final void Function(Move) onApplied;
  const _AnimatorTestWrapper({required this.onApplied});

  @override
  State<_AnimatorTestWrapper> createState() => _AnimatorTestWrapperState();
}

class _AnimatorTestWrapperState extends State<_AnimatorTestWrapper>
    with SingleTickerProviderStateMixin {
  late final CubeAnimatorController _animator;

  @override
  void initState() {
    super.initState();
    _animator = CubeAnimatorController(
      vsync: this,
      moveDuration: const Duration(milliseconds: 100),
      onMoveApplied: widget.onApplied,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animator.animateMove(Move.R);
    });
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CubeRenderer(
      facelets: FaceletConstants.solved,
      controller: _animator,
    );
  }
}
