import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/cube/face_orientation.dart';
import '../../providers/scan_provider.dart';
import '../../providers/teaching_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/color_picker_sheet.dart';
import '../widgets/face_grid.dart';

class CorrectionScreen extends StatefulWidget {
  const CorrectionScreen({super.key});

  @override
  State<CorrectionScreen> createState() => _CorrectionScreenState();
}

class _CorrectionScreenState extends State<CorrectionScreen> {
  int _selectedFace = 0; // 0..5: U, R, F, D, L, B

  static const _faceNames = [
    'Up (White)',
    'Right (Red)',
    'Front (Green)',
    'Down (Yellow)',
    'Left (Orange)',
    'Back (Blue)'
  ];

  void _onStickerTapped(int indexWithinFace) {
    if (indexWithinFace == 4) {
      // Center sticker is fixed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Center sticker cannot be modified — it defines face identity.'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final globalIndex = _selectedFace * 9 + indexWithinFace;
    final scanProv = context.read<ScanProvider>();
    final currentColor = scanProv.facelets[globalIndex];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ColorPickerSheet(
        currentColor: currentColor,
        onColorSelected: (newColor) {
          scanProv.updateFacelet(globalIndex, newColor);
        },
      ),
    );
  }

  void _showFullNetModal(BuildContext context, ScanProvider scanProv) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceDark,
          title: Row(
            children: const [
              Icon(Icons.view_in_ar_rounded, color: AppTheme.primaryLight),
              SizedBox(width: 10),
              Text('Unfolded Cube Net'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Tap any face to inspect or correct its stickers:',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                _buildCubeNet(ctx, scanProv),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCubeNet(BuildContext ctx, ScanProvider scanProv) {
    const miniSize = 58.0;

    Widget miniFace(int faceIndex) {
      final isCurrent = _selectedFace == faceIndex;
      final faceColors = scanProv.facelets.sublist(faceIndex * 9, faceIndex * 9 + 9);

      return GestureDetector(
        onTap: () {
          setState(() => _selectedFace = faceIndex);
          Navigator.of(ctx).pop();
        },
        child: Container(
          width: miniSize,
          height: miniSize,
          decoration: BoxDecoration(
            border: Border.all(
              color: isCurrent ? AppTheme.primaryLight : AppTheme.borderDark,
              width: isCurrent ? 2.5 : 1.0,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: FaceGrid(faceColors: faceColors),
        ),
      );
    }

    final emptySpace = const SizedBox(width: miniSize, height: miniSize);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top row: U (face 0)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [emptySpace, miniFace(0), emptySpace, emptySpace],
        ),
        const SizedBox(height: 4),
        // Middle row: L (4), F (2), R (1), B (5)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [miniFace(4), miniFace(2), miniFace(1), miniFace(5)],
        ),
        const SizedBox(height: 4),
        // Bottom row: D (3)
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [emptySpace, miniFace(3), emptySpace, emptySpace],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scanProv = context.watch<ScanProvider>();
    final facelets = scanProv.facelets;
    final validationError = scanProv.validationError;
    final isValid = scanProv.isScanComplete && validationError == null;

    final currentFaceColors = facelets.sublist(
      _selectedFace * 9,
      _selectedFace * 9 + 9,
    );

    final orientation = FaceOrientation.forFace(_selectedFace);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify & Correct Colors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.view_in_ar_rounded),
            tooltip: 'View Full Cube Net',
            onPressed: () => _showFullNetModal(context, scanProv),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Scan',
            onPressed: () {
              scanProv.reset();
              context.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Face selection tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (i) {
                    final isSelected = _selectedFace == i;
                    final ori = FaceOrientation.forFace(i);
                    final centerColor = AppTheme.cubeColor(ori.centerColor);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: centerColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30),
                          ),
                        ),
                        label: Text(_faceNames[i]),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFace = i),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Instruction subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Verify stickers match your cube. The 4 borders show the adjacent centers.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
            ),

            const SizedBox(height: 12),

            // Main Face Area with 4 Adjacent Center Orientation Indicators
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // TOP adjacent center indicator
                      _AdjacentFacePill(
                        direction: 'TOP',
                        faceIndex: orientation.topFace,
                        onTap: () => setState(() => _selectedFace = orientation.topFace),
                      ),

                      const SizedBox(height: 8),

                      // Middle Row: LEFT pill, 3x3 Grid, RIGHT pill
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // LEFT adjacent center indicator
                          _AdjacentFaceSidePill(
                            direction: 'LEFT',
                            faceIndex: orientation.leftFace,
                            onTap: () => setState(() => _selectedFace = orientation.leftFace),
                          ),

                          const SizedBox(width: 10),

                          // 3x3 Grid
                          Container(
                            width: 220,
                            height: 220,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceDark,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderDark, width: 1.5),
                            ),
                            child: FaceGrid(
                              faceColors: currentFaceColors,
                              onStickerTap: _onStickerTapped,
                            ),
                          ),

                          const SizedBox(width: 10),

                          // RIGHT adjacent center indicator
                          _AdjacentFaceSidePill(
                            direction: 'RIGHT',
                            faceIndex: orientation.rightFace,
                            onTap: () => setState(() => _selectedFace = orientation.rightFace),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // BOTTOM adjacent center indicator
                      _AdjacentFacePill(
                        direction: 'BOTTOM',
                        faceIndex: orientation.bottomFace,
                        onTap: () => setState(() => _selectedFace = orientation.bottomFace),
                      ),

                      const SizedBox(height: 12),

                      // Orientation Hint
                      Text(
                        orientation.orientationHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Rotate Face Action Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => scanProv.rotateFaceCounterClockwise(_selectedFace),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.rotate_left_rounded, size: 18),
                            label: const Text('Rotate 90° ↺', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: () => scanProv.rotateFaceClockwise(_selectedFace),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            ),
                            icon: const Icon(Icons.rotate_right_rounded, size: 18),
                            label: const Text('Rotate 90° ↻', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Validation Status Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isValid
                    ? AppTheme.success.withOpacity(0.12)
                    : AppTheme.error.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isValid ? AppTheme.success : AppTheme.error,
                  width: 1.2,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isValid ? Icons.check_circle_outline : Icons.error_outline,
                    color: isValid ? AppTheme.success : AppTheme.error,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isValid
                          ? 'Cube configuration is valid! Ready to learn.'
                          : (validationError?.message ?? 'Please check sticker counts.'),
                      style: TextStyle(
                        color: isValid ? AppTheme.success : AppTheme.error,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Start Lesson CTA
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isValid
                      ? () async {
                          final teachingProv = context.read<TeachingProvider>();
                          await teachingProv.startSession(facelets);
                          if (context.mounted) {
                            context.push('/teach');
                          }
                        }
                      : null,
                  icon: const Icon(Icons.school_rounded),
                  label: const Text('Start Solving Lesson'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjacentFacePill extends StatelessWidget {
  final String direction;
  final int faceIndex;
  final VoidCallback onTap;

  const _AdjacentFacePill({
    required this.direction,
    required this.faceIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ori = FaceOrientation.forFace(faceIndex);
    final color = AppTheme.cubeColor(ori.centerColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.55), width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              direction == 'TOP' ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(width: 4),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 0.8),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '$direction: ${ori.faceName}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color == Colors.white ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdjacentFaceSidePill extends StatelessWidget {
  final String direction;
  final int faceIndex;
  final VoidCallback onTap;

  const _AdjacentFaceSidePill({
    required this.direction,
    required this.faceIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ori = FaceOrientation.forFace(faceIndex);
    final color = AppTheme.cubeColor(ori.centerColor);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 66,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.55), width: 1.2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              direction == 'LEFT' ? Icons.arrow_left_rounded : Icons.arrow_right_rounded,
              size: 20,
              color: color,
            ),
            const SizedBox(height: 2),
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30, width: 0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              direction,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              ori.faceName.split(' ')[0],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color == Colors.white ? Colors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
