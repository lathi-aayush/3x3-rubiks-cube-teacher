import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
          content: Text('Center sticker cannot be modified.'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify & Correct Colors'),
        actions: [
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (i) {
                    final isSelected = _selectedFace == i;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_faceNames[i]),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedFace = i),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Instruction subtitle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Tap any sticker that looks wrong to fix its color.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),

            const SizedBox(height: 20),

            // 3x3 Grid
            Expanded(
              child: Center(
                child: Container(
                  width: 280,
                  height: 280,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: FaceGrid(
                    faceColors: currentFaceColors,
                    onStickerTap: _onStickerTapped,
                  ),
                ),
              ),
            ),

            // Validation Status Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(16),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Start Lesson CTA
            Padding(
              padding: const EdgeInsets.all(20),
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
