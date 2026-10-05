import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../domain/models/stage.dart';
import '../../providers/teaching_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/cube_renderer/cube_animator.dart';
import '../widgets/cube_renderer/cube_renderer.dart';
import '../widgets/face_grid.dart';

class TeachingScreen extends StatefulWidget {
  const TeachingScreen({super.key});

  @override
  State<TeachingScreen> createState() => _TeachingScreenState();
}

class _TeachingScreenState extends State<TeachingScreen> with SingleTickerProviderStateMixin {
  int _previewFace = 0; // 0..5
  bool _is3DView = true;
  late final CubeAnimatorController _animator;
  static const _faceNames = ['Up', 'Right', 'Front', 'Down', 'Left', 'Back'];

  @override
  void initState() {
    super.initState();
    _animator = CubeAnimatorController(
      vsync: this,
      moveDuration: const Duration(milliseconds: 360),
    );
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  void _playStepMoves(List<dynamic> moves) {
    if (moves.isEmpty) return;
    _animator.animateSequence(
      moves.cast(),
      perMoveDuration: const Duration(milliseconds: 380),
    );
  }

  @override
  Widget build(BuildContext context) {
    final teaching = context.watch<TeachingProvider>();

    if (teaching.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculating optimal teaching steps...'),
            ],
          ),
        ),
      );
    }

    if (teaching.isCubeSolved) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.celebration_rounded, color: AppTheme.cubeYellow, size: 72),
                const SizedBox(height: 20),
                Text(
                  'Congratulations!',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 26),
                ),
                const SizedBox(height: 10),
                Text(
                  'You have successfully solved the Rubik’s Cube!',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Home'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentStage = teaching.currentStage ?? Stage.whiteCross;
    final currentStep = teaching.currentStep;
    final faceColors = teaching.cubeState.sublist(_previewFace * 9, _previewFace * 9 + 9);

    return Scaffold(
      appBar: AppBar(
        title: Text('Stage ${currentStage.order}: ${currentStage.displayName}'),
        actions: [
          IconButton(
            icon: Icon(_is3DView ? Icons.view_module_rounded : Icons.view_in_ar_rounded),
            tooltip: _is3DView ? 'Switch to 2D Face' : 'Switch to 3D Cube',
            onPressed: () => setState(() => _is3DView = !_is3DView),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.go('/'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stage Progress Bar (1 to 7)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: currentStage.order / 7.0,
                  backgroundColor: AppTheme.borderDark,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 16),

              // Step Guidance Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Current Action',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'STEP ${teaching.currentStepIndex + 1} OF ${teaching.currentSteps.length}',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryLight,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currentStep?.description ?? 'Follow the instructions below to complete this stage.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    if (currentStep != null && currentStep.notation.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.borderDark.withOpacity(0.6)),
                            ),
                            child: Text(
                              currentStep.notation,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.cubeYellow,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (_is3DView && currentStep.moves.isNotEmpty)
                            TextButton.icon(
                              onPressed: _animator.isAnimating ? null : () => _playStepMoves(currentStep.moves),
                              icon: const Icon(Icons.play_circle_outline_rounded, size: 20),
                              label: const Text('Play in 3D'),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Virtual Cube View (3D Cube or 2D Face)
              Expanded(
                child: Center(
                  child: _is3DView
                      ? Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceDark,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.borderDark),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: CubeRenderer(
                              facelets: teaching.cubeState,
                              controller: _animator,
                            ),
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: List.generate(6, (i) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ChoiceChip(
                                      label: Text(_faceNames[i]),
                                      selected: _previewFace == i,
                                      onSelected: (_) => setState(() => _previewFace = i),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              width: 220,
                              height: 220,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppTheme.borderDark),
                              ),
                              child: FaceGrid(faceColors: faceColors),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 14),

              // Controls Bottom Row
              Row(
                children: [
                  OutlinedButton(
                    onPressed: teaching.currentStepIndex > 0 ? teaching.previousStep : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                    ),
                    child: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _animator.stop();
                        teaching.advanceStep();
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('I did this move'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
