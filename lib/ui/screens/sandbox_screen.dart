import 'dart:math';
import 'package:flutter/material.dart';
import '../../domain/cube/facelets.dart';
import '../../domain/cube/move_applier.dart';
import '../../domain/models/move.dart';
import '../theme/app_theme.dart';
import '../widgets/cube_renderer/cube_animator.dart';
import '../widgets/cube_renderer/cube_renderer.dart';
import '../widgets/face_grid.dart';

class SandboxScreen extends StatefulWidget {
  const SandboxScreen({super.key});

  @override
  State<SandboxScreen> createState() => _SandboxScreenState();
}

class _SandboxScreenState extends State<SandboxScreen> with SingleTickerProviderStateMixin {
  Facelets _cube = FaceletConstants.createSolved();
  int _activeFace = 0; // 0: U, 1: R, 2: F, 3: D, 4: L, 5: B
  bool _is3DView = true;
  Set<int>? _highlightedFacelets;

  late final CubeAnimatorController _animator;

  static const _faceNames = [
    'Up (White)',
    'Right (Red)',
    'Front (Green)',
    'Down (Yellow)',
    'Left (Orange)',
    'Back (Blue)'
  ];

  @override
  void initState() {
    super.initState();
    _animator = CubeAnimatorController(
      vsync: this,
      moveDuration: const Duration(milliseconds: 280),
      onMoveApplied: (move) {
        setState(() {
          _cube = MoveApplier.apply(_cube, move);
        });
      },
    );
  }

  @override
  void dispose() {
    _animator.dispose();
    super.dispose();
  }

  void _applyMove(Move move) {
    if (_is3DView) {
      _animator.animateMove(move);
    } else {
      setState(() {
        _cube = MoveApplier.apply(_cube, move);
      });
    }
  }

  void _scramble() {
    final rand = Random();
    final moves = List.generate(20, (_) => Move.values[rand.nextInt(Move.values.length)]);

    if (_is3DView) {
      _animator.animateSequence(moves, perMoveDuration: const Duration(milliseconds: 140));
    } else {
      var state = _cube;
      for (final m in moves) {
        state = MoveApplier.apply(state, m);
      }
      setState(() {
        _cube = state;
      });
    }
  }

  void _reset() {
    _animator.stop();
    setState(() {
      _cube = FaceletConstants.createSolved();
      _highlightedFacelets = null;
    });
  }

  void _toggleHighlightDemo() {
    setState(() {
      if (_highlightedFacelets == null) {
        // Highlight U-face cross edges for demo (UF=1, UR=3, UL=5, UB=7)
        _highlightedFacelets = {1, 3, 5, 7};
      } else {
        _highlightedFacelets = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final faceColors = _cube.sublist(_activeFace * 9, _activeFace * 9 + 9);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Sandbox'),
        actions: [
          IconButton(
            icon: Icon(_is3DView ? Icons.view_module_rounded : Icons.view_in_ar_rounded),
            tooltip: _is3DView ? 'Switch to 2D Face' : 'Switch to 3D Cube',
            onPressed: () => setState(() => _is3DView = !_is3DView),
          ),
          IconButton(
            icon: const Icon(Icons.highlight_rounded),
            tooltip: 'Toggle Highlight Demo',
            onPressed: _toggleHighlightDemo,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset Solved',
            onPressed: _reset,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              // Main Cube Display (3D Renderer or 2D FaceGrid)
              if (_is3DView) ...[
                Container(
                  width: double.infinity,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppTheme.borderDark, width: 1.2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        CubeRenderer(
                          facelets: _cube,
                          controller: _animator,
                          highlightedFacelets: _highlightedFacelets,
                        ),
                        Positioned(
                          top: 12,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.touch_app_rounded, size: 14, color: AppTheme.textSecondary),
                                SizedBox(width: 6),
                                Text(
                                  'Drag to rotate view • Double tap resets',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: List.generate(6, (i) {
                      final isSelected = _activeFace == i;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(_faceNames[i]),
                          selected: isSelected,
                          onSelected: (_) => setState(() => _activeFace = i),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 260,
                  height: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderDark),
                  ),
                  child: FaceGrid(faceColors: faceColors),
                ),
              ],

              const SizedBox(height: 20),

              // Move Buttons
              Text(
                'Execute Moves (tap to animate):',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _MoveBtn(label: 'U', onTap: () => _applyMove(Move.U)),
                  _MoveBtn(label: "U'", onTap: () => _applyMove(Move.Ui)),
                  _MoveBtn(label: 'U2', onTap: () => _applyMove(Move.U2)),
                  _MoveBtn(label: 'D', onTap: () => _applyMove(Move.D)),
                  _MoveBtn(label: "D'", onTap: () => _applyMove(Move.Di)),
                  _MoveBtn(label: 'D2', onTap: () => _applyMove(Move.D2)),
                  _MoveBtn(label: 'R', onTap: () => _applyMove(Move.R)),
                  _MoveBtn(label: "R'", onTap: () => _applyMove(Move.Ri)),
                  _MoveBtn(label: 'R2', onTap: () => _applyMove(Move.R2)),
                  _MoveBtn(label: 'L', onTap: () => _applyMove(Move.L)),
                  _MoveBtn(label: "L'", onTap: () => _applyMove(Move.Li)),
                  _MoveBtn(label: 'L2', onTap: () => _applyMove(Move.L2)),
                  _MoveBtn(label: 'F', onTap: () => _applyMove(Move.F)),
                  _MoveBtn(label: "F'", onTap: () => _applyMove(Move.Fi)),
                  _MoveBtn(label: 'F2', onTap: () => _applyMove(Move.F2)),
                  _MoveBtn(label: 'B', onTap: () => _applyMove(Move.B)),
                  _MoveBtn(label: "B'", onTap: () => _applyMove(Move.Bi)),
                  _MoveBtn(label: 'B2', onTap: () => _applyMove(Move.B2)),
                ],
              ),

              const SizedBox(height: 22),

              // Scramble Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _scramble,
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Scramble Cube (Animated Sequence)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoveBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MoveBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      height: 42,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: AppTheme.surfaceDark,
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }
}
