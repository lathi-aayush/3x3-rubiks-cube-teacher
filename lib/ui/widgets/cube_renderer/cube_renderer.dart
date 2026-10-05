import 'package:flutter/material.dart';
import '../../../domain/cube/facelets.dart';
import '../../theme/app_theme.dart';
import 'cube_animator.dart';
import 'cube_geometry.dart';

/// Interactive 3D Rubik's Cube widget rendered with CustomPainter.
/// Supports smooth layer animations, orbit drag gesture, depth sorting,
/// tactile shading, and piece highlighting.
class CubeRenderer extends StatefulWidget {
  final Facelets facelets;
  final CubeAnimatorController? controller;
  final Set<int>? highlightedFacelets;
  final double initialPitch;
  final double initialYaw;
  final bool interactive;
  final VoidCallback? onTap;

  const CubeRenderer({
    super.key,
    required this.facelets,
    this.controller,
    this.highlightedFacelets,
    this.initialPitch = 0.42,
    this.initialYaw = 0.65,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<CubeRenderer> createState() => _CubeRendererState();
}

class _CubeRendererState extends State<CubeRenderer> {
  late double _pitch;
  late double _yaw;

  @override
  void initState() {
    super.initState();
    _pitch = widget.initialPitch;
    _yaw = widget.initialYaw;
    widget.controller?.addListener(_onAnimatorUpdate);
  }

  @override
  void didUpdateWidget(covariant CubeRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_onAnimatorUpdate);
      widget.controller?.addListener(_onAnimatorUpdate);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_onAnimatorUpdate);
    super.dispose();
  }

  void _onAnimatorUpdate() {
    if (mounted) setState(() {});
  }

  void _resetOrientation() {
    setState(() {
      _pitch = widget.initialPitch;
      _yaw = widget.initialYaw;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "3D Rubik's Cube View",
      hint: widget.interactive ? 'Drag to rotate viewpoint. Double tap to reset view.' : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onDoubleTap: widget.interactive ? _resetOrientation : null,
        onPanUpdate: widget.interactive
            ? (details) {
                setState(() {
                  _pitch = (_pitch + details.delta.dy * 0.009).clamp(-1.45, 1.45);
                  _yaw = (_yaw - details.delta.dx * 0.009);
                });
              }
            : null,
        child: CustomPaint(
          size: Size.infinite,
          painter: _CubePainter(
            facelets: widget.facelets,
            pitch: _pitch,
            yaw: _yaw,
            activeMove: widget.controller?.activeMove,
            moveProgress: widget.controller?.progress ?? 0.0,
            highlightedFacelets: widget.highlightedFacelets,
          ),
        ),
      ),
    );
  }
}

class _CubePainter extends CustomPainter {
  final Facelets facelets;
  final double pitch;
  final double yaw;
  final dynamic activeMove;
  final double moveProgress;
  final Set<int>? highlightedFacelets;

  _CubePainter({
    required this.facelets,
    required this.pitch,
    required this.yaw,
    required this.activeMove,
    required this.moveProgress,
    this.highlightedFacelets,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final quads = CubeGeometry.project(
      size: size,
      pitch: pitch,
      yaw: yaw,
      activeMove: activeMove,
      moveProgress: moveProgress,
    );

    final plasticPaint = Paint()..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = const Color(0xFF0F0F12);

    final stickerPaint = Paint()..style = PaintingStyle.fill;
    final highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeJoin = StrokeJoin.round
      ..color = AppTheme.cubeYellow;

    for (final quad in quads) {
      final polyPath = Path();
      polyPath.moveTo(quad.points[0].dx, quad.points[0].dy);
      polyPath.lineTo(quad.points[1].dx, quad.points[1].dy);
      polyPath.lineTo(quad.points[2].dx, quad.points[2].dy);
      polyPath.lineTo(quad.points[3].dx, quad.points[3].dy);
      polyPath.close();

      // 1. Draw plastic base of the cubie face
      final baseShade = (quad.shade * 0.9).clamp(0.5, 1.0);
      plasticPaint.color = Color.fromRGBO(
        (28 * baseShade).round(),
        (28 * baseShade).round(),
        (32 * baseShade).round(),
        1.0,
      );
      canvas.drawPath(polyPath, plasticPaint);
      canvas.drawPath(polyPath, edgePaint);

      // 2. Draw external sticker if this quad corresponds to a facelet
      if (quad.stickerIndex >= 0 && quad.stickerIndex < facelets.length) {
        final colorCode = facelets[quad.stickerIndex];
        final baseColor = AppTheme.cubeColor(colorCode);

        // Apply 3D light shading
        final r = (baseColor.red * quad.shade).clamp(0, 255).round();
        final g = (baseColor.green * quad.shade).clamp(0, 255).round();
        final b = (baseColor.blue * quad.shade).clamp(0, 255).round();
        stickerPaint.color = Color.fromRGBO(r, g, b, 1.0);

        // Inset points slightly towards centroid (84% of quad) for rounded sticker effect
        final cx = (quad.points[0].dx + quad.points[1].dx + quad.points[2].dx + quad.points[3].dx) / 4.0;
        final cy = (quad.points[0].dy + quad.points[1].dy + quad.points[2].dy + quad.points[3].dy) / 4.0;
        const stickerInset = 0.85;

        Offset insetPoint(Offset p) => Offset(
              cx + (p.dx - cx) * stickerInset,
              cy + (p.dy - cy) * stickerInset,
            );

        final s0 = insetPoint(quad.points[0]);
        final s1 = insetPoint(quad.points[1]);
        final s2 = insetPoint(quad.points[2]);
        final s3 = insetPoint(quad.points[3]);

        final stickerPath = Path()
          ..moveTo(s0.dx, s0.dy)
          ..lineTo(s1.dx, s1.dy)
          ..lineTo(s2.dx, s2.dy)
          ..lineTo(s3.dx, s3.dy)
          ..close();

        canvas.drawPath(stickerPath, stickerPaint);

        // 3. Highlighted border if requested
        if (highlightedFacelets != null &&
            highlightedFacelets!.contains(quad.stickerIndex)) {
          canvas.drawPath(stickerPath, highlightPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CubePainter oldDelegate) {
    return oldDelegate.facelets != facelets ||
        oldDelegate.pitch != pitch ||
        oldDelegate.yaw != yaw ||
        oldDelegate.activeMove != activeMove ||
        oldDelegate.moveProgress != moveProgress ||
        oldDelegate.highlightedFacelets != highlightedFacelets;
  }
}
