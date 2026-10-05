import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScanOverlay extends StatelessWidget {
  final String faceName;
  final int faceIndex;
  final VoidCallback onCapture;
  final bool isScanning;

  const ScanOverlay({
    super.key,
    required this.faceName,
    required this.faceIndex,
    required this.onCapture,
    this.isScanning = false,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = constraints.maxWidth * 0.78;

        return Stack(
          children: [
            // Dark vignette overlay with square transparent cutout
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.55),
                BlendMode.srcOut,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Center(
                    child: Container(
                      width: boxSize,
                      height: boxSize,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3x3 Grid Outline over the cutout
            Center(
              child: Container(
                width: boxSize,
                height: boxSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primaryLight, width: 2.5),
                ),
                child: CustomPaint(
                  painter: _GridPainter(borderColor: AppTheme.primaryLight.withOpacity(0.6)),
                ),
              ),
            ),

            // Top Guidance Pill
            Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: AppTheme.cubeColor(faceIndex == 0
                              ? 0
                              : faceIndex == 1
                                  ? 4
                                  : faceIndex == 2
                                      ? 2
                                      : faceIndex == 3
                                          ? 1
                                          : faceIndex == 4
                                              ? 5
                                              : 3),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Align Face: $faceName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Shutter Button
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: isScanning ? null : onCapture,
                  child: Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3.5),
                    ),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: isScanning
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              ),
                            )
                          : const Icon(Icons.camera_alt, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GridPainter extends CustomPainter {
  final Color borderColor;

  _GridPainter({required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = 1.5;

    final cellW = size.width / 3.0;
    final cellH = size.height / 3.0;

    // Vertical lines
    canvas.drawLine(Offset(cellW, 0), Offset(cellW, size.height), paint);
    canvas.drawLine(Offset(cellW * 2, 0), Offset(cellW * 2, size.height), paint);

    // Horizontal lines
    canvas.drawLine(Offset(0, cellH), Offset(size.width, cellH), paint);
    canvas.drawLine(Offset(0, cellH * 2), Offset(size.width, cellH * 2), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
